import { HttpsError, onCall } from "firebase-functions/v2/https";
import { adminAuth, db } from "./admin";
import { logError, logInfo, requireAuth } from "./util";

/**
 * claimRole: assigns the custom claim `role` ('staff' | 'student').
 *
 * - The email is read from the verified ID token, never from the request.
 * - Staff is granted only when the email is in config/staffAllowlist.emails
 *   AND the email is verified (Google sign-in is verified). In the Auth
 *   emulator (FUNCTIONS_EMULATOR=true) verification is not required so local
 *   testing with email/password accounts works.
 * - Unverified or non-allowlisted users become 'student'.
 * The client must call getIdToken(true) afterwards to pick up the claim.
 */
export const claimRole = onCall(async (request) => {
  const uid = requireAuth(request);
  try {
    const email = String(request.auth?.token.email ?? "").trim().toLowerCase();
    const verified = request.auth?.token.email_verified === true;
    const emulator = process.env["FUNCTIONS_EMULATOR"] === "true";

    let role: "staff" | "student" = "student";
    if (email && (verified || emulator)) {
      const snap = await db.doc("config/staffAllowlist").get();
      const emails: unknown = snap.get("emails");
      if (Array.isArray(emails) && emails.some((e) => typeof e === "string" && e.trim().toLowerCase() === email)) {
        role = "staff";
      }
    }

    const user = await adminAuth.getUser(uid);
    if (user.customClaims?.["role"] !== role) {
      await adminAuth.setCustomUserClaims(uid, { ...(user.customClaims ?? {}), role });
      logInfo("claimRole.assigned", { uid, role });
    }

    // Keep the profile mirror in sync, but never create the profile here.
    const profile = db.collection("users").doc(uid);
    if ((await profile.get()).exists) await profile.update({ role });

    return { role };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("claimRole", err, { uid });
    throw new HttpsError("internal", "Could not assign role.");
  }
});
