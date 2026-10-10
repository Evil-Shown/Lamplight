// Seat map grouped by floor (live). "Release seat" is a direct staff write to seats/{id}
// (rules: staff may update seats). It frees the seat only; it does not end the booking.
import { el, mount, chip, openOverlay, confirmDialog, toast, emptyState } from "../ui.js";
import { db, F } from "../firebase.js";
import { userLabel } from "../store.js";
import { pageHeader, liveIndicator, watchView, kv } from "./_common.js";

const CATEGORY = { quietZone: "Quiet zone", collaborative: "Collaborative", individualPod: "Individual pod" };

function openSeat(s) {
  const ov = openOverlay({ title: `Seat ${s.label || s.id}`, kind: "drawer" });
  const yes = (v) => (v ? "Yes" : "No");
  ov.body.append(kv([
    ["Status", chip(s.status || "available")], ["Floor", String(s.floor ?? "-")], ["Section", s.section || "-"], ["Category", CATEGORY[s.category] || s.category || "-"],
    ["Power outlet", yes(s.hasPowerOutlet)], ["Monitor", yes(s.hasMonitor)], ["Near window", yes(s.nearWindow)], ["Standing desk", yes(s.standingDesk)],
    s.heldBy ? ["Held by", userLabel(s.heldBy)] : null, s.bookingId ? ["Booking ID", s.bookingId] : null, s.heldFor ? ["Held for (waitlist)", userLabel(s.heldFor)] : null,
  ]));
  const close = el("button", { class: "btn", type: "button", onClick: () => ov.close() }, "Close");
  ov.footer.append(close);
  if (s.status !== "available") {
    const rel = el("button", { class: "btn btn-danger", type: "button" }, "Release seat");
    rel.addEventListener("click", async () => {
      const ok = await confirmDialog({ title: `Release seat ${s.label || s.id}?`, danger: true, confirmLabel: "Release seat",
        message: `Seat ${s.label || s.id} on floor ${s.floor ?? "?"} becomes available and its holder is cleared. A booking that still exists is not cancelled - use "End session" on the Seat bookings page for that.` });
      if (!ok) return;
      rel.disabled = true;
      try {
        await F.updateDoc(F.doc(db, "seats", s.id), { status: "available", heldBy: F.deleteField(), bookingId: F.deleteField() });
        toast(`Seat ${s.label || s.id} released`, "success"); ov.close();
      } catch (e) { rel.disabled = false; toast(e?.code === "permission-denied" ? "Your role isn't allowed to change seats." : "Couldn't release the seat. Try again.", "error"); }
    });
    ov.footer.append(rel);
  } else {
    ov.body.append(el("p", { class: "muted small", text: "This seat is already available." }));
  }
}

export function render({ container }) {
  const live = liveIndicator();
  const body = el("div", {});
  mount(container, pageHeader("Seats", "Live seat status by floor. Select a seat for details.", live.el), body);
  return watchView(body, ["seats"], (snaps) => {
    const seats = snaps.seats.docs;
    if (!seats.length) { mount(body, emptyState("No seats found", "Seats are created by the seed script.")); return; }
    const floors = new Map();
    for (const s of seats) { const f = Number(s.floor) || 1; if (!floors.has(f)) floors.set(f, []); floors.get(f).push(s); }
    const counts = (list) => `${list.filter((s) => s.status === "occupied").length} occupied, ${list.filter((s) => s.status === "limited").length} limited, ${list.filter((s) => (s.status || "available") === "available").length} available`;
    mount(body, [...floors.entries()].sort((a, b) => a[0] - b[0]).map(([f, list]) => {
      list.sort((a, b) => (a.row ?? 0) - (b.row ?? 0) || (a.col ?? 0) - (b.col ?? 0) || String(a.label).localeCompare(String(b.label), undefined, { numeric: true }));
      return el("section", { class: "card floor", "aria-label": `Floor ${f}` },
        el("div", { class: "floor-head" }, el("h3", { text: `Floor ${f}` }), el("p", { class: "muted small", text: counts(list) })),
        el("div", { class: "seat-grid" }, list.map((s) => el("button", { class: `seat seat-${s.status || "available"}`, type: "button", onClick: () => openSeat(s),
          "aria-label": `Seat ${s.label || s.id}, ${s.status || "available"}` },
        el("span", { class: "seat-label", text: s.label || s.id }), el("span", { class: "seat-state", text: (s.status || "available") === "available" ? "Free" : s.status === "limited" ? "Limited" : "Taken" })))));
    }));
  }, { onSnap: (s) => live.update(s) });
}
