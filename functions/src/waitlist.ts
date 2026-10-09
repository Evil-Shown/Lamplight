import { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
  DocumentReference,
  DocumentSnapshot,
  FieldValue,
  QueryDocumentSnapshot,
  Timestamp,
  Transaction,
} from "firebase-admin/firestore";
import { db } from "./admin";
import { LibraryConfig, loadConfig, MS, SCHEDULE_EVERY_5_MIN } from "./config";
import { NotificationInput, pushToUser, writeNotification } from "./notify";
import { asObject, availabilityFor, boolField, idField, logError, logInfo, requireAuth } from "./util";

export type WaitType = "book" | "seat";

export interface OfferInfo {
  uid: string;
  entryId: string;
  notification: NotificationInput;
}

export interface ReleasePlan {
  type: WaitType;
  resourceId: string;
  resourceRef: DocumentReference;
  resourceSnap: DocumentSnapshot;
  next: QueryDocumentSnapshot | null;
}

/**
 * Release = a unit (book copy or seat) becomes free. Either the next waiting
 * student gets an offer (the unit stays held for them) or it goes back to the
 * pool. Phase 1 (plan) does every read; phase 2 (apply) only writes, so both
 * fit inside one Firestore transaction.
 */
export async function planRelease(tx: Transaction, type: WaitType, resourceId: string): Promise<ReleasePlan> {
  const resourceRef = db.collection(type === "book" ? "books" : "seats").doc(resourceId);
  const resourceSnap = await tx.get(resourceRef);
  const q = db
    .collectionGroup("waitlist")
    .where("type", "==", type)
    .where("resourceId", "==", resourceId)
    .where("status", "==", "waiting")
    .orderBy("queuedAt")
    .limit(1);
  const next = (await tx.get(q)).docs[0] ?? null;
  return { type, resourceId, resourceRef, resourceSnap, next };
}

export function applyRelease(tx: Transaction, plan: ReleasePlan, cfg: LibraryConfig): OfferInfo | null {
  const exists = plan.resourceSnap.exists;
  const next = plan.next;
  if (next) {
    const uid = next.ref.parent.parent!.id;
    const now = Date.now();
    const expires = Timestamp.fromMillis(now + cfg.waitlistOfferMinutes * MS.minute);
    tx.update(next.ref, { status: "offered", offeredAt: Timestamp.fromMillis(now), offerExpiresAt: expires });
    if (plan.type === "seat" && exists) {
      tx.update(plan.resourceRef, {
        status: "available",
        heldBy: null,
        bookingId: null,
        heldFor: uid,
        heldUntil: expires,
      });
    }
    const title = String(next.get("title") ?? (plan.type === "seat" ? "A seat" : "A book"));
    const notification: NotificationInput = {
      type: "waitlistOffer",
      title: "Waitlist spot open",
      body: `${title} is available. Claim it within ${cfg.waitlistOfferMinutes} minutes.`,
      tone: "warning",
      refPath: next.ref.path,
    };
    writeNotification(tx, uid, notification);
    return { uid, entryId: next.id, notification };
  }
  if (!exists) return null;
  if (plan.type === "seat") {
    tx.update(plan.resourceRef, {
      status: "available",
      heldBy: null,
      bookingId: null,
      heldFor: null,
      heldUntil: null,
    });
  } else {
    const copies = Number(plan.resourceSnap.get("copiesAvailable") ?? 0) + 1;
    tx.update(plan.resourceRef, {
      copiesAvailable: copies,
      availability: availabilityFor(copies, plan.resourceSnap.get("availability")),
    });
  }
  return null;
}

export async function pushOffer(offer: OfferInfo | null): Promise<void> {
  if (offer) await pushToUser(offer.uid, offer.notification, "waitlist");
}

/** Release a unit outside any other transaction. Returns the offer made, if any. */
export async function releaseResource(type: WaitType, resourceId: string): Promise<OfferInfo | null> {
  const cfg = await loadConfig();
  const offer = await db.runTransaction(async (tx) => {
    const plan = await planRelease(tx, type, resourceId);
    return applyRelease(tx, plan, cfg);
  });
  await pushOffer(offer);
  return offer;
}

