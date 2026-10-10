#!/usr/bin/env node
/*
 * Seeds the catalogue, the 16-seat map and config/library using the Admin SDK.
 *
 *   Emulator (safe):
 *     $env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"; $env:GCLOUD_PROJECT="demo-library"
 *     node scripts/seed.js --yes
 *
 *   Real project (only on purpose; needs ADC credentials):
 *     $env:GCLOUD_PROJECT="<project-id>"
 *     node scripts/seed.js --yes --i-mean-production
 *
 * The project id is taken from GCLOUD_PROJECT / GOOGLE_CLOUD_PROJECT; there is
 * no default. Existing docs are overwritten with merge, so re-running is safe.
 * Set SEED_STAFF_EMAILS="a@sliit.lk,b@sliit.lk" to create config/staffAllowlist
 * (only if it does not exist yet).
 */
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

const args = new Set(process.argv.slice(2));
const project = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
const emulator = !!process.env.FIRESTORE_EMULATOR_HOST;

if (!args.has("--yes")) {
  console.error("Refusing to run: pass --yes to confirm.");
  process.exit(1);
}
if (!project) {
  console.error("Refusing to run: set GCLOUD_PROJECT to the target project id.");
  process.exit(1);
}
if (!emulator && !args.has("--i-mean-production")) {
  console.error(`FIRESTORE_EMULATOR_HOST is not set, so this would write to the REAL project "${project}".`);
  console.error("Re-run with --i-mean-production if that is what you want.");
  process.exit(1);
}

initializeApp({ projectId: project });
const db = getFirestore();

const books = [
  ["b1", "Clean Code", "Robert C. Martin", "Software Engineering", "9780132350884", "B2-14", 3, 0xff7a2e2b, "https://m.media-amazon.com/images/I/41xShlnTZTL._SX376_BO1,204,203,200_.jpg", "A practical guide to writing clean, readable and maintainable software."],
  ["b2", "The Pragmatic Programmer", "David Thomas, Andrew Hunt", "Software Engineering", "978-0135957059", "B1-08", 1, 0xff0e7490, "https://m.media-amazon.com/images/I/51A8l+FtCEL._SX379_BO1,204,203,200_.jpg", "An easy read on pragmatic software development."],
  ["b3", "Code Complete", "Steve McConnell", "Software Engineering", "978-0078022159", "B2-09", 0, 0xffb45309, "https://covers.openlibrary.org/b/isbn/9780078022159-L.jpg?default=false", "A thorough guide to constructing maintainable software."],
  ["b4", "Atomic Habits", "James Clear", "Self Development", "9780735211292", "C3-21", 5, 0xff9d174d, "https://covers.openlibrary.org/b/isbn/9780735211292-L.jpg?default=false", "Tiny changes, remarkable results."],
  ["b5", "Human-Computer Interaction", "Alan Dix, Janet Beale", "Human-Computer Interaction", "9780321500883", "B3-02", 0, 0xff5b21b6, "https://covers.openlibrary.org/b/isbn/9780321500883-L.jpg?default=false", "An introduction to the design and evaluation of interactive systems."],
  ["b6", "Introduction to Algorithms", "Thomas H. Cormen", "Computer Science", "978-0262046305", "A1-03", 2, 0xff155e75, "https://covers.openlibrary.org/b/isbn/9780262046305-L.jpg?default=false", "A comprehensive introduction to the modern study of computer algorithms."],
  ["b7", "The Design of Everyday Things", "Don Norman", "Design", "978-0465050659", "C1-11", 4, 0xff9a3412, "https://covers.openlibrary.org/b/isbn/9780465050659-L.jpg?default=false", "Design is an integral part of everyday human existence."],
].map(([id, title, author, subject, isbn, shelfLocation, copies, coverColor, coverUrl, description]) => ({
  id,
  data: {
    title,
    author,
    subject,
    isbn,
    shelfLocation,
    copiesAvailable: copies,
    copiesTotal: copies + (id === "b3" ? 2 : id === "b5" ? 2 : 0),
    availability: copies > 0 ? "available" : id === "b3" ? "waitlisted" : "onLoan",
    coverColor,
    coverUrl,
    description,
    titleLower: title.toLowerCase(),
    authorLower: author.toLowerCase(),
    createdAt: Timestamp.now(),
    dueDate: null,
  },
}));

const seats = [];
for (let row = 0; row < 4; row++) {
  for (let col = 0; col < 4; col++) {
    const label = `${row + 1}${String.fromCharCode(65 + col)}`;
    const featured = label === "2C";
    seats.push({
      id: `s${row}_${col}`,
      data: {
        label,
        floor: 2,
        section: "Quiet Wing",
        status: "available",
        category: featured || col < 2 ? "quietZone" : col === 2 ? "individualPod" : "collaborative",
        hasPowerOutlet: featured || col !== 1,
        hasMonitor: col === 3,
        nearWindow: featured || col === 3,
        standingDesk: col === 0,
        row,
        col,
        heldBy: null,
        bookingId: null,
        heldFor: null,
        heldUntil: null,
      },
    });
  }
}

const libraryConfig = {
  currency: "USD",
  finePerDay: 0.25,
  fineCap: 10,
  loanDays: 14,
  renewDays: 7,
  maxRenewals: 2,
  seatGraceMinutes: 15,
  seatEarlyCheckInMinutes: 30,
  pickupWindowDays: 7,
  waitlistOfferMinutes: 30,
  seatReminderMinutes: 30,
  pickupReminderHours: 2,
  dueSoonDays: 2,
  dueDayHours: 12,
};

// Adds titleLower / authorLower / createdAt to any book missing them.
async function backfillBooks() {
  const snap = await db.collection("books").get();
  let n = 0;
  for (const d of snap.docs) {
    const x = d.data();
    const patch = {};
    if (typeof x.title === "string" && x.titleLower !== x.title.toLowerCase()) patch.titleLower = x.title.toLowerCase();
    if (typeof x.author === "string" && x.authorLower !== x.author.toLowerCase()) patch.authorLower = x.author.toLowerCase();
    if (!x.createdAt) patch.createdAt = Timestamp.now();
    if (Object.keys(patch).length) {
      await d.ref.set(patch, { merge: true });
      n++;
    }
  }
  console.log(`Backfilled search fields on ${n} existing book(s).`);
}

async function main() {
  const batch = db.batch();
  for (const b of books) batch.set(db.collection("books").doc(b.id), b.data, { merge: true });
  await backfillBooks();
  for (const s of seats) batch.set(db.collection("seats").doc(s.id), s.data, { merge: true });
  batch.set(db.doc("config/library"), libraryConfig, { merge: true });
  await batch.commit();

  const emails = (process.env.SEED_STAFF_EMAILS || "")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
  if (emails.length > 0) {
    const ref = db.doc("config/staffAllowlist");
    if ((await ref.get()).exists) console.log("config/staffAllowlist already exists; left untouched.");
    else await ref.set({ emails, createdAt: Timestamp.now() });
  }
  console.log(`Seeded ${books.length} books, ${seats.length} seats and config/library into "${project}"${emulator ? " (emulator)" : ""}.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
