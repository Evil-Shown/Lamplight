const { before, after, beforeEach, describe, it } = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, Timestamp } = require("firebase/firestore");

let env;
const hour = 3600 * 1000;
const inFuture = (ms) => Timestamp.fromMillis(Date.now() + ms);

const student = (uid = "alice") => env.authenticatedContext(uid, { role: "student", email: `${uid}@sliit.lk` }).firestore();
const staff = () => env.authenticatedContext("staff1", { role: "staff", email: "staff1@sliit.lk" }).firestore();
const admin = () => env.authenticatedContext("admin1", { role: "admin", email: "admin1@sliit.lk" }).firestore();
const noClaim = (uid = "carol") => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

const reservation = (over = {}) => ({
  bookId: "b1",
  bookTitle: "Clean Code",
  userId: "alice",
  reservedAt: Timestamp.now(),
  pickupBy: inFuture(7 * 24 * hour),
  pickupLocation: "Main Library",
  qrCode: "LIB-R1",
  status: "ready",
  ...over,
});

const booking = (over = {}) => ({
  seatId: "s1_1",
  userId: "alice",
  date: Timestamp.now(),
  startTime: inFuture(hour),
  endTime: inFuture(3 * hour),
  qrCode: "LIB-B1",
  status: "active",
  checkedInAt: null,
  ...over,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-library",
    firestore: { rules: fs.readFileSync(path.join(__dirname, "..", "firestore.rules"), "utf8") },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "users/alice"), { name: "Alice", studentId: "IT1", email: "alice@sliit.lk" });
    await setDoc(doc(db, "users/bob"), { name: "Bob", studentId: "IT2", email: "bob@sliit.lk" });
    await setDoc(doc(db, "users/alice/reservations/r1"), reservation());
    await setDoc(doc(db, "users/alice/bookings/bk1"), booking());
    await setDoc(doc(db, "users/alice/waitlist/w1"), {
      type: "book", title: "Code Complete", resourceId: "b3", userId: "alice", status: "offered", joinedAt: Timestamp.now(),
    });
    await setDoc(doc(db, "books/b1"), { title: "Clean Code", copiesAvailable: 3 });
    await setDoc(doc(db, "seats/s1_1"), { label: "2B", status: "available", heldBy: null, bookingId: null });
    await setDoc(doc(db, "seats/held"), { label: "9Z", status: "available", heldBy: null, heldFor: "bob" });
    await setDoc(doc(db, "config/staffAllowlist"), { emails: ["staff1@sliit.lk"] });
    await setDoc(doc(db, "config/library"), { currency: "USD" });
    await setDoc(doc(db, "loans/l1"), { userId: "alice", bookId: "b1", status: "active", renewals: 0, renewalRequested: false });
    await setDoc(doc(db, "queue/q1"), { studentName: "A", status: "pending" });
  });
});

describe("users and roles", () => {
  it("student cannot read another student's profile or reservations", async () => {
    await assertFails(getDoc(doc(student("bob"), "users/alice")));
    await assertFails(getDoc(doc(student("bob"), "users/alice/reservations/r1")));
  });

  it("owner and staff can read reservations", async () => {
    await assertSucceeds(getDoc(doc(student("alice"), "users/alice/reservations/r1")));
    await assertSucceeds(getDoc(doc(staff(), "users/alice/reservations/r1")));
  });

  it("student cannot write role (create or update)", async () => {
    await assertFails(updateDoc(doc(student("alice"), "users/alice"), { role: "staff" }));
    await assertFails(setDoc(doc(student("dave"), "users/dave"), { name: "D", role: "staff" }));
    await assertFails(updateDoc(doc(student("alice"), "users/alice"), { strikes: 0 }));
    await assertFails(updateDoc(doc(student("alice"), "users/alice"), { finesTotal: 0 }));
  });

  it("owner can create and update ordinary profile fields", async () => {
    await assertSucceeds(setDoc(doc(student("dave"), "users/dave"), { name: "Dave", studentId: "IT9", email: "dave@sliit.lk" }));
    await assertSucceeds(updateDoc(doc(student("alice"), "users/alice"), { notificationPrefs: { pushEnabled: false } }));
  });
});

