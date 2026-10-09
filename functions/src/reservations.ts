import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { DocumentReference, FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import { loadConfig, OPEN_STATUSES, SCHEDULE_EVERY_5_MIN } from "./config";
import { writeNotification } from "./notify";
import { newNonce, QR_SECRET, signPass } from "./qr";
import { OfferInfo, applyRelease, planRelease, pushOffer } from "./waitlist";
import { availabilityFor, logError, logInfo } from "./util";

/**
 * Book reservation lifecycle (server side of "reserve a copy"):
 *  - onReservationCreated: allocates a copy (transaction on books/{id}) and
 *    issues the signed QR pass. If no copy is left the reservation is
 *    cancelled with cancelReason 'noCopies'.
 *  - onReservationUpdated: when an open reservation becomes cancelled/expired
 *    the held copy is released (to the next waitlisted student, else the pool).
 *  - expireReservations: marks overdue pickups 'expired' (which triggers the above).
 */
export const onReservationCreated = onDocumentCreated(
  { document: "users/{uid}/reservations/{id}", secrets: [QR_SECRET] },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const { uid, id } = event.params;
    try {
      await db.runTransaction(async (tx) => {
        const cur = await tx.get(snap.ref);
        if (!cur.exists || cur.get("qrNonce")) return; // already processed
        const held = cur.get("copyHeld") === true;
        const bookRef = db.collection("books").doc(String(cur.get("bookId")));
        const book = held ? null : await tx.get(bookRef);

        if (book) {
          const copies = Number(book.get("copiesAvailable") ?? 0);
          if (!book.exists || copies <= 0) {
            tx.update(snap.ref, {
              status: "cancelled",
              cancelReason: "noCopies",
              copyHeld: false,
              copyReleased: true,
              qrNonce: "void",
            });
            writeNotification(tx, uid, {
              type: "reservationCancelled",
              title: "Reservation cancelled",
              body: "No copies were left. Join the waitlist to be notified.",
              tone: "danger",
              refPath: snap.ref.path,
            });
            return;
          }
          tx.update(bookRef, {
            copiesAvailable: copies - 1,
            availability: availabilityFor(copies - 1, book.get("availability")),
          });
        }

        const nonce = newNonce();
        tx.update(snap.ref, {
          qrNonce: nonce,
          qrPass: signPass("r", uid, id, nonce),
          copyHeld: true,
          copyReleased: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      });
    } catch (err) {
      logError("onReservationCreated", err, { uid, id });
      throw err;
    }
  },
);

/** Idempotent copy release. Returns the waitlist offer it triggered, if any. */
export async function releaseReservationCopy(ref: DocumentReference): Promise<OfferInfo | null> {
  const cfg = await loadConfig();
  const offer = await db.runTransaction(async (tx) => {
    const r = await tx.get(ref);
    if (!r.exists) return null;
    const status = String(r.get("status"));
    if (status !== "cancelled" && status !== "expired") return null;
    if (r.get("copyHeld") !== true || r.get("copyReleased") === true) return null;
    const plan = await planRelease(tx, "book", String(r.get("bookId")));
    tx.update(ref, { copyReleased: true });
    return applyRelease(tx, plan, cfg);
  });
  await pushOffer(offer);
  return offer;
}

export const onReservationUpdated = onDocumentUpdated("users/{uid}/reservations/{id}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || !event.data) return;
  const closing = after["status"] === "cancelled" || after["status"] === "expired";
  if (!closing || !OPEN_STATUSES.includes(String(before["status"]))) return;
  try {
    await releaseReservationCopy(event.data.after.ref);
  } catch (err) {
    logError("onReservationUpdated", err, { path: event.data.after.ref.path });
    throw err;
  }
});

export const expireReservations = onSchedule(SCHEDULE_EVERY_5_MIN, async () => {
  const due = await db
    .collectionGroup("reservations")
    .where("status", "in", OPEN_STATUSES)
    .where("pickupBy", "<=", Timestamp.now())
    .limit(300)
    .get();
  let expired = 0;
  for (const doc of due.docs) {
    try {
      const done = await db.runTransaction(async (tx) => {
        const cur = await tx.get(doc.ref);
        const pickupBy = cur.get("pickupBy") as Timestamp | undefined;
        if (!cur.exists || !OPEN_STATUSES.includes(String(cur.get("status"))) || !pickupBy || pickupBy.toMillis() > Date.now()) {
          return false;
        }
        tx.update(doc.ref, { status: "expired", expiredAt: FieldValue.serverTimestamp() });
        writeNotification(tx, doc.ref.parent.parent!.id, {
          type: "reservationExpired",
          title: "Reservation expired",
          body: `${String(cur.get("bookTitle") ?? "Your book")} was not collected in time.`,
          tone: "danger",
          refPath: doc.ref.path,
        });
        return true;
      });
      if (done) expired++;
    } catch (err) {
      logError("expireReservations", err, { path: doc.ref.path });
    }
  }
  logInfo("expireReservations.done", { scanned: due.size, expired });
});
