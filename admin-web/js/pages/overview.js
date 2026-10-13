// Overview: live stat cards, today's activity, seat occupancy by floor.
// Metric definitions mirror AppState.dashboardStats (lib/core/state/app_state.dart).
import { el, mount, chip, fmtTime, isToday, toDate, emptyState } from "../ui.js";
import { icon } from "../icons.js";
import { watch, userLabel } from "../store.js";
import { pageHeader, liveIndicator, watchView } from "./_common.js";

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

function statCard(label, value, hint, href, iconName = "overview", tone = "caramel") {
  const ico = icon(iconName, { size: 20, className: "stat-ico" });
  const head = el("div", { class: "stat-head" },
    el("div", { class: `stat-icon-wrap stat-icon-${tone}` }, ico),
    href ? el("span", { class: "stat-arrow", "aria-hidden": "true" }, icon("arrowRight", { size: 14 })) : null);
  const val = el("div", { class: "stat-value", text: String(value) });
  const lbl = el("div", { class: "stat-label", text: label });
  const hnt = hint ? el("div", { class: "stat-hint muted small", text: hint }) : null;
  const content = el("div", { class: "stat-body" }, val, lbl, hnt);
  const body = [head, content];
  return href
    ? el("a", { class: `card stat stat-link stat-tone-${tone}`, href, "aria-label": `${label}: ${value}. ${hint || ""}` }, body)
    : el("div", { class: `card stat stat-tone-${tone}` }, body);
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

  let totalOcc = 0, totalLim = 0, totalAv = 0;
  const floorItems = rows.map(([f, c]) => {
    const total = c.occupied + c.limited + c.available;
    totalOcc += c.occupied;
    totalLim += c.limited;
    totalAv += c.available;
    const occPct = total ? (c.occupied / total) * 100 : 0;
    const limPct = total ? (c.limited / total) * 100 : 0;
    const avPct = total ? (c.available / total) * 100 : 0;
    const pctOccupied = total ? Math.round((c.occupied / total) * 100) : 0;

    const bar = el("div", { class: "floor-progress-track", "aria-hidden": "true" },
      occPct > 0 ? el("div", { class: "floor-seg seg-occ", style: `width: ${occPct}%`, title: `Occupied: ${c.occupied}` }) : null,
      limPct > 0 ? el("div", { class: "floor-seg seg-lim", style: `width: ${limPct}%`, title: `Limited: ${c.limited}` }) : null,
      avPct > 0 ? el("div", { class: "floor-seg seg-av", style: `width: ${avPct}%`, title: `Available: ${c.available}` }) : null);

    return el("div", { class: "floor-row" },
      el("div", { class: "floor-row-head" },
        el("span", { class: "floor-row-name", text: `Floor ${f}` }),
        el("span", { class: "floor-row-stat muted small", text: `${c.occupied}/${total} occupied (${pctOccupied}%)` })),
      bar);
  });

  const totalSeats = totalOcc + totalLim + totalAv;
  const totalFree = totalAv;
  const summaryStrip = el("div", { class: "floor-summary-strip" },
    el("div", { class: "summary-stat-box" },
      el("span", { class: "summary-val", text: String(totalSeats) }),
      el("span", { class: "summary-lbl muted small", text: "Total Seats" })),
    el("div", { class: "summary-stat-box" },
      el("span", { class: "summary-val text-success", text: String(totalFree) }),
      el("span", { class: "summary-lbl muted small", text: "Free Now" })),
    el("div", { class: "summary-stat-box" },
      el("span", { class: "summary-val text-danger", text: String(totalOcc) }),
      el("span", { class: "summary-lbl muted small", text: "In Session" })));

  const legend = el("div", { class: "chart-legend" },
    el("div", { class: "legend-item" },
      el("span", { class: "sw seg-occ" }),
      el("span", { class: "legend-text", text: `Occupied (${totalOcc})` })),
    el("div", { class: "legend-item" },
      el("span", { class: "sw seg-lim" }),
      el("span", { class: "legend-text", text: `Limited (${totalLim})` })),
    el("div", { class: "legend-item" },
      el("span", { class: "sw seg-av" }),
      el("span", { class: "legend-text", text: `Available (${totalAv})` })));

  return el("div", { class: "floor-chart-wrap" }, summaryStrip, ...floorItems, legend);
}