describe("books and seats", () => {
  it("student cannot write books; staff can; anyone signed in can read", async () => {
    await assertFails(setDoc(doc(student(), "books/b9"), { title: "X" }));
    await assertFails(updateDoc(doc(student(), "books/b1"), { copiesAvailable: 0 }));
    await assertSucceeds(setDoc(doc(staff(), "books/b9"), { title: "X" }));
    await assertSucceeds(getDoc(doc(student(), "books/b1")));
    await assertFails(getDoc(doc(anon(), "books/b1")));
  });

  it("staff can update seat status; nobody creates or deletes seats", async () => {
    await assertSucceeds(updateDoc(doc(staff(), "seats/s1_1"), { status: "limited" }));
    await assertFails(setDoc(doc(staff(), "seats/new"), { status: "available" }));
    await assertFails(deleteDoc(doc(staff(), "seats/s1_1")));
  });

  it("student can take an available seat and release their own seat", async () => {
    const db = student("alice");
    await assertSucceeds(updateDoc(doc(db, "seats/s1_1"), { status: "occupied", heldBy: "alice", bookingId: "bk1" }));
    await assertSucceeds(updateDoc(doc(db, "seats/s1_1"), { status: "available", heldBy: null, bookingId: null }));
  });

  it("student cannot flip a seat to occupied without a matching booking; can with one", async () => {
    // booking for a different seat
    await env.withSecurityRulesDisabled(async (ctx) => {
      const c = ctx.firestore();
      await setDoc(doc(c, "users/alice/bookings/other"), booking({ seatId: "s9_9" }));
      await setDoc(doc(c, "users/bob/bookings/bobs"), booking({ userId: "bob" }));
    });
    await assertFails(updateDoc(doc(student("alice"), "seats/s1_1"), { status: "occupied", heldBy: "alice", bookingId: "other" }));
    // no such booking
    await assertFails(updateDoc(doc(student("alice"), "seats/s1_1"), { status: "occupied", heldBy: "alice", bookingId: "nope" }));
    // someone else's booking id
    await assertFails(updateDoc(doc(student("alice"), "seats/s1_1"), { status: "occupied", heldBy: "alice", bookingId: "bobs" }));
    // matching booking in the same batch as the seat flip (what the client does)
    const db = student("alice");
    const batch = writeBatch(db);
    batch.set(doc(db, "users/alice/bookings/bk2"), booking());
    batch.update(doc(db, "seats/s1_1"), { status: "occupied", heldBy: "alice", bookingId: "bk2" });
    await assertSucceeds(batch.commit());
  });

  it("student cannot free someone else's seat, take a held seat, or touch other fields", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), "seats/s1_1"), { status: "occupied", heldBy: "bob", bookingId: "x" });
    });
    await assertFails(updateDoc(doc(student("alice"), "seats/s1_1"), { status: "available", heldBy: null, bookingId: null }));
    await assertFails(updateDoc(doc(student("alice"), "seats/held"), { status: "occupied", heldBy: "alice", bookingId: "bk1" }));
    await assertFails(updateDoc(doc(student("alice"), "seats/held"), { label: "hack" }));
  });
});

describe("reservations and bookings", () => {
  it("owner can create their reservation; others cannot", async () => {
    await assertSucceeds(setDoc(doc(student("alice"), "users/alice/reservations/r2"), reservation()));
    await assertFails(setDoc(doc(student("bob"), "users/alice/reservations/r3"), reservation()));
  });

  it("invalid status values are rejected", async () => {
    await assertFails(setDoc(doc(student("alice"), "users/alice/reservations/r4"), reservation({ status: "bogus" })));
    await assertFails(setDoc(doc(student("alice"), "users/alice/reservations/r5"), reservation({ status: "completed" })));
    await assertFails(updateDoc(doc(student("alice"), "users/alice/reservations/r1"), { status: "bogus" }));
    await assertFails(updateDoc(doc(staff(), "users/alice/reservations/r1"), { status: "bogus" }));
  });

  it("owner cannot change ownership/server fields or forge states", async () => {
    const r = doc(student("alice"), "users/alice/reservations/r1");
    await assertFails(updateDoc(r, { userId: "bob" }));
    await assertFails(updateDoc(r, { qrNonce: "x" }));
    await assertFails(updateDoc(r, { status: "completed" }));
    await assertFails(setDoc(doc(student("alice"), "users/alice/reservations/r6"), { ...reservation(), copyHeld: true }));
    await assertFails(setDoc(doc(student("alice"), "users/alice/reservations/r7"), reservation({ userId: "bob" })));
    await assertSucceeds(updateDoc(r, { status: "cancelled" }));
  });

  it("staff can mark status for verification / no-show", async () => {
    await assertSucceeds(updateDoc(doc(staff(), "users/alice/bookings/bk1"), { status: "noShow" }));
    await assertSucceeds(updateDoc(doc(staff(), "users/alice/reservations/r1"), { status: "completed" }));
  });

  it("student cannot self check in a booking", async () => {
    await assertFails(updateDoc(doc(student("alice"), "users/alice/bookings/bk1"), { checkedInAt: Timestamp.now() }));
  });

  it("owner can create a seat booking and cancel it", async () => {
    await assertSucceeds(setDoc(doc(student("alice"), "users/alice/bookings/bk2"), booking()));
    await assertSucceeds(updateDoc(doc(student("alice"), "users/alice/bookings/bk2"), { status: "cancelled" }));
  });
});

