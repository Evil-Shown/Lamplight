import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import { FINE_SCHEDULE, FINE_TIMEZONE, loadConfig, MS } from "./config";
import { pushToUser, writeNotification } from "./notify";
import { applyRelease, planRelease, pushOffer } from "./waitlist";
import { asObject, availabilityFor, idField, logError, logInfo, requireAuth, requireStaff } from "./util";

const round2 = (n: number): number => Math.round(n * 100) / 100;

/**
 * loans/{loanId}: userId, bookId, bookTitle, checkedOutAt, dueDate, returnedAt,
 * status ('active'|'overdue'|'returned'), renewals, renewalRequested,
 * fineAccrued, fineCurrency, lastFineAt, reservationId, remindersSent{}.
 */

/** renewLoan { loanId } (owner or staff) -> { loanId, dueDate, renewals } */
export const renewLoan = onCall(async (request) => {
  const uid = requireAuth(request);
  const loanId = idField(asObject(request.data), "loanId");
  const isStaff = request.auth?.token["role"] === "staff";
  const cfg = await loadConfig();
  try {
    return await db.runTransaction(async (tx) => {
      const ref = db.collection("loans").doc(loanId);
      const loan = await tx.get(ref);
      if (!loan.exists) throw new HttpsError("not-found", "Loan not found.");
      if (loan.get("userId") !== uid && !isStaff) throw new HttpsError("permission-denied", "Not your loan.");
      const due = loan.get("dueDate") as Timestamp;
      if (loan.get("status") !== "active" || due.toMillis() < Date.now()) {
        throw new HttpsError("failed-precondition", "Only on-time active loans can be renewed.");
      }
      const renewals = Number(loan.get("renewals") ?? 0);
      if (renewals >= cfg.maxRenewals) throw new HttpsError("failed-precondition", "Renewal limit reached.");
      const waiting = await tx.get(
        db
          .collectionGroup("waitlist")
          .where("type", "==", "book")
          .where("resourceId", "==", String(loan.get("bookId")))
          .where("status", "in", ["waiting", "offered"])
          .orderBy("queuedAt")
          .limit(1),
      );
      if (!waiting.empty) throw new HttpsError("failed-precondition", "Another student is waiting for this book.");

      const newDue = Timestamp.fromMillis(due.toMillis() + cfg.renewDays * MS.day);
      tx.update(ref, {
        dueDate: newDue,
        renewals: renewals + 1,
        renewalRequested: false,
        remindersSent: {},
        lastRenewedAt: FieldValue.serverTimestamp(),
      });
      writeNotification(tx, String(loan.get("userId")), {
        type: "loanRenewed",
        title: "Loan renewed",
        body: `${String(loan.get("bookTitle") ?? "Your book")} is now due ${newDue.toDate().toISOString().slice(0, 10)}.`,
        tone: "success",
        refPath: ref.path,
      });
      return { loanId, dueDate: newDue.toDate().toISOString(), renewals: renewals + 1 };
    });
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("renewLoan", err, { uid, loanId });
    throw new HttpsError("internal", "Could not renew.");
  }
});

/**
 * checkoutBook (staff) { userId, bookId, reservationId?, loanDays? }
 * -> { loanId, dueDate }. With reservationId the copy already held by the
 * reservation is used; without it a copy is taken from the shelf count.
 */
export const checkoutBook = onCall(async (request) => {
  const staffUid = requireStaff(request);
  const body = asObject(request.data);
  const userId = idField(body, "userId");
  const bookId = idField(body, "bookId");
  const reservationId = body["reservationId"] === undefined ? null : idField(body, "reservationId");
  const cfg = await loadConfig();
  let days = cfg.loanDays;
  if (body["loanDays"] !== undefined) {
    const d = body["loanDays"];
    if (typeof d !== "number" || !Number.isInteger(d) || d < 1 || d > 60) {
      throw new HttpsError("invalid-argument", "loanDays must be an integer 1-60.");
    }
    days = d;
  }
  try {
    return await db.runTransaction(async (tx) => {
      const bookRef = db.collection("books").doc(bookId);
      const resRef = reservationId ? db.collection("users").doc(userId).collection("reservations").doc(reservationId) : null;
      const [book, res, user] = await Promise.all([
        tx.get(bookRef),
        resRef ? tx.get(resRef) : Promise.resolve(null),
        tx.get(db.collection("users").doc(userId)),
      ]);
      if (!book.exists) throw new HttpsError("not-found", "Book not found.");
      if (!user.exists) throw new HttpsError("not-found", "Student not found.");

      if (res) {
        if (!res.exists || res.get("bookId") !== bookId) throw new HttpsError("not-found", "Reservation not found.");
        if (res.get("loanId")) throw new HttpsError("failed-precondition", "Reservation already checked out.");
        if (["cancelled", "expired", "noShow"].includes(String(res.get("status")))) {
          throw new HttpsError("failed-precondition", "Reservation is not valid.");
        }
      } else {
        const copies = Number(book.get("copiesAvailable") ?? 0);
        if (copies <= 0) throw new HttpsError("failed-precondition", "No copies available.");
        tx.update(bookRef, { copiesAvailable: copies - 1, availability: availabilityFor(copies - 1, book.get("availability")) });
      }

      const loanRef = db.collection("loans").doc();
      const now = Date.now();
      const due = Timestamp.fromMillis(now + days * MS.day);
      tx.set(loanRef, {
        userId,
        bookId,
        bookTitle: book.get("title") ?? "",
        checkedOutAt: Timestamp.fromMillis(now),
        dueDate: due,
        returnedAt: null,
        status: "active",
        renewals: 0,
        renewalRequested: false,
        fineAccrued: 0,
        fineCurrency: cfg.currency,
        lastFineAt: null,
        reservationId,
        remindersSent: {},
        createdBy: staffUid,
      });
      if (resRef && res) tx.update(resRef, { loanId: loanRef.id, status: "completed" });
      return { loanId: loanRef.id, dueDate: due.toDate().toISOString() };
    });
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("checkoutBook", err, { userId, bookId });
    throw new HttpsError("internal", "Checkout failed.");
  }
});

