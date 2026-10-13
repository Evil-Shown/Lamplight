// App shell: login vs dashboard, nav, theme toggle, header, footer.
import { initAuth, signOutNow } from "./auth.js";
import { startRouter, stopRouter, visibleRoutes, currentPath } from "./router.js";
import { stopAll } from "./store.js";
import { el, mount, clear, toast } from "./ui.js";
import { icon } from "./icons.js";
import { renderLogin } from "./pages/login.js";
import { APP_VERSION } from "./firebase-config.js";
import { usingEmulator } from "./firebase.js";

const app = document.getElementById("app");
let shellUid = null;

function store(key, val) { try { if (val === undefined) return localStorage.getItem(key); localStorage.setItem(key, val); } catch { /* ignore */ } return null; }

function applyTheme(t) {
  if (t === "light" || t === "dark") document.documentElement.setAttribute("data-theme", t);
  else document.documentElement.removeAttribute("data-theme");
}
function effectiveTheme() {
  const t = document.documentElement.getAttribute("data-theme");
  return t || (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
}

function buildShell(st) {
  const role = st.role;
  const user = st.user;
  const routes = visibleRoutes(role);
  const sections = [];
  for (const r of routes) {
    const secName = r.section || "Main";
    let group = sections.find((s) => s.name === secName);
    if (!group) {
      group = { name: secName, items: [] };
      sections.push(group);
    }
    group.items.push(r);
  }

  const navElements = [];
  sections.forEach((sec, idx) => {
    if (idx > 0 || sec.name !== "Main") {
      navElements.push(el("div", { class: "nav-section-title", text: sec.name }));
    }
    sec.items.forEach((r) => {
      navElements.push(
        el("a", { class: "nav-link", href: `#/${r.path}`, "data-path": r.path },
          el("span", { class: "nav-ico", "aria-hidden": "true" }, icon(r.iconKey || "overview", { size: 18 })),
          el("span", { class: "nav-label", text: r.label }))
      );
    });
  });
  const nav = el("nav", { class: "sidebar", id: "sidebar", "aria-label": "Main" },
    el("div", { class: "side-brand" },
      el("img", { src: "favicon.png", alt: "", width: "28", height: "28", class: "brand-logo" }),
      el("span", { class: "brand-name", text: "Lamplight" }),
      el("span", { class: "brand-badge", text: "STAFF" })),
    el("div", { class: "nav-list" }, ...navElements));
  const scrim = el("div", { class: "nav-scrim" });
  const mobileQuery = window.matchMedia("(max-width: 900px)");
  const menuBtn = el("button", { class: "btn btn-ghost icon-btn menu-btn", type: "button", "aria-label": "Toggle navigation", "aria-controls": "sidebar", "aria-expanded": "false" },
    icon("menu", { size: 20 }));
  const setOpen = (open) => {
    document.body.classList.toggle("nav-open", open);
    menuBtn.setAttribute("aria-expanded", String(open));
  };
  menuBtn.addEventListener("click", () => {
    if (mobileQuery.matches) setOpen(!document.body.classList.contains("nav-open"));
    else {
      const c = !document.body.classList.contains("nav-collapsed");
      document.body.classList.toggle("nav-collapsed", c); store("lamplight-admin-nav", c ? "collapsed" : "open");
      menuBtn.setAttribute("aria-expanded", String(!c));
    }
  });
  if (!mobileQuery.matches && store("lamplight-admin-nav") === "collapsed") document.body.classList.add("nav-collapsed");
  scrim.addEventListener("click", () => setOpen(false));
  nav.addEventListener("click", (e) => { if (e.target.closest("a")) setOpen(false); });
  document.addEventListener("keydown", (e) => { if (e.key === "Escape" && document.body.classList.contains("nav-open") && !document.querySelector(".ov-root")) { setOpen(false); menuBtn.focus(); } });

  const title = el("h1", { class: "page-title", id: "page-title", text: "" });
  const themeBtn = el("button", { class: "btn btn-ghost icon-btn theme-toggle-btn", type: "button" });
  const syncTheme = () => {
    const dark = effectiveTheme() === "dark";
    clear(themeBtn);
    themeBtn.append(icon(dark ? "sun" : "moon", { size: 18 }));
    themeBtn.setAttribute("aria-label", dark ? "Switch to light theme" : "Switch to dark theme");
    themeBtn.setAttribute("title", dark ? "Switch to light theme" : "Switch to dark theme");
  };
  themeBtn.addEventListener("click", () => {
    const next = effectiveTheme() === "dark" ? "light" : "dark";
    applyTheme(next); store("lamplight-admin-theme", next); syncTheme();
  });
  syncTheme();

  const name = user.displayName || user.email || "Signed in";
  const cleanName = (user.displayName || user.email || "").replace(/[^a-zA-Z0-9 ]/g, "").trim();
  const initials = (cleanName ? cleanName.split(/\s+/).map((w) => w[0]).slice(0, 2).join("") : "U").toUpperCase();
  const roleLabel = role === "admin" ? "Administrator" : "Library staff";
  const avatar = el("div", { class: "who-avatar", "aria-hidden": "true", text: initials });
  const who = el("div", { class: "who" },
    avatar,
    el("div", { class: "who-text" }, el("span", { class: "who-name", text: name }), user.displayName ? el("span", { class: "who-email muted small", text: user.email || "" }) : null),
    el("span", { class: `role-badge role-${role}`, text: roleLabel }));
  const signOut = el("button", { class: "btn btn-ghost signout-btn", type: "button", "aria-label": "Sign out" },
    icon("logout", { size: 16 }),
    el("span", { class: "signout-text", text: "Sign out" }));
  signOut.addEventListener("click", () => signOutNow());

  const header = el("header", { class: "topbar" }, menuBtn, title, el("div", { class: "spacer" }), usingEmulator ? el("span", { class: "chip chip-warn", text: "Emulator" }) : null, themeBtn, who, signOut);
  const main = el("main", { class: "content", id: "main", tabindex: "-1", "aria-labelledby": "page-title" });
  const footer = el("footer", { class: "footer muted small" },
    el("span", { text: `Lamplight Staff Dashboard v${APP_VERSION}` }),
    el("span", { class: "footer-dot", text: " • " }),
    el("span", { text: "Library Administration" }));
  mount(app, el("div", { class: "shell" }, nav, scrim, el("div", { class: "shell-main" }, header, el("div", { class: "content-wrap" }, main), footer)));
  document.getElementById("app").className = "";
  return { main, title };
}

function markNav(route, titleEl) {
  document.querySelectorAll(".nav-link").forEach((a) => {
    const on = a.dataset.path === route.path;
    if (on) a.setAttribute("aria-current", "page"); else a.removeAttribute("aria-current");
  });
  titleEl.textContent = route.label;
  document.title = `${route.label} - Lamplight Staff`;
}

initAuth((st) => {
  if (st.status === "ready") {
    if (shellUid === st.user.uid) return; // role refresh only
    shellUid = st.user.uid;
    stopRouter();
    const { main, title } = buildShell(st);
    if (!location.hash) location.replace("#/overview");
    startRouter(main, { role: st.role, user: st.user }, (route) => markNav(route, title));
    return;
  }
  // Anything but ready: tear down listeners + shell, show only the login page.
  if (shellUid) { shellUid = null; stopRouter(); stopAll(); document.body.classList.remove("nav-open", "nav-collapsed"); }
  document.title = "Sign in - Lamplight Staff";
  renderLogin(app, st);
});

window.addEventListener("online", () => toast("Back online", "info"));
window.addEventListener("offline", () => toast("You're offline - data may be out of date", "error"));
void currentPath;
