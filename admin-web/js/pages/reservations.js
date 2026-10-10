// Book reservations (collection group users/*/reservations).
// Rules: staff may read the group and update only {status, checkedInAt} with a valid status,
// so "Cancel reservation" is allowed. Copy accounting is done server-side by onReservationUpdated.
import { el, mount, chip, dataTable, fmtDateTime, toDate, openOverlay, confirmDialog, toast } from "../ui.js";
import { db, F } from "../firebase.js";
import { userInfo, userLabel } from "../store.js";
import { pageHeader, liveIndicator, watchView, toolbar, selectBox, searchBox, kv } from "./_common.js";

const OPEN = ["ready", "active", "expiringSoon"];
const STATUSES = ["ready", "active", "expiringSoon", "completed", "cancelled", "expired", "noShow"];

function studentText(uid) {
  const u = userInfo(uid);
  return [u?.name, u?.studentId, u?.email, uid].filter(Boolean).join(" ").toLowerCase();
}

function openDetail(r, onDone) {
  const ov = openOverlay({ title: r.bookTitle || "Reservation", kind: "drawer" });
  const u = userInfo(r.uid);
  ov.body.append(kv([
    ["Status", chip(r.status)],
    ["Student", `${userLabel(r.uid)}${u?.studentId ? ` (${u.studentId})` : ""}`],
    ["Email", u?.email || "-"],
    ["Book", r.bookTitle || "-"],
    ["Book ID", r.bookId || "-"],
    ["Reserved", fmtDateTime(r.reservedAt)],
    ["Pickup by", fmtDateTime(r.pickupBy)],
    ["Pickup location", r.pickupLocation || "-"],
    ["Short code", r.qrCode || "-"],
    ["Verified at", r.qrUsedAt ? fmtDateTime(r.qrUsedAt) : "-"],
    ["Cancel reason", r.cancelReason || null],
    ["Document", r.path],
  ]));
  const close = el("button", { class: "btn", type: "button", onClick: () => ov.close() }, "Close");
  if (OPEN.includes(r.status)) {
    const cancel = el("button", { class: "btn btn-danger", type: "button" }, "Cancel reservation");
    cancel.addEventListener("click", async () => {
      const ok = await confirmDialog({ title: "Cancel this reservation?", danger: true, confirmLabel: "Cancel reservation",
        message: `This cancels "${r.bookTitle || "this book"}" for ${userLabel(r.uid)}. The copy is released and the student is notified by the server.` });
      if (!ok) return;
      cancel.disabled = true;
      try {
        await F.updateDoc(F.doc(db, r.path), { status: "cancelled" });
        toast("Reservation cancelled", "success");
        ov.close(); onDone && onDone();
      } catch (e) {
        cancel.disabled = false;
        toast(e?.code === "permission-denied" ? "Your role isn't allowed to cancel this reservation." : "Couldn't cancel. Try again.", "error");
      }
    });
    ov.footer.append(close, cancel);
  } else {
    ov.body.append(el("p", { class: "muted small", text: "Only open reservations (ready, active, expiring soon) can be cancelled." }));
    ov.footer.append(close);
  }
}

export function render({ container }) {
  const live = liveIndicator();
  let status = "all", q = "", snap = null;
  const table = dataTable({
    caption: "Book reservations", defaultSort: { key: "reserved", dir: "desc" },
    emptyTitle: "No reservations match", emptyHint: "Try clearing the filters.",
    onRowClick: (r) => openDetail(r),
    columns: [
      { key: "student", label: "Student", value: (r) => userLabel(r.uid).toLowerCase(),
        render: (r) => el("div", {}, el("div", { text: userLabel(r.uid) }), el("div", { class: "muted small", text: userInfo(r.uid)?.studentId || "" })) },
      { key: "book", label: "Book", value: (r) => (r.bookTitle || "").toLowerCase(), render: (r) => r.bookTitle || "-" },
      { key: "status", label: "Status", value: (r) => r.status, render: (r) => chip(r.status) },
      { key: "reserved", label: "Reserved", value: (r) => toDate(r.reservedAt)?.getTime() ?? null, render: (r) => fmtDateTime(r.reservedAt) },
      { key: "pickup", label: "Pickup by", value: (r) => toDate(r.pickupBy)?.getTime() ?? null, render: (r) => fmtDateTime(r.pickupBy) },
    ],
  });
  const apply = () => {
    if (!snap) return;
    const needle = q.trim().toLowerCase();
    table.refresh(snap.reservations.docs.filter((r) =>
      (status === "all" || r.status === status) &&
      (!needle || (r.bookTitle || "").toLowerCase().includes(needle) || studentText(r.uid).includes(needle) || (r.qrCode || "").toLowerCase().includes(needle))));
  };
  const search = searchBox("Search", "Student, book or code", (v) => { q = v; apply(); });
  const tb = toolbar(search.el, selectBox("Status", [["all", "All statuses"], ...STATUSES.map((s) => [s, s === "noShow" ? "No-show" : s === "expiringSoon" ? "Expiring soon" : s[0].toUpperCase() + s.slice(1)])], "all", (v) => { status = v; apply(); }));
  const body = el("div", {});
  const area = el("section", { class: "card" }, table.el);
  mount(container, pageHeader("Reservations", "All book reservations. Select a row for details.", live.el), tb, body);
  return watchView(body, ["reservations"], (snaps) => { snap = snaps; mount(body, area); apply(); },
    { onSnap: (s) => { live.update(s); }, rerenderOnUsers: true });
}
