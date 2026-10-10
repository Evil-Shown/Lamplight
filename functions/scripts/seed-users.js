#!/usr/bin/env node
/*
 * Creates (or updates) three sample logins with the Admin SDK: a student, a
 * staff member and an admin. Each gets a verified email, a users/{uid}
 * profile, the matching `role` custom claim, and the staff/admin emails are
 * merged into config/staffAllowlist and config/adminAllowlist.
 *
 *   Emulator (safe):
 *     $env:FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9099"
 *     $env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"; $env:GCLOUD_PROJECT="demo-library"
 *     node scripts/seed-users.js
 *
 *   Real project (only on purpose; needs ADC credentials):
 *     $env:GCLOUD_PROJECT="<project-id>"
 *     node scripts/seed-users.js --i-understand-this-is-a-real-project
 *
 * Passwords: SEED_STUDENT_PASSWORD / SEED_STAFF_PASSWORD / SEED_ADMIN_PASSWORD.
 * The built-in default is for development only - set real ones for any
 * non-emulator project. Re-running is safe (users are updated, lists merged).
 */
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const args = new Set(process.argv.slice(2));
const project = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
const emulator = !!(process.env.FIREBASE_AUTH_EMULATOR_HOST && process.env.FIRESTORE_EMULATOR_HOST);
const partialEmulator = !emulator && !!(process.env.FIREBASE_AUTH_EMULATOR_HOST || process.env.FIRESTORE_EMULATOR_HOST);

if (!project) {
  console.error("Refusing to run: set GCLOUD_PROJECT to the target project id.");
  process.exit(1);
}
if (partialEmulator) {
  console.error("Set BOTH FIREBASE_AUTH_EMULATOR_HOST and FIRESTORE_EMULATOR_HOST (or neither).");
  process.exit(1);
}
if (!emulator && !args.has("--i-understand-this-is-a-real-project")) {
  console.error(`The emulator hosts are not set, so this would write to the REAL project "${project}".`);
  console.error("Re-run with --i-understand-this-is-a-real-project if that is what you want.");
  process.exit(1);
}

const DEFAULT_PASSWORD = "Lamplight#2026";
const users = [
  { role: "student", email: "student@lamplight.test", name: "Sam Student", studentId: "IT26000001", env: "SEED_STUDENT_PASSWORD" },
  { role: "staff", email: "staff@lamplight.test", name: "Lee Librarian", studentId: "STAFF0001", env: "SEED_STAFF_PASSWORD" },
  { role: "admin", email: "admin@lamplight.test", name: "Ada Admin", studentId: "ADMIN0001", env: "SEED_ADMIN_PASSWORD" },
];

initializeApp({ projectId: project });
const auth = getAuth();
const db = getFirestore();

async function upsertUser(u) {
  const password = process.env[u.env] || DEFAULT_PASSWORD;
  if (!process.env[u.env]) usedDefault = true;
  let rec;
  try {
    rec = await auth.getUserByEmail(u.email);
    rec = await auth.updateUser(rec.uid, { password, displayName: u.name, emailVerified: true });
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
    rec = await auth.createUser({ email: u.email, password, displayName: u.name, emailVerified: true });
  }
  await auth.setCustomUserClaims(rec.uid, { ...(rec.customClaims || {}), role: u.role });
  await db.collection("users").doc(rec.uid).set(
    {
      name: u.name,
      studentId: u.studentId,
      email: u.email,
      reservationsVisibleToStaffOnly: false,
      role: u.role,
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return { ...u, uid: rec.uid, password };
}

let usedDefault = false;

async function main() {
  const out = [];
  for (const u of users) out.push(await upsertUser(u));

const staffEmails = out.filter((u) => u.role === "staff").map((u) => u.email);
  const adminEmails = out.filter((u) => u.role === "admin").map((u) => u.email);
  await db.doc("config/staffAllowlist").set({ emails: FieldValue.arrayUnion(...staffEmails) }, { merge: true });
  await db.doc("config/adminAllowlist").set({ emails: FieldValue.arrayUnion(...adminEmails) }, { merge: true });

  if (usedDefault) {
    console.warn(`\nWARNING: the default password "${DEFAULT_PASSWORD}" is for development only.`);
    console.warn("Set SEED_STUDENT_PASSWORD / SEED_STAFF_PASSWORD / SEED_ADMIN_PASSWORD for anything else.");
  }
  console.log(`\nSample logins in "${project}"${emulator ? " (emulator)" : ""}:\n`);
  console.table(out.map((u) => ({ role: u.role, email: u.email, name: u.name, password: u.password, uid: u.uid })));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
