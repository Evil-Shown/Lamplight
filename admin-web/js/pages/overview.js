// Overview: live stat cards, today's activity, seat occupancy by floor.
// Metric definitions mirror AppState.dashboardStats (lib/core/state/app_state.dart).
import { el, mount, chip, fmtTime, isToday, toDate, emptyState } from "../ui.js";
import { watch, userLabel } from "../store.js";
import { pageHeader, liveIndicator, watchView } from "./_common.js";

const SVGNS = "http://www.w3.org/2000/svg";
const svg = (tag, attrs, ...kids) => {
  const n = document.createElementNS(SVGNS, tag);
  for (const [k, v] of Object.entries(attrs || {})) n.setAttribute(k, String(v));
  kids.forEach((k) => n.append(k));
  return n;
};

export function computeStats(s, now = new Date()) {
  const reservations = s.reservations.docs;
  const bookings = s.bookings.docs;
  const waitlist = s.waitlist.docs;
  const seats = s.seats.docs;
  const inSession = bookings.filter((b) => {
    const start = toDate(b.startTime), end = toDate(b.endTime);
    return b.status === "active" && end && end > now && start && start <= now;
  }).length;
  const dueToday = reservations.filter((r) => {
    const d = toDate(r.pickupBy);
    return d && isToday(d, now) && r.status !== "cancelled" && r.status !== "completed";
  }).length;
  const waiting = waitlist.filter((w) => w.status === "waiting").length;
  const occupied = seats.filter((x) => x.status === "occupied").length;
  const fill = seats.length ? Math.round((occupied / seats.length) * 100) : 0;
  return { inSession, dueToday, waiting, occupied, total: seats.length, fill };
}

function statCard(label, value, hint, href) {
  const body = [el("div", { class: "stat-value", text: String(value) }), el("div", { class: "stat-label", text: label }), hint ? el("div", { class: "muted small", text: hint }) : null];
  return href ? el("a", { class: "card stat stat-link", href }, body) : el("div", { class: "card stat" }, body);
}

function floorChart(seats) {
  const floors = new Map();
  for (const s of seats) {
    const f = Number(s.floor) || 1;
    if (!floors.has(f)) floors.set(f, { occupied: 0, limited: 0, available: 0 });
    const k = s.status === "occupied" ? "occupied" : s.status === "limited" ? "limited" : "available";
    floors.get(f)[k]++;
  }
  const rows = [...floors.entries()].sort((a, b) => a[0] - b[0]);
  if (!rows.length) return emptyState("No seats found", "Seats appear here once they exist in the seats collection.");
  const rowH = 34, left = 64, width = 560, barW = width - left - 90;
  const chart = svg("svg", { viewBox: `0 0 ${width} ${rows.length * rowH + 8}`, class: "chart", role: "img",
    "aria-label": `Seat occupancy by floor: ${rows.map(([f, c]) => `floor ${f} ${c.occupied} occupied, ${c.limited} limited, ${c.available} available`).join("; ")}` });
  rows.forEach(([f, c], i) => {
    const total = c.occupied + c.limited + c.available;
    const y = i * rowH + 4;
    const t = svg("text", { x: 0, y: y + 18, class: "chart-label" }); t.textContent = `Floor ${f}`;
    chart.append(t);
    let x = left;
    for (const [k, cls] of [["occupied", "seg-occ"], ["limited", "seg-lim"], ["available", "seg-av"]]) {
      const w = total ? (c[k] / total) * barW : 0;
      if (w > 0) chart.append(svg("rect", { x, y, width: w, height: 24, rx: 3, class: cls }));
      x += w;
    }
    const pct = total ? Math.round((c.occupied / total) * 100) : 0;
    const v = svg("text", { x: left + barW + 10, y: y + 18, class: "chart-label" }); v.textContent = `${c.occupied}/${total} (${pct}%)`;
    chart.append(v);
  });
  return el("div", {}, chart, el("ul", { class: "legend" },
    el("li", {}, el("span", { class: "sw seg-occ" }), " Occupied"), el("li", {}, el("span", { class: "sw seg-lim" }), " Limited"), el("li", {}, el("span", { class: "sw seg-av" }), " Available")));
}

