import { HttpsError, onCall } from "firebase-functions/v2/https";
import { DocumentSnapshot, FieldValue } from "firebase-admin/firestore";
import { adminAuth, db } from "./admin";
import { applyRoleToUser, roleForEmail } from "./roles";
import { asObject, logError, logInfo, requireAdmin } from "./util";

const MAX_EMAILS = 200;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function readEmails(snap: DocumentSnapshot): string[] {
  const v: unknown = snap.get("emails");
  if (!Array.isArray(v)) return [];
  return v.filter((e): e is string => typeof e === "string").map((e) => e.trim().toLowerCase());
}

/**
 * setStaffAllowlist (admin): { emails: string[] } -> { emails: string[], updated: number }
 * Validates, lowercases and de-duplicates, writes config/staffAllowlist and
 * immediately re-evaluates the role of every Auth user whose email was added
 * or removed (demoted users also get their refresh tokens revoked).
 */
export const setStaffAllowlist = onCall(async (request) => {
  const adminUid = requireAdmin(request);
  const body = asObject(request.data);
  const raw = body["emails"];
  if (!Array.isArray(raw)) throw new HttpsError("invalid-argument", "emails must be a list.");
  if (raw.length > MAX_EMAILS) throw new HttpsError("invalid-argument", `At most ${MAX_EMAILS} emails.`);
  const emails: string[] = [];
  for (const e of raw) {
    if (typeof e !== "string") throw new HttpsError("invalid-argument", "Every email must be a string.");
    const clean = e.trim().toLowerCase();
    if (clean.length > 200 || !EMAIL_RE.test(clean)) throw new HttpsError("invalid-argument", `Invalid email: ${e}`);
    if (!emails.includes(clean)) emails.push(clean);
  }

  try {
    const ref = db.doc("config/staffAllowlist");
    const before = readEmails(await ref.get());
    await ref.set({ emails, updatedAt: FieldValue.serverTimestamp(), updatedBy: adminUid });

    const affected = [...before.filter((e) => !emails.includes(e)), ...emails.filter((e) => !before.includes(e))];
    let updated = 0;
    for (const email of affected) {
      try {
        const user = await adminAuth.getUserByEmail(email);
        // Unverified accounts never keep an elevated role.
        const role = user.emailVerified ? await roleForEmail(email) : "student";
        if (await applyRoleToUser(user.uid, role)) updated++;
      } catch (err) {
        if ((err as { code?: string }).code === "auth/user-not-found") continue;
        logError("setStaffAllowlist.apply", err, { email });
      }
    }
    logInfo("setStaffAllowlist", { adminUid, count: emails.length, updated });
    return { emails, updated };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("setStaffAllowlist", err, { adminUid });
    throw new HttpsError("internal", "Could not update the staff list.");
  }
});

/**
 * listStaff (admin): {} -> { staff: [{ email, hasAccount, uid|null, displayName|null }] }
 */
export const listStaff = onCall(async (request) => {
  requireAdmin(request);
  try {
    const emails = readEmails(await db.doc("config/staffAllowlist").get());
    const staff = await Promise.all(
      emails.map(async (email) => {
        try {
          const u = await adminAuth.getUserByEmail(email);
          return { email, hasAccount: true, uid: u.uid, displayName: u.displayName ?? null };
        } catch (err) {
          if ((err as { code?: string }).code !== "auth/user-not-found") logError("listStaff.lookup", err, { email });
          return { email, hasAccount: false, uid: null, displayName: null };
        }
      }),
    );
    return { staff };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("listStaff", err);
    throw new HttpsError("internal", "Could not load the staff list.");
  }
});
