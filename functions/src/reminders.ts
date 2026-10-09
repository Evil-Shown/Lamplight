import { onSchedule } from "firebase-functions/v2/scheduler";
import { DocumentReference, FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import { loadConfig, MS, OPEN_STATUSES, SCHEDULE_EVERY_5_MIN } from "./config";
import {
  NotificationInput,
  Prefs,
  PushCategory,
  categoryAllowed,
  loadPrefs,
  pushToUser,
  writeNotification,
} from "./notify";
import { logError, logInfo } from "./util";

/**
 * Claims a reminder exactly once: inside a transaction, checks
 * `remindersSent.<key>` is unset, sets it, and (if the user's preferences
 * allow) writes the in-app notification. Push is sent after commit.
 * Returns the notification to push, or null if already sent / not wanted.
 */
async function claim(
  ref: DocumentReference,
  uid: string,
  key: string,
  build: () => NotificationInput,
  category: PushCategory,
  prefs: Prefs,
): Promise<NotificationInput | null> {
  return db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    if (!cur.exists || cur.get(`remindersSent.${key}`)) return null;
    tx.update(ref, { [`remindersSent.${key}`]: FieldValue.serverTimestamp() });
    if (!categoryAllowed(prefs, category)) return null;
    const n = build();
    writeNotification(tx, uid, n);
    return n;
  });
}

function ownerOf(ref: DocumentReference, data: Record<string, unknown>): string {
  return ref.path.startsWith("users/") ? ref.parent.parent!.id : String(data["userId"]);
}

function fmt(ts: Timestamp): string {
  return ts.toDate().toISOString().replace("T", " ").slice(0, 16) + " UTC";
}

export const sendReminders = onSchedule(SCHEDULE_EVERY_5_MIN, async () => {
  const cfg = await loadConfig();
  const nowMs = Date.now();
  const now = Timestamp.fromMillis(nowMs);
  const prefsCache = new Map<string, Prefs>();
  const prefsFor = async (uid: string): Promise<Prefs> => {
    let p = prefsCache.get(uid);
    if (!p) {
      p = await loadPrefs(uid);
      prefsCache.set(uid, p);
    }
    return p;
  };
  let sent = 0;

  const deliver = async (
    ref: DocumentReference,
    data: Record<string, unknown>,
    key: string,
    category: PushCategory,
    build: () => NotificationInput,
  ): Promise<void> => {
    const uid = ownerOf(ref, data);
    try {
      const prefs = await prefsFor(uid);
      const n = await claim(ref, uid, key, build, category, prefs);
      if (n) {
        sent++;
        await pushToUser(uid, n, category, prefs);
      }
    } catch (err) {
      logError("sendReminders", err, { path: ref.path, key });
    }
  };

  // 1) Seat session starting within seatReminderMinutes.
  const seatSoon = await db
    .collectionGroup("bookings")
    .where("status", "==", "active")
    .where("startTime", ">", now)
    .where("startTime", "<=", Timestamp.fromMillis(nowMs + cfg.seatReminderMinutes * MS.minute))
    .limit(300)
    .get();
  for (const d of seatSoon.docs) {
    if (d.get("checkedInAt") || d.get("remindersSent.start30")) continue;
    await deliver(d.ref, d.data(), "start30", "start", () => ({
      type: "seatReminder",
      title: "Seat session starting soon",
      body: `Your seat session starts at ${fmt(d.get("startTime") as Timestamp)}. Check in with your QR pass.`,
      tone: "info",
      refPath: d.ref.path,
    }));
  }

  // 2) Book pickup expiring within pickupReminderHours.
  const pickupSoon = await db
    .collectionGroup("reservations")
    .where("status", "in", OPEN_STATUSES)
    .where("pickupBy", ">", now)
    .where("pickupBy", "<=", Timestamp.fromMillis(nowMs + cfg.pickupReminderHours * MS.hour))
    .limit(300)
    .get();
  for (const d of pickupSoon.docs) {
    if (d.get("remindersSent.pickup2h")) continue;
    await deliver(d.ref, d.data(), "pickup2h", "expiry", () => ({
      type: "pickupReminder",
      title: "Pickup expiring soon",
      body: `${String(d.get("bookTitle") ?? "Your reserved book")} must be collected by ${fmt(d.get("pickupBy") as Timestamp)}.`,
      tone: "warning",
      refPath: d.ref.path,
    }));
  }

  // 3) Loans due within dueSoonDays (once) and within dueDayHours (once).
  const loans = await db
    .collection("loans")
    .where("status", "==", "active")
    .where("dueDate", ">", now)
    .where("dueDate", "<=", Timestamp.fromMillis(nowMs + cfg.dueSoonDays * MS.day))
    .limit(300)
    .get();
  for (const d of loans.docs) {
    const dueMs = (d.get("dueDate") as Timestamp).toMillis();
    const title = String(d.get("bookTitle") ?? "A borrowed book");
    if (dueMs - nowMs <= cfg.dueDayHours * MS.hour) {
      if (!d.get("remindersSent.dueDay")) {
        await deliver(d.ref, d.data(), "dueDay", "expiry", () => ({
          type: "dueToday",
          title: "Book due today",
          body: `${title} is due today. Return or renew it to avoid fines.`,
          tone: "warning",
          refPath: d.ref.path,
        }));
      }
    } else if (!d.get("remindersSent.due2d")) {
      await deliver(d.ref, d.data(), "due2d", "expiry", () => ({
        type: "dueSoon",
        title: "Book due soon",
        body: `${title} is due on ${fmt(d.get("dueDate") as Timestamp)}.`,
        tone: "info",
        refPath: d.ref.path,
      }));
    }
  }

  logInfo("sendReminders.done", { seat: seatSoon.size, pickup: pickupSoon.size, loans: loans.size, sent });
});
