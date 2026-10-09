import { onSchedule } from "firebase-functions/v2/scheduler";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import { loadConfig, MS, SCHEDULE_EVERY_5_MIN } from "./config";
import { writeNotification } from "./notify";
import { OfferInfo, applyRelease, planRelease, pushOffer } from "./waitlist";
import { logError, logInfo } from "./util";

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
