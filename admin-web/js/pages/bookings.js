// Seat bookings (collection group users/*/bookings) + End session via callable endSeatSession.
import { el, mount, chip, dataTable, fmtDateTime, fmtTime, toDate, ymd, openOverlay, confirmDialog, toast } from "../ui.js";
import { call } from "../firebase.js";
import { userInfo, userLabel } from "../store.js";
import { pageHeader, liveIndicator, watchView, toolbar, selectBox, searchBox, kv } from "./_common.js";

const STATUSES = ["ready", "active", "expiringSoon", "completed", "cancelled", "expired", "noShow"];
const canEnd = (b) => b.status === "active" && !!b.checkedInAt;

export function endSessionMessage(err) {
  const code = String(err?.code || "");
  const msg = String(err?.message || "");
  if (code.endsWith("unimplemented") || (code.endsWith("not-found") && !/booking not found/i.test(msg))) return "This needs the latest server update.";
  if (code.endsWith("not-found")) return "That booking no longer exists.";
  if (code.endsWith("failed-precondition")) return "This booking is not an active checked-in session.";
  if (code.endsWith("permission-denied")) return "Your role isn't allowed to end sessions.";
  if (code.endsWith("unavailable") || code.endsWith("deadline-exceeded")) return "Network problem. Try again.";
  return "Couldn't end the session. Try again.";
}

export async function endSession(b, label) {
  const ok = await confirmDialog({ title: "End this session?", danger: true, confirmLabel: "End session",
    message: `This ends ${userLabel(b.uid)}'s session on ${label}, frees the seat and offers it to the next person on the waiting list.` });
  if (!ok) return false;
  try {
    const res = await call("endSeatSession", { bookingId: b.id, uid: b.uid });
    toast(res?.result === "alreadyEnded" ? "Session was already ended" : "Session ended", "success");
    return true;
  } catch (e) {
    toast(endSessionMessage(e), "error");
    return false;
  }
}

export function render({ container }) {
  const live = liveIndicator();
  let status = "all", date = "", q = "", snap = null;
  const seatLabel = (b) => {
    const s = snap?.seats.docs.find((x) => x.id === b.seatId);
    return s ? `${s.label} (Floor ${s.floor})` : (b.seatId || "-");
  };
  const detail = (b) => {
    const ov = openOverlay({ title: `Seat ${seatLabel(b)}`, kind: "drawer" });
    const u = userInfo(b.uid);
    ov.body.append(kv([
      ["Status", chip(b.status)], ["Student", `${userLabel(b.uid)}${u?.studentId ? ` (${u.studentId})` : ""}`], ["Email", u?.email || "-"],
      ["Seat", seatLabel(b)], ["Start", fmtDateTime(b.startTime)], ["End", fmtDateTime(b.endTime)],
      ["Checked in", b.checkedInAt ? fmtDateTime(b.checkedInAt) : "Not yet"], ["Short code", b.qrCode || "-"], ["Document", b.path],
    ]));
    const close = el("button", { class: "btn", type: "button", onClick: () => ov.close() }, "Close");
    ov.footer.append(close);
    if (canEnd(b)) {
      const end = el("button", { class: "btn btn-danger", type: "button", text: "End session" });
      end.addEventListener("click", async () => { end.disabled = true; if (await endSession(b, seatLabel(b))) ov.close(); else end.disabled = false; });
      ov.footer.append(end);
    }
  };
  const table = dataTable({
    caption: "Seat bookings", defaultSort: { key: "start", dir: "desc" }, onRowClick: detail,
    emptyTitle: "No bookings match", emptyHint: "Try clearing the filters.",
    columns: [
      { key: "seat", label: "Seat", value: (b) => seatLabel(b).toLowerCase(), render: (b) => seatLabel(b) },
      { key: "student", label: "Student", value: (b) => userLabel(b.uid).toLowerCase(),
        render: (b) => el("div", {}, el("div", { text: userLabel(b.uid) }), el("div", { class: "muted small", text: userInfo(b.uid)?.studentId || "" })) },
      { key: "start", label: "Time window", value: (b) => toDate(b.startTime)?.getTime() ?? null,
        render: (b) => { const s = toDate(b.startTime); return s ? `${ymd(s)}  ${fmtTime(s)} - ${fmtTime(b.endTime)}` : "-"; } },
      { key: "status", label: "Status", value: (b) => b.status, render: (b) => chip(b.status) },
      { key: "action", label: "Action", value: () => null, render: (b) => {
        if (!canEnd(b)) return el("span", { class: "muted small", text: "-" });
        const btn = el("button", { class: "btn btn-sm", type: "button", text: "End session" });
        btn.addEventListener("click", async (e) => { e.stopPropagation(); btn.disabled = true; await endSession(b, seatLabel(b)); btn.disabled = false; });
        return btn;
      } },
    ],
  });
  const apply = () => {
    if (!snap) return;
    const needle = q.trim().toLowerCase();
    table.refresh(snap.bookings.docs.filter((b) => {
      if (status !== "all" && b.status !== status) return false;
      if (date) { const s = toDate(b.startTime); if (!s || ymd(s) !== date) return false; }
      if (!needle) return true;
      const u = userInfo(b.uid);
      return [seatLabel(b), u?.name, u?.studentId, u?.email, b.uid, b.qrCode].filter(Boolean).join(" ").toLowerCase().includes(needle);
    }));
  };
  const search = searchBox("Search", "Seat, student or code", (v) => { q = v; apply(); });
  const dateIn = el("input", { type: "date" });
  dateIn.addEventListener("change", () => { date = dateIn.value; apply(); });
  const dateId = "bk-date"; dateIn.id = dateId;
  const tb = toolbar(search.el,
    selectBox("Status", [["all", "All statuses"], ...STATUSES.map((s) => [s, s === "noShow" ? "No-show" : s === "expiringSoon" ? "Expiring soon" : s[0].toUpperCase() + s.slice(1)])], "all", (v) => { status = v; apply(); }),
    el("div", { class: "tool" }, el("label", { for: dateId, text: "Date" }), dateIn),
    el("button", { class: "btn", type: "button", onClick: () => { dateIn.value = ""; date = ""; apply(); } }, "Clear date"));
  const body = el("div", {});
  const area = el("section", { class: "card" }, table.el);
  mount(container, pageHeader("Seat bookings", "Every seat booking. Active checked-in sessions can be ended here.", live.el), tb, body);
  return watchView(body, ["bookings", "seats"], (snaps) => { snap = snaps; mount(body, area); apply(); },
    { onSnap: (s) => live.update(s), rerenderOnUsers: true });
}
