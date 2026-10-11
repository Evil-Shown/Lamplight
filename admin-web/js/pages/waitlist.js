// Waiting list (collection group users/*/waitlist). Read-only: the rules would let staff
// update/delete entries, but no callable promotes/removes on a staff's behalf, and
// editing `status` directly would bypass the server-side offer flow - so this page does not.
import { el, mount, chip, dataTable, fmtDateTime, toDate, openOverlay } from "../ui.js";
import { userInfo, userLabel } from "../store.js";
import { pageHeader, liveIndicator, watchView, toolbar, selectBox, searchBox, kv } from "./_common.js";

const STATUSES = ["waiting", "offered", "accepted", "declined", "expired"];
const joined = (w) => toDate(w.joinedAt ?? w.queuedAt);

export function render({ container }) {
  const live = liveIndicator();
  let type = "all", status = "all", q = "", snap = null;
  const detail = (w) => {
    const ov = openOverlay({ title: w.title || "Waiting-list entry", kind: "drawer" });
    const u = userInfo(w.uid);
    ov.body.append(kv([
      ["Status", chip(w.status)], ["Type", w.type === "book" ? "Book" : "Seat"], ["Resource", w.title || "-"], ["Details", w.subtitle || null],
      ["Resource ID", w.resourceId || "-"], ["Student", `${userLabel(w.uid)}${u?.studentId ? ` (${u.studentId})` : ""}`], ["Email", u?.email || "-"],
      ["Position", w.position != null ? String(w.position) : "-"], ["Joined", fmtDateTime(joined(w))],
      ["Estimated wait", w.estimatedWaitMinutes != null ? `${w.estimatedWaitMinutes} min` : null],
      ["Offer expires", w.offerExpiresAt ? fmtDateTime(w.offerExpiresAt) : null], ["Seat preference", w.seatPreference || null],
    ]), el("p", { class: "muted small", text: "Read-only. Offers are made and answered by the server and the student, not edited by hand." }));
    ov.footer.append(el("button", { class: "btn", type: "button", onClick: () => ov.close() }, "Close"));
  };
  const table = dataTable({
    caption: "Waiting list", defaultSort: { key: "joined", dir: "asc" }, onRowClick: detail,
    emptyTitle: "Nobody is waiting", emptyHint: "Entries appear when students join a waiting list.",
    columns: [
      { key: "type", label: "Type", value: (w) => w.type || "", render: (w) => w.type === "book" ? "Book" : "Seat" },
      { key: "resource", label: "Resource", value: (w) => (w.title || "").toLowerCase(),
        render: (w) => el("div", {}, el("div", { text: w.title || "-" }), el("div", { class: "muted small", text: w.subtitle || "" })) },
      { key: "student", label: "Student", value: (w) => userLabel(w.uid).toLowerCase(), render: (w) => userLabel(w.uid) },
      { key: "position", label: "Position", numeric: true, value: (w) => (typeof w.position === "number" ? w.position : null), render: (w) => (w.position ?? "-") },
      { key: "joined", label: "Joined", value: (w) => joined(w)?.getTime() ?? null, render: (w) => fmtDateTime(joined(w)) },
      { key: "status", label: "Status", value: (w) => w.status, render: (w) => chip(w.status) },
    ],
  });
  const apply = () => {
    if (!snap) return;
    const needle = q.trim().toLowerCase();
    table.refresh(snap.waitlist.docs.filter((w) =>
      (type === "all" || w.type === type) && (status === "all" || w.status === status) &&
      (!needle || [w.title, w.subtitle, w.resourceId, userInfo(w.uid)?.name, userInfo(w.uid)?.studentId, w.uid].filter(Boolean).join(" ").toLowerCase().includes(needle))));
  };
  const tb = toolbar(searchBox("Search", "Resource or student", (v) => { q = v; apply(); }).el,
    selectBox("Type", [["all", "Books and seats"], ["book", "Books"], ["seat", "Seats"]], "all", (v) => { type = v; apply(); }),
    selectBox("Status", [["all", "All statuses"], ...STATUSES.map((s) => [s, s[0].toUpperCase() + s.slice(1)])], "all", (v) => { status = v; apply(); }));
  const body = el("div", {});
  const area = el("section", { class: "card" }, table.el);
  mount(container, pageHeader("Waiting list", "Students waiting for a book or a seat.", live.el), tb, body);
  return watchView(body, ["waitlist"], (snaps) => { snap = snaps; mount(body, area); apply(); },
    { onSnap: (s) => live.update(s), rerenderOnUsers: true });
}
