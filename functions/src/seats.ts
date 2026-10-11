import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import { loadConfig, MS, SCHEDULE_EVERY_5_MIN } from "./config";
import { writeNotification } from "./notify";
import { OfferInfo, applyRelease, planRelease, pushOffer } from "./waitlist";
import { asObject, idField, logError, logInfo, requireAuth } from "./util";

/**
 * releaseNoShowSeats: active seat bookings with no check-in `seatGraceMinutes`
 * after startTime become 'noShow', the seat is released (to the next waitlisted
 * student, else available), and a strike is recorded:
 *   users/{uid}.strikes (server-only counter) + users/{uid}/strikes/{bookingId}.
 */
export const releaseNoShowSeats = onSchedule(SCHEDULE_EVERY_5_MIN, async () => {
  const cfg = await loadConfig();
  const cutoff = Timestamp.fromMillis(Date.now() - cfg.seatGraceMinutes * MS.minute);
  const due = await db
    .collectionGroup("bookings")
    .where("status", "==", "active")
    .where("startTime", "<=", cutoff)
    .limit(300)
    .get();

  let released = 0;
  for (const doc of due.docs) {
    if (doc.get("checkedInAt")) continue;
    const uid = doc.ref.parent.parent!.id;
    try {
      const offer = await db.runTransaction(async (tx): Promise<OfferInfo | null | false> => {
        const cur = await tx.get(doc.ref);
        const start = cur.get("startTime") as Timestamp | undefined;
        if (!cur.exists || cur.get("status") !== "active" || cur.get("checkedInAt") || !start || start.toMillis() > cutoff.toMillis()) {
          return false;
        }
        const seatId = String(cur.get("seatId"));
        const plan = await planRelease(tx, "seat", seatId);
        const holdsSeat = plan.resourceSnap.get("bookingId") === doc.id && plan.resourceSnap.get("heldBy") === uid;

        tx.update(doc.ref, { status: "noShow", noShowAt: FieldValue.serverTimestamp() });
        tx.set(db.collection("users").doc(uid), { strikes: FieldValue.increment(1) }, { merge: true });
        tx.set(db.collection("users").doc(uid).collection("strikes").doc(doc.id), {
          reason: "seatNoShow",
          seatId,
          bookingPath: doc.ref.path,
          createdAt: FieldValue.serverTimestamp(),
        });
        writeNotification(tx, uid, {
          type: "seatNoShow",
          title: "Seat released",
          body: "You did not check in on time, so your seat was released and a strike was recorded.",
          tone: "danger",
          refPath: doc.ref.path,
        });
        return holdsSeat ? applyRelease(tx, plan, cfg) : null;
      });
      if (offer !== false) {
        released++;
        await pushOffer(offer);
      }
    } catch (err) {
      logError("releaseNoShowSeats", err, { path: doc.ref.path });
    }
  }
  logInfo("releaseNoShowSeats.done", { scanned: due.size, released });
});

/** Frees the seat held by a booking (used when an account is deleted). */
export async function freeSeatForBooking(uid: string, bookingId: string, seatId: string): Promise<void> {
  const cfg = await loadConfig();
  const offer = await db.runTransaction(async (tx) => {
    const plan = await planRelease(tx, "seat", seatId);
    if (plan.resourceSnap.get("bookingId") !== bookingId || plan.resourceSnap.get("heldBy") !== uid) return null;
    return applyRelease(tx, plan, cfg);
  });
  await pushOffer(offer);
}

type EndResult = "ended" | "alreadyEnded" | "notActive" | "notFound";

/**
 * Completes one checked-in seat booking and releases its seat through the same
 * path as the no-show job (next waitlist entry gets an offer). Idempotent: a
 * booking that is already completed returns "alreadyEnded". With `onlyIfPast`
 * the booking is left alone unless its endTime has passed.
 */
async function endBooking(
  ref: FirebaseFirestore.DocumentReference,
  uid: string,
  onlyIfPast: boolean,
  endedBy: string,
): Promise<EndResult> {
  const cfg = await loadConfig();
  const out = await db.runTransaction(async (tx): Promise<{ result: EndResult; offer: OfferInfo | null }> => {
    const cur = await tx.get(ref);
    if (!cur.exists) return { result: "notFound", offer: null };
    if (cur.get("status") === "completed") return { result: "alreadyEnded", offer: null };
    if (cur.get("status") !== "active" || !cur.get("checkedInAt")) return { result: "notActive", offer: null };
    const end = cur.get("endTime");
    if (onlyIfPast && !(end instanceof Timestamp && end.toMillis() <= Date.now())) return { result: "notActive", offer: null };

    const seatId = String(cur.get("seatId"));
    const plan = await planRelease(tx, "seat", seatId);
    const holdsSeat = plan.resourceSnap.get("bookingId") === ref.id && plan.resourceSnap.get("heldBy") === uid;

    tx.update(ref, { status: "completed", endedAt: FieldValue.serverTimestamp(), endedBy });
    return { result: "ended", offer: holdsSeat ? applyRelease(tx, plan, cfg) : null };
  });
  if (out.result === "ended") await pushOffer(out.offer);
  return out.result;
}

/**
 * endExpiredSeatSessions: checked-in seat bookings whose endTime has passed
 * become 'completed' and the seat is released (waitlist offer or available).
 */
export const endExpiredSeatSessions = onSchedule(SCHEDULE_EVERY_5_MIN, async () => {
  const due = await db
    .collectionGroup("bookings")
    .where("status", "==", "active")
    .where("endTime", "<=", Timestamp.now())
    .limit(300)
    .get();

  let ended = 0;
  for (const doc of due.docs) {
    if (!doc.get("checkedInAt")) continue; // never checked in: the no-show job owns it
    try {
      if ((await endBooking(doc.ref, doc.ref.parent.parent!.id, true, "system")) === "ended") ended++;
    } catch (err) {
      logError("endExpiredSeatSessions", err, { path: doc.ref.path });
    }
  }
  logInfo("endExpiredSeatSessions.done", { scanned: due.size, ended });
});

/**
 * endSeatSession: { bookingId: string, uid?: string } ->
 *   { result: "ended" | "alreadyEnded" }
 * The owner may end their own checked-in session; staff/admin may end anyone's
 * by passing `uid`. Errors: not-found (no such booking), failed-precondition
 * (booking is not an active checked-in session), permission-denied.
 */
export const endSeatSession = onCall(async (request) => {
  const caller = requireAuth(request);
  const body = asObject(request.data);
  const bookingId = idField(body, "bookingId");
  const targetUid = body["uid"] === undefined || body["uid"] === null ? caller : idField(body, "uid");
  const role = request.auth?.token["role"];
  if (targetUid !== caller && role !== "staff" && role !== "admin") {
    throw new HttpsError("permission-denied", "You can only end your own session.");
  }
  try {
    const ref = db.collection("users").doc(targetUid).collection("bookings").doc(bookingId);
    const result = await endBooking(ref, targetUid, false, caller);
    if (result === "notFound") throw new HttpsError("not-found", "Booking not found.");
    if (result === "notActive") throw new HttpsError("failed-precondition", "This booking is not an active session.");
    return { result };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("endSeatSession", err, { caller, targetUid, bookingId });
    throw new HttpsError("internal", "Could not end the session.");
  }
});
