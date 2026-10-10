// Auth + role gate. Roles come from the server-set custom claim `role`
// (functions/src/roles.ts claimRole). Only 'staff' and 'admin' may use the dashboard.
import { auth, A, call } from "./firebase.js";

export const STAFF_ROLES = ["staff", "admin"];
export const isStaffRole = (r) => STAFF_ROLES.includes(r);

const MESSAGES = {
  "auth/wrong-password": "Incorrect email or password.",
  "auth/invalid-credential": "Incorrect email or password.",
  "auth/invalid-login-credentials": "Incorrect email or password.",
  "auth/user-not-found": "Incorrect email or password.",
  "auth/invalid-email": "That doesn't look like a valid email address.",
  "auth/user-disabled": "This account has been disabled. Contact an administrator.",
  "auth/too-many-requests": "Too many attempts. Wait a few minutes, then try again.",
  "auth/network-request-failed": "Network problem. Check your connection and try again.",
  "auth/popup-blocked": "Your browser blocked the sign-in popup. Allow popups for this site and try again.",
  "auth/popup-closed-by-user": "Sign-in was cancelled.",
  "auth/cancelled-popup-request": "Sign-in was cancelled.",
  "auth/unauthorized-domain": "This domain isn't authorised for sign-in. Add it under Firebase Authentication > Settings > Authorized domains.",
  "auth/operation-not-allowed": "This sign-in method isn't enabled for the project.",
  "auth/account-exists-with-different-credential": "An account already exists with this email using a different sign-in method.",
};
export function friendlyAuthError(err) {
  const code = err && err.code;
  return MESSAGES[code] || (code === "auth/internal-error" ? "Something went wrong. Try again." : "Couldn't sign in. Try again.");
}

let listener = () => {};
let state = { status: "checking", user: null, role: null, notice: null };
let gen = 0;
let pendingNotice = null;
function emit(next) { state = next; listener(state); }
export const getState = () => state;

async function readRole(user, force) {
  const res = await user.getIdTokenResult(force);
  return res.claims.role || null;
}

/** Resolve the role for a signed-in user, asking the server to (re)assign if needed. */
async function resolveRole(user, { claim }) {
  let role = null;
  if (!claim) {
    try { role = await readRole(user, false); } catch { role = null; }
    if (isStaffRole(role)) return role;
  }
  // Ask the server to assign the claim from the allow-lists, then pick it up.
  await call("claimRole");
  await user.getIdToken(true);
  return readRole(user, false);
}

async function gate(user, { claim }) {
  const my = ++gen;
  emit({ status: "checking", user, role: null, notice: null });
  try {
    // Google accounts are always verified; email/password accounts must verify first.
    if (!user.emailVerified) {
      emit({ status: "unverified", user, role: null, notice: null });
      return;
    }
    const role = await resolveRole(user, { claim });
    if (my !== gen) return;
    if (!isStaffRole(role)) {
      pendingNotice = { kind: "denied", text: "This account doesn't have library staff access. Ask an administrator to add your email." };
      await A.signOut(auth);
      return;
    }
    emit({ status: "ready", user, role, notice: null });
  } catch (err) {
    if (my !== gen) return;
    const offline = err && (err.code === "functions/unavailable" || err.code === "auth/network-request-failed");
    pendingNotice = { kind: "error", text: offline ? "Network problem while checking your access. Try again."
      : "Couldn't verify your access right now. Try again in a moment." };
    await A.signOut(auth);
  }
}

export function initAuth(cb) {
  listener = cb;
  A.setPersistence(auth, A.browserLocalPersistence).catch(() => {});
  A.onAuthStateChanged(auth, (user) => {
    if (!user) {
      gen++;
      const notice = pendingNotice; pendingNotice = null;
      emit({ status: "signedOut", user: null, role: null, notice });
      return;
    }
    // Avoid re-gating when we already hold a ready session for this user.
    if (state.status === "ready" && state.user && state.user.uid === user.uid) return;
    if (state.status === "checking" && state.user && state.user.uid === user.uid) return;
    gate(user, { claim: false });
  });
  // Token refresh (hourly or forced): sign out if the staff claim is lost.
  A.onIdTokenChanged(auth, async (user) => {
    if (!user || state.status !== "ready" || state.user?.uid !== user.uid) return;
    try {
      const role = await readRole(user, false);
      if (!isStaffRole(role)) {
        pendingNotice = { kind: "denied", text: "Your staff access was removed, so you've been signed out." };
        await A.signOut(auth);
      } else if (role !== state.role) {
        emit({ ...state, role });
      }
    } catch { /* transient; next refresh re-checks */ }
  });
}

export async function signInEmail(email, password) {
  const cred = await A.signInWithEmailAndPassword(auth, email.trim(), password);
  if (state.status === "signedOut") await gate(cred.user, { claim: true });
}
export async function signInGoogle() {
  const provider = new A.GoogleAuthProvider();
  provider.setCustomParameters({ prompt: "select_account" });
  await A.signInWithPopup(auth, provider);
}
export async function resetPassword(email) { await A.sendPasswordResetEmail(auth, email.trim()); }
export async function resendVerification() { if (auth.currentUser) await A.sendEmailVerification(auth.currentUser); }
/** Re-check after the user clicked the verification link. */
export async function recheckVerification() {
  const u = auth.currentUser;
  if (!u) return;
  await u.reload();
  if (u.emailVerified) await gate(u, { claim: true });
}
export async function signOutNow() { await A.signOut(auth); }
