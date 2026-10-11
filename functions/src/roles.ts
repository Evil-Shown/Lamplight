import { HttpsError, onCall } from "firebase-functions/v2/https";
import { adminAuth, db } from "./admin";
import { Role, logError, logInfo, pickRole, requireAuth } from "./util";

/** Reads both allow-lists and returns the role for a (verified) email. */
export async function roleForEmail(email: string): Promise<Role> {
  const [staff, admin] = await Promise.all([db.doc("config/staffAllowlist").get(), db.doc("config/adminAllowlist").get()]);
  return pickRole(email, staff.get("emails"), admin.get("emails"));
}

/**
 * Sets the `role` claim (and the users/{uid}.role mirror) for an existing Auth
 * user. When the role goes down (admin -> staff/student, staff -> student) the
 * refresh tokens are revoked so the old claim stops working quickly.
 * Returns true when the claim changed.
 */
export async function applyRoleToUser(uid: string, role: Role): Promise<boolean> {
  const user = await adminAuth.getUser(uid);
  const previous = user.customClaims?.["role"];
  const profile = db.collection("users").doc(uid);
  if (previous === role) {
    if ((await profile.get()).exists) await profile.update({ role });
    return false;
  }
  await adminAuth.setCustomUserClaims(uid, { ...(user.customClaims ?? {}), role });
  const rank: Record<string, number> = { student: 0, staff: 1, admin: 2 };
  if ((rank[String(previous)] ?? 0) > (rank[role] ?? 0)) await adminAuth.revokeRefreshTokens(uid);
  if ((await profile.get()).exists) await profile.update({ role });
  logInfo("role.assigned", { uid, role, previous: previous ?? null });
  return true;
}

/**
 * claimRole: assigns the custom claim `role` ('admin' | 'staff' | 'student').
 *
 * - The email is read from the verified ID token, never from the request.
 * - Admin / staff is granted only when the email is in config/adminAllowlist /
 *   config/staffAllowlist (field `emails`) AND the email is verified (Google
 *   sign-in is verified). In the Auth emulator (FUNCTIONS_EMULATOR=true)
 *   verification is not required so local email/password accounts work.
 * - Precedence: admin > staff > student. Everyone else is 'student'.
 * The client must call getIdToken(true) afterwards to pick up the claim.
 */
export const claimRole = onCall(async (request) => {
  const uid = requireAuth(request);
  try {
    const email = String(request.auth?.token.email ?? "").trim().toLowerCase();
    const verified = request.auth?.token.email_verified === true;
    const emulator = process.env["FUNCTIONS_EMULATOR"] === "true";

    let role: Role = "student";
    if (email && (verified || emulator)) role = await roleForEmail(email);

    await applyRoleToUser(uid, role);
    return { role };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("claimRole", err, { uid });
    throw new HttpsError("internal", "Could not assign role.");
  }
});