/** Stamps the server queue time so students cannot jump the line. */
export const onWaitlistCreated = onDocumentCreated("users/{uid}/waitlist/{id}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  try {
    await snap.ref.update({ queuedAt: FieldValue.serverTimestamp() });
  } catch (err) {
    logError("onWaitlistCreated", err, { path: snap.ref.path });
    throw err;
  }
});

/** A student who leaves while holding an offer passes it on. */
export const onWaitlistDeleted = onDocumentDeleted("users/{uid}/waitlist/{id}", async (event) => {
  const d = event.data?.data();
  if (!d || d["status"] !== "offered") return;
  const type = d["type"] as WaitType;
  const resourceId = d["resourceId"];
  if ((type !== "book" && type !== "seat") || typeof resourceId !== "string") return;
  try {
    await releaseResource(type, resourceId);
  } catch (err) {
    logError("onWaitlistDeleted", err, { path: event.document });
    throw err;
  }
});

/** Seat freed by a client (cancel/checkout): offer it to the next in line. */
export const onSeatUpdated = onDocumentUpdated("seats/{seatId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before["status"] === "available" || after["status"] !== "available" || after["heldFor"]) return;
  try {
    const cfg = await loadConfig();
    const offer = await db.runTransaction(async (tx) => {
      const plan = await planRelease(tx, "seat", event.params.seatId);
      const s = plan.resourceSnap.data();
      if (!s || s["status"] !== "available" || s["heldFor"]) return null;
      if (!plan.next) return null;
      return applyRelease(tx, plan, cfg);
    });
    await pushOffer(offer);
  } catch (err) {
    logError("onSeatUpdated", err, { seatId: event.params.seatId });
    throw err;
  }
});

/**
 * Closes an offer (declined/expired) and passes it on, atomically. Idempotent:
 * returns closed=false if the entry is no longer in the expected state.
 */
async function closeOffer(
  entryRef: DocumentReference,
  newStatus: "declined" | "expired",
  cfg: LibraryConfig,
  requireExpired: boolean,
): Promise<{ closed: boolean; offer: OfferInfo | null }> {
  const res = await db.runTransaction(async (tx) => {
    const entry = await tx.get(entryRef);
    if (!entry.exists || entry.get("status") !== "offered") return { closed: false, offer: null };
    const exp = entry.get("offerExpiresAt") as Timestamp | undefined;
    if (requireExpired && exp && exp.toMillis() > Date.now()) return { closed: false, offer: null };
    const plan = await planRelease(tx, entry.get("type") as WaitType, String(entry.get("resourceId")));
    tx.update(entryRef, { status: newStatus, closedAt: FieldValue.serverTimestamp() });
    if (newStatus === "expired") {
      writeNotification(tx, entryRef.parent.parent!.id, {
        type: "waitlistExpired",
        title: "Waitlist offer expired",
        body: `${String(entry.get("title") ?? "Your spot")} was offered to the next person.`,
        tone: "info",
        refPath: entryRef.path,
      });
    }
    return { closed: true, offer: applyRelease(tx, plan, cfg) };
  });
  await pushOffer(res.offer);
  return res;
}

export const expireWaitlistOffers = onSchedule(SCHEDULE_EVERY_5_MIN, async () => {
  const cfg = await loadConfig();
  const due = await db
    .collectionGroup("waitlist")
    .where("status", "==", "offered")
    .where("offerExpiresAt", "<=", Timestamp.now())
    .limit(200)
    .get();
  let closed = 0;
  for (const doc of due.docs) {
    try {
      if ((await closeOffer(doc.ref, "expired", cfg, true)).closed) closed++;
    } catch (err) {
      logError("expireWaitlistOffers", err, { path: doc.ref.path });
    }
  }
  logInfo("expireWaitlistOffers.done", { scanned: due.size, closed });
});

