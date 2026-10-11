import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import { defineSecret } from "firebase-functions/params";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { DocumentReference, FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import { loadConfig, MS } from "./config";
import { asObject, logError, requireStaff } from "./util";

export const QR_SECRET = defineSecret("QR_SECRET");

export type PassKind = "r" | "b"; // r = book reservation, b = seat booking

export function newNonce(): string {
  return randomBytes(16).toString("hex");
}

/** Pass = v1.<kind>.<uid>.<docId>.<nonce>.<hmac-sha256 base64url>. */
export function signPass(kind: PassKind, uid: string, docId: string, nonce: string): string {
  const mac = createHmac("sha256", QR_SECRET.value())
    .update(`${kind}:${uid}:${docId}:${nonce}`)
    .digest("base64url");
  return `v1.${kind}.${uid}.${docId}.${nonce}.${mac}`;
}

interface ParsedPass {
  kind: PassKind;
  uid: string;
  docId: string;
  nonce: string;
  mac: string;
}

export function parsePass(code: string): ParsedPass | null {
  const parts = code.split(".");
  if (parts.length !== 6 || parts[0] !== "v1") return null;
  const [, kind, uid, docId, nonce, mac] = parts as [string, string, string, string, string, string];
  if (kind !== "r" && kind !== "b") return null;
  if (!uid || !docId || !nonce || !mac) return null;
  return { kind, uid, docId, nonce, mac };
}

function signatureValid(p: ParsedPass): boolean {
  const expected = Buffer.from(signPass(p.kind, p.uid, p.docId, p.nonce));
  const given = Buffer.from(`v1.${p.kind}.${p.uid}.${p.docId}.${p.nonce}.${p.mac}`);
  return expected.length === given.length && timingSafeEqual(expected, given);
}

/** Seat bookings get their nonce + signed pass here (reservations: reservations.ts). */
export const onBookingCreated = onDocumentCreated(
  { document: "users/{uid}/bookings/{id}", secrets: [QR_SECRET] },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const { uid, id } = event.params;
    try {
      await db.runTransaction(async (tx) => {
        const cur = await tx.get(snap.ref);
        if (!cur.exists || cur.get("qrNonce")) return;
        const nonce = newNonce();
        tx.update(snap.ref, {
          qrNonce: nonce,
          qrPass: signPass("b", uid, id, nonce),
          createdAt: FieldValue.serverTimestamp(),
        });
      });
    } catch (err) {
      logError("onBookingCreated", err, { uid, id });
      throw err;
    }
  },
);

type Result = "valid" | "alreadyUsed" | "expired" | "cancelled" | "tooEarly" | "notFound" | "malformed" | "invalid" | "ambiguous";

/**
 * verifyQrPass (staff): { code: string, consume?: boolean (default true) }
 * Accepts a signed pass (v1.*) or, as a manual-entry fallback, the short
 * `qrCode` string. A valid pass is consumed exactly once (transaction).
 */
export const verifyQrPass = onCall({ secrets: [QR_SECRET] }, async (request) => {
  const staffUid = requireStaff(request);
  const body = asObject(request.data);
  const code = typeof body["code"] === "string" ? body["code"].trim() : "";
  const consume = body["consume"] === undefined ? true : body["consume"] === true;
  if (code.length < 3 || code.length > 400) return { result: "malformed" as Result };

  try {
    let ref: DocumentReference | null = null;
    let kind: PassKind = "r";
    let nonce: string | null = null;

    if (code.startsWith("v1.")) {
      const pass = parsePass(code);
      if (!pass || !signatureValid(pass)) return { result: "malformed" as Result };
      kind = pass.kind;
      nonce = pass.nonce;
      ref = db.doc(`users/${pass.uid}/${pass.kind === "b" ? "bookings" : "reservations"}/${pass.docId}`);
    } else {
      // Manual entry: look the short code up (staff-typed, no nonce proof).
      const [b, r] = await Promise.all([
        db.collectionGroup("bookings").where("qrCode", "==", code).limit(2).get(),
        db.collectionGroup("reservations").where("qrCode", "==", code).limit(2).get(),
      ]);
      if (b.size + r.size > 1) return { result: "ambiguous" as Result };
      if (!b.empty) {
        ref = b.docs[0]!.ref;
        kind = "b";
      } else if (!r.empty) {
        ref = r.docs[0]!.ref;
      }
    }
    if (!ref) return { result: "notFound" as Result };

    const cfg = await loadConfig();
    const now = Date.now();
    const target = ref;
    const ownerUid = target.parent.parent!.id;

    const out = await db.runTransaction(async (tx) => {
      const snap = await tx.get(target);
      if (!snap.exists) return { result: "notFound" as Result };
      const d = snap.data()!;
      if (nonce !== null && d["qrNonce"] !== nonce) return { result: "malformed" as Result };

      const iso = (v: unknown): string | null => (v instanceof Timestamp ? v.toDate().toISOString() : null);
      const status = String(d["status"]);
      const base = {
        kind: kind === "b" ? "seat" : "book",
        docPath: target.path,
        status,
        seatId: (d["seatId"] as string | undefined) ?? null,
        bookId: (d["bookId"] as string | undefined) ?? null,
        bookTitle: (d["bookTitle"] as string | undefined) ?? null,
        startTime: iso(d["startTime"]),
        endTime: iso(d["endTime"]),
        pickupBy: iso(d["pickupBy"]),
      };

      let result: Result = "valid";
      if (status === "cancelled") result = "cancelled";
      else if (status === "expired" || status === "noShow") result = "expired";
      else if (status === "completed" || d["qrUsedAt"] || (kind === "b" && d["checkedInAt"])) result = "alreadyUsed";
      else if (kind === "b") {
        const startTs = d["startTime"];
        const endTs = d["endTime"];
        if (!(startTs instanceof Timestamp) || !(endTs instanceof Timestamp)) return { result: "invalid" as Result, ...base };
        const start = startTs.toMillis();
        const end = endTs.toMillis();
        if (now > end) result = "expired";
        else if (now < start - cfg.seatEarlyCheckInMinutes * MS.minute) result = "tooEarly";
      } else if (!(d["pickupBy"] instanceof Timestamp)) {
        return { result: "invalid" as Result, ...base };
      } else if (d["pickupBy"].toMillis() < now) {
        result = "expired";
      }

      if (result === "valid" && consume) {
        const patch: Record<string, unknown> = { qrUsedAt: FieldValue.serverTimestamp(), verifiedBy: staffUid };
        if (kind === "b") {
          patch["checkedInAt"] = Timestamp.fromMillis(now);
          patch["status"] = "active";
        } else {
          patch["status"] = "completed";
        }
        tx.update(target, patch);
      }
      return { result, ...base };
    });

    const user = await db.collection("users").doc(ownerUid).get();
    return {
      ...out,
      consumed: out.result === "valid" && consume,
      ownerUid,
      ownerName: (user.get("name") as string | undefined) ?? "Student",
      ownerStudentId: (user.get("studentId") as string | undefined) ?? "",
    };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("verifyQrPass", err);
    throw new HttpsError("internal", "Verification failed.");
  }
});
