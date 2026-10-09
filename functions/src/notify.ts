import { DocumentData, DocumentReference, Timestamp } from "firebase-admin/firestore";
import { db, messaging } from "./admin";
import { logError } from "./util";

export type NotificationType =
  | "seatReminder"
  | "pickupReminder"
  | "dueSoon"
  | "dueToday"
  | "waitlistOffer"
  | "waitlistExpired"
  | "reservationExpired"
  | "reservationCancelled"
  | "seatNoShow"
  | "fineAccrued"
  | "loanRenewed"
  | "info";

export type Tone = "info" | "success" | "warning" | "danger";
export type PushCategory = "start" | "expiry" | "waitlist" | "always";

export interface NotificationInput {
  type: NotificationType;
  title: string;
  body: string;
  tone: Tone;
  refPath?: string;
}

export interface Prefs {
  pushEnabled: boolean;
  emailEnabled: boolean;
  smsEnabled: boolean;
  reminderBeforeStart: boolean;
  reminderBeforeExpiry: boolean;
  waitlistUpdates: boolean;
}

const ICONS: Record<Tone, number> = {
  info: 0xe911,
  success: 0xe86c,
  warning: 0xe911,
  danger: 0xe5e0,
};

interface SetWriter {
  set(ref: DocumentReference, data: DocumentData): unknown;
}

/** Queues an in-app notification doc on a transaction or batch. */
export function writeNotification(w: SetWriter, uid: string, n: NotificationInput): void {
  const ref = db.collection("users").doc(uid).collection("notifications").doc();
  w.set(ref, {
    type: n.type,
    title: n.title,
    body: n.body,
    tone: n.tone,
    iconCodePoint: ICONS[n.tone],
    refPath: n.refPath ?? null,
    read: false,
    timestamp: Timestamp.now(),
  });
}

export async function loadPrefs(uid: string): Promise<Prefs> {
  const snap = await db.collection("users").doc(uid).get();
  const p = (snap.data()?.["notificationPrefs"] ?? {}) as Partial<Prefs>;
  const b = (v: unknown): boolean => (typeof v === "boolean" ? v : true);
  return {
    pushEnabled: b(p.pushEnabled),
    emailEnabled: b(p.emailEnabled),
    smsEnabled: b(p.smsEnabled),
    reminderBeforeStart: b(p.reminderBeforeStart),
    reminderBeforeExpiry: b(p.reminderBeforeExpiry),
    waitlistUpdates: b(p.waitlistUpdates),
  };
}

export function categoryAllowed(prefs: Prefs, c: PushCategory): boolean {
  if (c === "start") return prefs.reminderBeforeStart;
  if (c === "expiry") return prefs.reminderBeforeExpiry;
  if (c === "waitlist") return prefs.waitlistUpdates;
  return true;
}

/** Best-effort FCM push to every device token of a user. Never throws. */
export async function pushToUser(
  uid: string,
  n: NotificationInput,
  category: PushCategory,
  prefs?: Prefs,
): Promise<void> {
  try {
    const p = prefs ?? (await loadPrefs(uid));
    if (!p.pushEnabled || !categoryAllowed(p, category)) return;
    const devices = await db.collection("users").doc(uid).collection("devices").get();
    const tokens = devices.docs
      .map((d) => d.get("token") as unknown)
      .filter((t): t is string => typeof t === "string" && t.length > 0);
    if (tokens.length === 0) return;
    const res = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: n.title, body: n.body },
      data: { type: n.type, refPath: n.refPath ?? "" },
    });
    const dead: Promise<unknown>[] = [];
    res.responses.forEach((r, i) => {
      const code = r.error?.code ?? "";
      if (!r.success && (code.includes("registration-token-not-registered") || code.includes("invalid-registration-token"))) {
        dead.push(devices.docs[i]!.ref.delete());
      }
    });
    await Promise.all(dead);
  } catch (err) {
    logError("pushToUser", err, { uid, type: n.type });
  }
}
