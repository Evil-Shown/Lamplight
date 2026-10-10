// Ref-counted live listeners. Pages call watch([...keys], cb) and get an
// unsubscribe function; the router calls it on route change, auth.js calls
// stopAll() on sign-out. A Firestore listener is only open while someone uses it.
import { db, F } from "./firebase.js";

const { collection, collectionGroup, query, where, limit, onSnapshot, Timestamp, getDocs, documentId } = F;

// Same unfiltered collection-group reads as the Flutter staff streams
// (firestore_service.dart allReservationsSnapshot & co): no index needed.
const SOURCES = {
  reservations: () => collectionGroup(db, "reservations"),
  bookings: () => collectionGroup(db, "bookings"),
  waitlist: () => collectionGroup(db, "waitlist"),
  seats: () => collection(db, "seats"),
  // Books running low (<= 1 copy). Single-field range: auto-indexed.
  lowBooks: () => query(collection(db, "books"), where("copiesAvailable", "<=", 1), limit(200)),
  // Overdue loans. Uses the existing composite index loans(status, dueDate).
  overdueLoans: () => query(collection(db, "loans"), where("status", "in", ["active", "overdue"]),
    where("dueDate", "<", Timestamp.now())),
};

const slots = new Map(); // key -> { unsub, subs:Set, data }
const users = new Map(); // uid -> { name, studentId, email } (profile cache)
const pendingUsers = new Set();

function slotFor(key) {
  let s = slots.get(key);
  if (s) return s;
  s = { subs: new Set(), data: { docs: [], loaded: false, error: null, fromCache: false }, unsub: null };
  slots.set(key, s);
  start(key, s);
  return s;
}

function start(key, s) {
  s.data = { docs: s.data.docs, loaded: false, error: null, fromCache: false };
  try {
    s.unsub = onSnapshot(SOURCES[key](), { includeMetadataChanges: true }, (snap) => {
      const docs = snap.docs.map((d) => ({
        id: d.id, path: d.ref.path,
        uid: d.ref.parent.parent && d.ref.parent.parent.parent.id === "users" ? d.ref.parent.parent.id : null,
        ...d.data(),
      }));
      s.data = { docs, loaded: true, error: null, fromCache: snap.metadata.fromCache, updatedAt: new Date() };
      if (key === "reservations" || key === "bookings" || key === "waitlist") resolveUsers(docs.map((d) => d.uid));
      notify(s);
    }, (error) => {
      s.data = { docs: [], loaded: true, error, fromCache: false };
      notify(s);
    });
  } catch (error) {
    s.data = { docs: [], loaded: true, error, fromCache: false };
  }
}
function notify(s) { for (const cb of [...s.subs]) cb(); }

/** Subscribe to several sources. cb receives a snapshot object keyed by source. */
export function watch(keys, cb) {
  const mine = [];
  const run = () => cb(Object.fromEntries(keys.map((k) => [k, slots.get(k)?.data])));
  for (const k of keys) {
    if (!SOURCES[k]) throw new Error(`Unknown source ${k}`);
    const s = slotFor(k);
    s.subs.add(run);
    mine.push([k, s]);
  }
  run();
  return () => {
    for (const [k, s] of mine) {
      s.subs.delete(run);
      if (s.subs.size === 0) { if (s.unsub) s.unsub(); slots.delete(k); }
    }
  };
}

/** Restart one failed source (Try again button). */
export function restart(key) {
  const s = slots.get(key);
  if (!s) return;
  if (s.unsub) s.unsub();
  start(key, s);
  notify(s);
}

export function stopAll() {
  for (const s of slots.values()) { if (s.unsub) s.unsub(); s.subs.clear(); }
  slots.clear();
  users.clear();
  pendingUsers.clear();
}

// ---- user profile lookup (rules: staff may read users/{uid}) ----
const userListeners = new Set();
export function onUsersChanged(cb) { userListeners.add(cb); return () => userListeners.delete(cb); }
export function userInfo(uid) { return users.get(uid) || null; }
export function userLabel(uid) {
  const u = users.get(uid);
  if (u && (u.name || u.studentId)) return u.name || u.studentId;
  return uid ? `${uid.slice(0, 6)}…` : "-";
}

async function resolveUsers(uids) {
  const need = [...new Set(uids)].filter((u) => u && !users.has(u) && !pendingUsers.has(u));
  if (!need.length) return;
  need.forEach((u) => pendingUsers.add(u));
  for (let i = 0; i < need.length; i += 30) {
    const chunk = need.slice(i, i + 30);
    try {
      const snap = await getDocs(query(collection(db, "users"), where(documentId(), "in", chunk)));
      snap.forEach((d) => {
        const x = d.data();
        users.set(d.id, { name: x.name || "", studentId: x.studentId || "", email: x.email || "" });
      });
    } catch (err) {
      console.warn("user lookup failed", err);
    }
    chunk.forEach((u) => { pendingUsers.delete(u); if (!users.has(u)) users.set(u, { name: "", studentId: "", email: "" }); });
  }
  userListeners.forEach((cb) => cb());
}