/**
 * respondToWaitlistOffer: { entryId, accept }  (caller = the waitlisted student)
 * -> { status: 'accepted' | 'declined', kind: 'book'|'seat', docId?: string }
 * Idempotent: repeating the same answer returns the same result.
 */
export const respondToWaitlistOffer = onCall(async (request) => {
  const uid = requireAuth(request);
  const body = asObject(request.data);
  const entryId = idField(body, "entryId");
  const accept = boolField(body, "accept");
  const entryRef = db.collection("users").doc(uid).collection("waitlist").doc(entryId);
  const cfg = await loadConfig();

  try {
    if (!accept) {
      const snap = await entryRef.get();
      if (!snap.exists) throw new HttpsError("not-found", "Waitlist entry not found.");
      if (snap.get("status") === "declined") return { status: "declined", kind: snap.get("type") };
      if (snap.get("status") !== "offered") throw new HttpsError("failed-precondition", "No open offer.");
      const r = await closeOffer(entryRef, "declined", cfg, false);
      if (!r.closed) throw new HttpsError("aborted", "Offer changed, retry.");
      return { status: "declined", kind: snap.get("type") };
    }

    const docId = `wl-${entryId}`;
    const result = await db.runTransaction(async (tx) => {
      const entry = await tx.get(entryRef);
      if (!entry.exists) throw new HttpsError("not-found", "Waitlist entry not found.");
      const type = entry.get("type") as WaitType;
      if (entry.get("status") === "accepted") return { status: "accepted", kind: type, docId };
      if (entry.get("status") !== "offered") throw new HttpsError("failed-precondition", "No open offer.");
      const exp = entry.get("offerExpiresAt") as Timestamp | undefined;
      if (!exp || exp.toMillis() <= Date.now()) throw new HttpsError("failed-precondition", "Offer expired.");
      const resourceId = String(entry.get("resourceId"));
      const now = Date.now();

      if (type === "book") {
        const book = await tx.get(db.collection("books").doc(resourceId));
        const ref = db.collection("users").doc(uid).collection("reservations").doc(docId);
        tx.set(ref, {
          bookId: resourceId,
          bookTitle: (book.get("title") as string | undefined) ?? String(entry.get("title") ?? ""),
          userId: uid,
          status: "ready",
          reservedAt: Timestamp.fromMillis(now),
          pickupBy: Timestamp.fromMillis(now + cfg.pickupWindowDays * MS.day),
          pickupLocation: "Main Library",
          qrCode: `LIB-${docId}`,
          fromWaitlistOffer: true,
          copyHeld: true, // the held copy transfers to this reservation
          copyReleased: false,
        });
      } else {
        const seatRef = db.collection("seats").doc(resourceId);
        const seat = await tx.get(seatRef);
        if (!seat.exists || seat.get("heldFor") !== uid) {
          throw new HttpsError("failed-precondition", "Seat is no longer held for you.");
        }
        const start = (entry.get("startTime") as Timestamp | undefined) ?? Timestamp.fromMillis(now);
        const end = (entry.get("endTime") as Timestamp | undefined) ?? Timestamp.fromMillis(now + 3 * MS.hour);
        tx.set(db.collection("users").doc(uid).collection("bookings").doc(docId), {
          seatId: resourceId,
          userId: uid,
          date: (entry.get("date") as Timestamp | undefined) ?? start,
          startTime: start,
          endTime: end,
          qrCode: `LIB-${docId}`,
          status: "active",
          checkedInAt: null,
          fromWaitlistOffer: true,
        });
        tx.update(seatRef, { status: "occupied", heldBy: uid, bookingId: docId, heldFor: null, heldUntil: null });
      }
      tx.update(entryRef, { status: "accepted", closedAt: FieldValue.serverTimestamp(), resultDocId: docId });
      return { status: "accepted", kind: type, docId };
    });
    return result;
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("respondToWaitlistOffer", err, { uid, entryId });
    throw new HttpsError("internal", "Could not answer the offer.");
  }
});