function activity(s) {
  const seatById = new Map(s.seats.docs.map((x) => [x.id, x]));
  const items = [];
  for (const r of s.reservations.docs) items.push({ t: toDate(r.reservedAt), kind: "Book", what: r.bookTitle || "Book", who: userLabel(r.uid), status: r.status });
  for (const b of s.bookings.docs) {
    const seat = seatById.get(b.seatId);
    items.push({ t: toDate(b.startTime), kind: "Seat", what: seat ? `Seat ${seat.label}` : `Seat ${b.seatId || "?"}`, who: userLabel(b.uid), status: b.status });
  }
  const todays = items.filter((i) => i.t && isToday(i.t));
  const list = (todays.length ? todays : items.filter((i) => i.t)).sort((a, b) => b.t - a.t).slice(0, 10);
  if (!list.length) return emptyState("No activity yet", "New reservations and seat bookings show up here instantly.");
  return el("ul", { class: "activity" }, list.map((i) => el("li", {},
    el("span", { class: "act-kind", text: i.kind }), el("span", { class: "act-what", text: i.what }), el("span", { class: "muted", text: i.who }),
    chip(i.status), el("time", { class: "muted small", text: fmtTime(i.t) }))));
}

export function render({ container }) {
  const live = liveIndicator();
  const head = pageHeader("Overview", "Live library activity", live.el);
  const body = el("div", {});
  mount(container, head, body);
  const extras = { lowBooks: null, overdueLoans: null };
  let lastCore = null;
  const draw = () => {
    if (!lastCore || !["reservations", "bookings", "waitlist", "seats"].every((k) => lastCore[k] && lastCore[k].loaded && !lastCore[k].error)) return;
    const st = computeStats(lastCore);
    const ex = (k) => (extras[k] && !extras[k].error && extras[k].loaded ? extras[k].docs.length : null);
    const low = ex("lowBooks"), od = ex("overdueLoans");
    mount(body,
      el("div", { class: "stats" },
        statCard("Due today", st.dueToday, "Book pickups due today", "#/reservations"),
        statCard("Waitlisted", st.waiting, "People waiting for a book or seat", "#/waitlist"),
        statCard("In session", st.inSession, "Checked-in seat sessions now", "#/bookings"),
        statCard("Seat fill", `${st.fill}%`, `${st.occupied} of ${st.total} seats occupied`, "#/seats"),
        statCard("Books low on copies", low === null ? "-" : low >= 200 ? "200+" : low, low === null ? "Not available" : "1 or no copies available", "#/books"),
        statCard("Overdue loans", od === null ? "-" : od, od === null ? "Not available" : "Past due and not returned")),
      el("div", { class: "grid-2" },
        el("section", { class: "card", "aria-labelledby": "h-act" }, el("h3", { id: "h-act", text: "Today's activity" }), activity(lastCore)),
        el("section", { class: "card", "aria-labelledby": "h-floor" }, el("h3", { id: "h-floor", text: "Seat occupancy by floor" }), floorChart(lastCore.seats.docs))));
  };
  const stopCore = watchView(body, ["reservations", "bookings", "waitlist", "seats"], (snaps) => { lastCore = snaps; draw(); },
    { onSnap: (snaps) => { live.update(snaps); lastCore = snaps; }, rerenderOnUsers: true });
  // Optional extras: failures only blank their own card.
  const stopExtra = watch(["lowBooks", "overdueLoans"], (snaps) => { Object.assign(extras, snaps); draw(); });
  const tick = setInterval(draw, 60000); // "in session"/"due today" depend on the clock
  return () => { stopCore(); stopExtra(); clearInterval(tick); };
}