describe("waitlist, notifications, loans, queue", () => {
  it("owner can join a waitlist as 'waiting' but cannot answer an offer by editing status", async () => {
    const base = { type: "book", title: "X", resourceId: "b3", userId: "alice", status: "waiting", joinedAt: Timestamp.now() };
    await assertSucceeds(setDoc(doc(student("alice"), "users/alice/waitlist/w2"), base));
    await assertFails(setDoc(doc(student("alice"), "users/alice/waitlist/w3"), { ...base, status: "offered" }));
    await assertFails(updateDoc(doc(student("alice"), "users/alice/waitlist/w1"), { status: "accepted" }));
    await assertFails(getDoc(doc(student("bob"), "users/alice/waitlist/w1")));
  });

  it("student cannot create a notification for another user or themselves; staff can", async () => {
    const n = { title: "t", body: "b", tone: "info", timestamp: Timestamp.now() };
    await assertFails(setDoc(doc(student("bob"), "users/alice/notifications/n1"), n));
    await assertFails(setDoc(doc(student("alice"), "users/alice/notifications/n2"), n));
    await assertSucceeds(setDoc(doc(staff(), "users/alice/notifications/n3"), n));
  });

  it("owner can mark a notification read and delete it, but not edit content", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "users/alice/notifications/n9"), { title: "t", body: "b", read: false });
    });
    await assertSucceeds(updateDoc(doc(student("alice"), "users/alice/notifications/n9"), { read: true }));
    await assertFails(updateDoc(doc(student("alice"), "users/alice/notifications/n9"), { title: "x" }));
    await assertSucceeds(deleteDoc(doc(student("alice"), "users/alice/notifications/n9")));
  });

  it("queue is staff only", async () => {
    await assertFails(getDoc(doc(student(), "queue/q1")));
    await assertSucceeds(getDoc(doc(staff(), "queue/q1")));
    await assertSucceeds(updateDoc(doc(staff(), "queue/q1"), { status: "active" }));
  });

  it("loans: owner reads, only renewalRequested is student-writable", async () => {
    await assertSucceeds(getDoc(doc(student("alice"), "loans/l1")));
    await assertFails(getDoc(doc(student("bob"), "loans/l1")));
    await assertSucceeds(updateDoc(doc(student("alice"), "loans/l1"), { renewalRequested: true }));
    await assertFails(updateDoc(doc(student("alice"), "loans/l1"), { renewals: 0, dueDate: Timestamp.now() }));
    await assertFails(updateDoc(doc(student("alice"), "loans/l1"), { fineAccrued: 0 }));
    await assertSucceeds(updateDoc(doc(staff(), "loans/l1"), { status: "returned" }));
  });
});

describe("collection-group reads", () => {
  it("staff can query reservations/bookings/waitlist across users; students cannot", async () => {
    const { collectionGroup, getDocs } = require("firebase/firestore");
    for (const g of ["reservations", "bookings", "waitlist"]) {
      await assertSucceeds(getDocs(collectionGroup(staff(), g)));
      await assertFails(getDocs(collectionGroup(student("alice"), g)));
    }
  });
});

describe("config and default deny", () => {
  it("config/staffAllowlist is admin-only (read and validated write)", async () => {
    await assertFails(getDoc(doc(student(), "config/staffAllowlist")));
    await assertFails(getDoc(doc(staff(), "config/staffAllowlist")));
    await assertFails(setDoc(doc(staff(), "config/staffAllowlist"), { emails: ["me@x.com"] }));
    await assertFails(setDoc(doc(student(), "config/staffAllowlist"), { emails: ["me@x.com"] }));
    await assertFails(getDoc(doc(anon(), "config/staffAllowlist")));
    await assertSucceeds(getDoc(doc(admin(), "config/staffAllowlist")));
    await assertSucceeds(setDoc(doc(admin(), "config/staffAllowlist"), { emails: ["me@x.com"] }));
    await assertFails(setDoc(doc(admin(), "config/staffAllowlist"), { emails: "me@x.com" }));
    await assertFails(setDoc(doc(admin(), "config/staffAllowlist"), { emails: [], extra: 1 }));
  });

  it("config/adminAllowlist is readable by admin only and never writable", async () => {
    await assertSucceeds(getDoc(doc(admin(), "config/adminAllowlist")));
    await assertFails(getDoc(doc(staff(), "config/adminAllowlist")));
    await assertFails(getDoc(doc(student(), "config/adminAllowlist")));
    await assertFails(setDoc(doc(admin(), "config/adminAllowlist"), { emails: ["me@x.com"] }));
  });

  it("admin counts as staff for staff-only collections", async () => {
    await assertSucceeds(setDoc(doc(admin(), "books/b9"), { title: "X" }));
  });

  it("config/library is readable when signed in and never writable", async () => {
    await assertSucceeds(getDoc(doc(student(), "config/library")));
    await assertFails(getDoc(doc(anon(), "config/library")));
    await assertFails(setDoc(doc(staff(), "config/library"), { finePerDay: 0 }));
    await assertFails(setDoc(doc(student(), "config/other"), { x: 1 }));
  });

  it("users without a role claim are not staff", async () => {
    await assertFails(getDoc(doc(noClaim(), "users/alice")));
    await assertFails(setDoc(doc(noClaim(), "books/b9"), { title: "X" }));
  });

  it("unknown collections are denied", async () => {
    await assertFails(getDoc(doc(staff(), "secrets/x")));
  });
});
