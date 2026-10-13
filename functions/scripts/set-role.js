#!/usr/bin/env node
/*
 * Adds / removes emails on the admin or staff allow-list and updates the `role`
 * custom claim of any matching Auth account (admin > staff > student; an
 * unverified email is always a student).
 *
 *   node scripts/set-role.js <admin|staff> <add|remove> <email> [more emails...]
 *
 *   Emulator (safe):
 *     $env:FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9099"
 *     $env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"; $env:GCLOUD_PROJECT="demo-library"
 *     node scripts/set-role.js admin add you@example.com
 *
 *   Real project (only on purpose; needs ADC credentials):
 *     $env:GCLOUD_PROJECT="<project-id>"
 *     node scripts/set-role.js admin add you@example.com --i-understand-this-is-a-real-project
 */
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const argv = process.argv.slice(2);
const flags = new Set(argv.filter((a) => a.startsWith("--")));
const [list, action, ...rest] = argv.filter((a) => !a.startsWith("--"));
const project = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
const emulator = !!(process.env.FIREBASE_AUTH_EMULATOR_HOST && process.env.FIRESTORE_EMULATOR_HOST);
const partialEmulator = !emulator && !!(process.env.FIREBASE_AUTH_EMULATOR_HOST || process.env.FIRESTORE_EMULATOR_HOST);

const USAGE = "Usage: node scripts/set-role.js <admin|staff> <add|remove> <email> [more emails...]";
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

if (!["admin", "staff"].includes(list) || !["add", "remove"].includes(action) || rest.length === 0) {
  console.error(USAGE);
  process.exit(1);
}
const emails = [...new Set(rest.map((e) => e.trim().toLowerCase()))];
const bad = emails.filter((e) => !EMAIL_RE.test(e));
if (bad.length) {
  console.error(`Invalid email(s): ${bad.join(", ")}\n${USAGE}`);
  process.exit(1);
}
if (!project) {
  console.error("Refusing to run: set GCLOUD_PROJECT to the target project id.");
  process.exit(1);
}
if (partialEmulator) {
  console.error("Set BOTH FIREBASE_AUTH_EMULATOR_HOST and FIRESTORE_EMULATOR_HOST (or neither).");
  process.exit(1);
}
if (!emulator && !flags.has("--i-understand-this-is-a-real-project")) {
  console.error(`The emulator hosts are not set, so this would write to the REAL project "${project}".`);
  console.error("Re-run with --i-understand-this-is-a-real-project if that is what you want.");
  process.exit(1);
}

initializeApp({ projectId: project });
const auth = getAuth();
const db = getFirestore();

const RANK = { student: 0, staff: 1, admin: 2 };
const has = (arr, email) => Array.isArray(arr) && arr.some((e) => typeof e === "string" && e.trim().toLowerCase() === email);

async function main() {
  const op = action === "add" ? FieldValue.arrayUnion(...emails) : FieldValue.arrayRemove(...emails);
  await db.doc(`config/${list}Allowlist`).set({ emails: op }, { merge: true });

  const [staffSnap, adminSnap] = await Promise.all([db.doc("config/staffAllowlist").get(), db.doc("config/adminAllowlist").get()]);
  const staffList = staffSnap.get("emails");
  const adminList = adminSnap.get("emails");

  const rows = [];
  const notes = [];
  for (const email of emails) {
    let rec;
    try {
      rec = await auth.getUserByEmail(email);
    } catch (e) {
      if (e.code !== "auth/user-not-found") throw e;
    }
    const listed = has(adminList, email) ? "admin" : has(staffList, email) ? "staff" : "student";
    if (!rec) {
      rows.push({ email, hasAccount: false, emailVerified: false, role: `(${listed} on first verified sign-in)` });
      if (listed !== "student") notes.push(`${email}: no account yet. The role applies when they sign up and verify their email.`);
      continue;
    }
    const role = rec.emailVerified ? listed : "student";
    const previous = rec.customClaims && rec.customClaims.role;
    if (previous !== role) {
      await auth.setCustomUserClaims(rec.uid, { ...(rec.customClaims || {}), role });
      if ((RANK[previous] ?? 0) > RANK[role]) await auth.revokeRefreshTokens(rec.uid);
    }
    const profile = db.collection("users").doc(rec.uid);
    if ((await profile.get()).exists) await profile.update({ role });
    rows.push({ email, hasAccount: true, emailVerified: rec.emailVerified, role });
    if (!rec.emailVerified && listed !== "student") {
      notes.push(`${email}: listed as ${listed} but the email is not verified, so the role is student until they verify and sign in again.`);
    }
  }

  console.log(`\n${list} allow-list: ${action} in "${project}"${emulator ? " (emulator)" : ""}\n`);
  console.table(rows);
  if (notes.length) {
    console.log("Notes:");
    for (const n of notes) console.log(` - ${n}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