/** checkinBook (staff) { loanId } -> { loanId, fineAccrued, fineCurrency } */
export const checkinBook = onCall(async (request) => {
  requireStaff(request);
  const loanId = idField(asObject(request.data), "loanId");
  const cfg = await loadConfig();
  try {
    const out = await db.runTransaction(async (tx) => {
      const ref = db.collection("loans").doc(loanId);
      const loan = await tx.get(ref);
      if (!loan.exists) throw new HttpsError("not-found", "Loan not found.");
      const fine = Number(loan.get("fineAccrued") ?? 0);
      const currency = String(loan.get("fineCurrency") ?? cfg.currency);
      if (loan.get("status") === "returned") return { loanId, fineAccrued: fine, fineCurrency: currency, offer: null };
      const plan = await planRelease(tx, "book", String(loan.get("bookId")));
      tx.update(ref, { status: "returned", returnedAt: FieldValue.serverTimestamp() });
      const offer = applyRelease(tx, plan, cfg);
      return { loanId, fineAccrued: fine, fineCurrency: currency, offer };
    });
    await pushOffer(out.offer);
    return { loanId: out.loanId, fineAccrued: out.fineAccrued, fineCurrency: out.fineCurrency };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("checkinBook", err, { loanId });
    throw new HttpsError("internal", "Check-in failed.");
  }
});

/** accrueFines: daily; fine = min(cap, fullDaysOverdue * finePerDay) per loan. */
export const accrueFines = onSchedule({ schedule: FINE_SCHEDULE, timeZone: FINE_TIMEZONE }, async () => {
  const cfg = await loadConfig();
  const overdue = await db
    .collection("loans")
    .where("status", "in", ["active", "overdue"])
    .where("dueDate", "<", Timestamp.now())
    .limit(500)
    .get();
  let updated = 0;
  for (const doc of overdue.docs) {
    try {
      const notify = await db.runTransaction(async (tx) => {
        const loan = await tx.get(doc.ref);
        if (!loan.exists || loan.get("status") === "returned") return null;
        const due = (loan.get("dueDate") as Timestamp).toMillis();
        const days = Math.floor((Date.now() - due) / MS.day);
        if (days < 1) return null;
        const target = round2(Math.min(cfg.fineCap, days * cfg.finePerDay));
        const current = Number(loan.get("fineAccrued") ?? 0);
        const delta = round2(target - current);
        const userId = String(loan.get("userId"));
        if (delta <= 0) {
          if (loan.get("status") !== "overdue") tx.update(doc.ref, { status: "overdue" });
          return null;
        }
        tx.update(doc.ref, {
          status: "overdue",
          fineAccrued: target,
          fineCurrency: cfg.currency,
          lastFineAt: FieldValue.serverTimestamp(),
        });
        tx.set(db.collection("users").doc(userId), { finesTotal: FieldValue.increment(delta) }, { merge: true });
        const n = {
          type: "fineAccrued" as const,
          title: "Overdue fine",
          body: `${String(loan.get("bookTitle") ?? "A book")} is ${days} day(s) overdue. Fine so far: ${target.toFixed(2)} ${cfg.currency}.`,
          tone: "danger" as const,
          refPath: doc.ref.path,
        };
        writeNotification(tx, userId, n);
        return { userId, n };
      });
      if (notify) {
        updated++;
        await pushToUser(notify.userId, notify.n, "always");
      }
    } catch (err) {
      logError("accrueFines", err, { path: doc.ref.path });
    }
  }
  logInfo("accrueFines.done", { scanned: overdue.size, updated });
});
