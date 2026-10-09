import { db } from "./admin";

/**
 * Policy defaults. Every value can be overridden by the Firestore document
 * `config/library` (same key names). Change the defaults here, or edit the
 * document in the console - no redeploy needed for the latter.
 *
 * NOTE: functions deploy to the default region (us-central1). If you change
 * region, the Flutter client must call FirebaseFunctions.instanceFor(region:).
 */
export const DEFAULTS = {
  currency: "USD",
  finePerDay: 0.25,
  fineCap: 10.0, // per loan
  loanDays: 14,
  renewDays: 7,
  maxRenewals: 2,
  seatGraceMinutes: 15, // after startTime
  seatEarlyCheckInMinutes: 30, // QR valid this long before startTime
  pickupWindowDays: 7,
  waitlistOfferMinutes: 30,
  seatReminderMinutes: 30,
  pickupReminderHours: 2,
  dueSoonDays: 2,
  dueDayHours: 12, // "due today" reminder fires when due within this many hours
};

export type LibraryConfig = typeof DEFAULTS;

export const SCHEDULE_EVERY_5_MIN = "every 5 minutes";
export const FINE_SCHEDULE = "every day 02:00";
export const FINE_TIMEZONE = "Asia/Colombo";
export const MS = { minute: 60_000, hour: 3_600_000, day: 86_400_000 };

export const OPEN_STATUSES = ["ready", "active", "expiringSoon"];

export async function loadConfig(): Promise<LibraryConfig> {
  const cfg: Record<string, unknown> = { ...DEFAULTS };
  try {
    const snap = await db.doc("config/library").get();
    const data = snap.data() ?? {};
    for (const [key, def] of Object.entries(DEFAULTS)) {
      const v = data[key];
      if (typeof v === typeof def && (typeof v !== "number" || Number.isFinite(v))) {
        cfg[key] = v;
      }
    }
  } catch {
    // fall back to defaults
  }
  return cfg as LibraryConfig;
}