function activity(s, currentFilter = "all", onFilterChange) {
  const seatById = new Map(s.seats.docs.map((x) => [x.id, x]));
  const items = [];
  for (const r of s.reservations.docs) items.push({ t: toDate(r.reservedAt), kind: "Book", what: r.bookTitle || "Book", who: userLabel(r.uid), status: r.status });
  for (const b of s.bookings.docs) {
    const seat = seatById.get(b.seatId);
    items.push({ t: toDate(b.startTime), kind: "Seat", what: seat ? `Seat ${seat.label}` : `Seat ${b.seatId || "?"}`, who: userLabel(b.uid), status: b.status });
  }
  const todays = items.filter((i) => i.t && isToday(i.t));
  let list = (todays.length ? todays : items.filter((i) => i.t)).sort((a, b) => b.t - a.t);

  if (currentFilter === "book") list = list.filter((i) => i.kind === "Book");
  else if (currentFilter === "seat") list = list.filter((i) => i.kind === "Seat");
  list = list.slice(0, 10);

  const filterTabs = el("div", { class: "activity-filters" },
    ...["all", "book", "seat"].map((key) => {
      const label = key === "all" ? "All" : key === "book" ? "Books" : "Seats";
      const btn = el("button", {
        class: `filter-pill-btn ${currentFilter === key ? "active" : ""}`,
        type: "button",
        text: label
      });
      btn.addEventListener("click", () => onFilterChange && onFilterChange(key));
      return btn;
    }));

  const content = !list.length
    ? emptyState("No activity matches", "Activity appears when reservations or seat bookings are placed.")
    : el("ul", { class: "activity-list" }, list.map((i) => el("li", { class: "activity-row" },
        el("div", { class: `act-badge act-badge-${i.kind.toLowerCase()}` },
          icon(i.kind === "Book" ? "bookIcon" : "seatIcon", { size: 14 }),
          el("span", { class: "act-kind-text", text: i.kind })),
        el("div", { class: "act-meta" },
          el("span", { class: "act-what", text: i.what }),
          el("span", { class: "act-who muted small", text: i.who })),
        el("div", { class: "act-status" }, chip(i.status)),
        el("time", { class: "act-time muted small", text: fmtTime(i.t) }))));

  return el("div", { class: "activity-wrapper" }, filterTabs, content);
}

export function render({ container }) {
  const live = liveIndicator();
  const quickActions = el("div", { class: "quick-actions-bar" },
    el("a", { class: "btn btn-sm btn-ghost action-pill", href: "#/verify" },
      icon("verify", { size: 15 }), el("span", { text: "Verify pass" })),
    el("a", { class: "btn btn-sm btn-ghost action-pill", href: "#/seats" },
      icon("seats", { size: 15 }), el("span", { text: "Seat map" })),
    el("a", { class: "btn btn-sm btn-ghost action-pill", href: "#/reservations" },
      icon("reservations", { size: 15 }), el("span", { text: "Reservations" })),
    live.el);

  const head = pageHeader("Overview", "Live library operations and dispatch hub", quickActions);
  const body = el("div", {});
  mount(container, head, body);
  const extras = { lowBooks: null, overdueLoans: null };
  let lastCore = null;
  let currentActivityFilter = "all";

  const draw = () => {
    if (!lastCore || !["reservations", "bookings", "waitlist", "seats"].every((k) => lastCore[k] && lastCore[k].loaded && !lastCore[k].error)) return;
    const st = computeStats(lastCore);
    const ex = (k) => (extras[k] && !extras[k].error && extras[k].loaded ? extras[k].docs.length : null);
    const low = ex("lowBooks"), od = ex("overdueLoans");

    mount(body,
      el("div", { class: "stats" },
        statCard("Due today", st.dueToday, "Book pickups due today", "#/reservations", "dueToday", "caramel"),
        statCard("Waitlisted", st.waiting, "People waiting for a book or seat", "#/waitlist", "waitlisted", "amber"),
        statCard("In session", st.inSession, "Checked-in seat sessions now", "#/bookings", "inSession", "terracotta"),
        statCard("Seat fill", `${st.fill}%`, `${st.occupied} of ${st.total} seats occupied`, "#/seats", "seatFill", "green"),
        statCard("Books low on copies", low === null ? "-" : low >= 200 ? "200+" : low, low === null ? "Not available" : "1 or no copies available", "#/books", "lowCopies", "warm"),
        statCard("Overdue loans", od === null ? "-" : od, od === null ? "Past due and not returned", null, "overdue", "red")),
      el("div", { class: "grid-2" },
        el("section", { class: "card", "aria-labelledby": "h-act" },
          el("div", { class: "card-title-row" },
            el("h3", { id: "h-act", text: "Today's activity" }),
            el("span", { class: "card-subtitle-badge", text: "Live Feed" })),
          activity(lastCore, currentActivityFilter, (newFilter) => {
            currentActivityFilter = newFilter;
            draw();
          })),
        el("section", { class: "card", "aria-labelledby": "h-floor" },
          el("div", { class: "card-title-row" },
            el("h3", { id: "h-floor", text: "Seat occupancy by floor" }),
            el("a", { class: "card-link-action small muted", href: "#/seats" },
              el("span", { text: "Manage seats" }),
              icon("arrowRight", { size: 12 }))),
          floorChart(lastCore.seats.docs))));
  };

  const stopCore = watchView(body, ["reservations", "bookings", "waitlist", "seats"], (snaps) => { lastCore = snaps; draw(); },
    { onSnap: (snaps) => { live.update(snaps); lastCore = snaps; }, rerenderOnUsers: true });
  // Optional extras: failures only blank their own card.
  const stopExtra = watch(["lowBooks", "overdueLoans"], (snaps) => { Object.assign(extras, snaps); draw(); });
  const tick = setInterval(draw, 60000); // "in session"/"due today" depend on the clock
  return () => { stopCore(); stopExtra(); clearInterval(tick); };
}
