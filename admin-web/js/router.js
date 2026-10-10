// Hash router (#/overview ...). Each page module exports `render(ctx)` and may
// return a cleanup function; the router calls it on every route change.
import { mount, el, closeAllOverlays } from "./ui.js";

export const ROUTES = [
  { path: "overview", label: "Overview", icon: "▦", load: () => import("./pages/overview.js") },
  { path: "reservations", label: "Reservations", icon: "❙", load: () => import("./pages/reservations.js") },
  { path: "bookings", label: "Seat bookings", icon: "▣", load: () => import("./pages/bookings.js") },
  { path: "waitlist", label: "Waiting list", icon: "⌛", load: () => import("./pages/waitlist.js") },
  { path: "books", label: "Books", icon: "☱", load: () => import("./pages/books.js") },
  { path: "seats", label: "Seats", icon: "☖", load: () => import("./pages/seats.js") },
  { path: "verify", label: "Verify pass", icon: "✓", load: () => import("./pages/verify.js") },
  { path: "staff", label: "Staff", icon: "☺", admin: true, load: () => import("./pages/staff.js") },
];

let cleanup = null;
let token = 0;
let ctx = null;
let container = null;
let onChange = () => {};

export function currentPath() {
  const p = location.hash.replace(/^#\/?/, "").split("?")[0];
  return p || "overview";
}
export function visibleRoutes(role) { return ROUTES.filter((r) => !r.admin || role === "admin"); }

async function resolve() {
  const my = ++token;
  if (cleanup) { try { cleanup(); } catch (e) { console.error(e); } cleanup = null; }
  closeAllOverlays();
  let route = ROUTES.find((r) => r.path === currentPath());
  if (!route) { location.replace("#/overview"); return; }
  onChange(route);
  if (route.admin && ctx.role !== "admin") {
    mount(container, el("div", { class: "state state-error", role: "alert" },
      el("h2", { text: "Administrators only" }), el("p", { text: "This page is only available to library administrators." })));
    return;
  }
  mount(container, el("div", { class: "state", role: "status" }, el("div", { class: "spinner", "aria-hidden": "true" }), el("p", { text: "Loading…" })));
  try {
    const mod = await route.load();
    if (my !== token) return;
    mount(container);
    const c = await mod.render({ container, role: ctx.role, user: ctx.user });
    if (my !== token) { if (typeof c === "function") c(); return; }
    cleanup = typeof c === "function" ? c : null;
  } catch (err) {
    console.error(err);
    if (my !== token) return;
    mount(container, el("div", { class: "state state-error", role: "alert" },
      el("h2", { text: "This page failed to load" }), el("p", { text: "Reload the page and try again." })));
  }
  container.focus({ preventScroll: true });
}

export function startRouter(el_, context, changeCb) {
  container = el_; ctx = context; onChange = changeCb || (() => {});
  window.addEventListener("hashchange", resolve);
  resolve();
}
export function stopRouter() {
  window.removeEventListener("hashchange", resolve);
  token++;
  if (cleanup) { try { cleanup(); } catch (e) { console.error(e); } cleanup = null; }
  closeAllOverlays();
}
