// Small DOM/UI toolkit. Never uses innerHTML with data: everything is built with
// createElement + textContent (book titles / names are user-controlled).

export function el(tag, props, ...children) {
  const n = document.createElement(tag);
  if (props) {
    for (const [k, v] of Object.entries(props)) {
      if (v === undefined || v === null || v === false) continue;
      if (k === "class") n.className = v;
      else if (k === "text") n.textContent = v;
      else if (k.startsWith("on") && typeof v === "function") n.addEventListener(k.slice(2).toLowerCase(), v);
      else if (v === true) n.setAttribute(k, "");
      else n.setAttribute(k, String(v));
    }
  }
  append(n, children);
  return n;
}
function append(n, children) {
  for (const c of children.flat(Infinity)) {
    if (c === null || c === undefined || c === false) continue;
    n.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
}
export function clear(n) { while (n.firstChild) n.removeChild(n.firstChild); }
export function mount(n, ...children) { clear(n); append(n, children); }
/** Escape helper for the rare place a string must be embedded in HTML text. */
export function escapeHtml(s) {
  const map = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
  return String(s ?? "").replace(/[&<>"']/g, (c) => map[c]);
}

// ---------------------------------------------------------------- formatting
export function toDate(v) {
  if (!v) return null;
  if (typeof v.toDate === "function") return v.toDate();
  if (v instanceof Date) return v;
  if (typeof v === "number") return new Date(v);
  if (typeof v === "string") { const d = new Date(v); return isNaN(d) ? null : d; }
  return null;
}
const dtf = new Intl.DateTimeFormat(undefined, { dateStyle: "medium", timeStyle: "short" });
const tf = new Intl.DateTimeFormat(undefined, { timeStyle: "short" });
export const fmtDateTime = (v) => { const d = toDate(v); return d ? dtf.format(d) : "-"; };
export const fmtTime = (v) => { const d = toDate(v); return d ? tf.format(d) : "-"; };
export function isToday(d, now = new Date()) {
  return !!d && d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth() && d.getDate() === now.getDate();
}
export function ymd(d) {
  const p = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

// -------------------------------------------------------------------- chips
const STATUS_LABEL = {
  ready: "Ready", active: "Active", expiringSoon: "Expiring soon", completed: "Completed",
  cancelled: "Cancelled", expired: "Expired", noShow: "No-show",
  waiting: "Waiting", offered: "Offered", accepted: "Accepted", declined: "Declined",
  available: "Available", limited: "Limited", occupied: "Occupied", onLoan: "On loan", waitlisted: "Waitlisted",
};
const STATUS_TONE = {
  ready: "info", active: "ok", expiringSoon: "warn", completed: "neutral", cancelled: "neutral",
  expired: "bad", noShow: "bad", waiting: "warn", offered: "info", accepted: "ok", declined: "neutral",
  available: "ok", limited: "warn", occupied: "bad", onLoan: "warn", waitlisted: "warn",
};
export const statusLabel = (s) => STATUS_LABEL[s] ?? String(s ?? "Unknown");
/** Chip always carries a text label (never colour alone). */
export function chip(status) {
  return el("span", { class: `chip chip-${STATUS_TONE[status] ?? "neutral"}`, text: statusLabel(status) });
}

// -------------------------------------------------------------------- toast
let toastRegion;
export function toast(message, kind = "info") {
  if (!toastRegion) {
    toastRegion = el("div", { class: "toasts", role: "status", "aria-live": "polite", "aria-atomic": "false" });
    document.body.append(toastRegion);
  }
  const t = el("div", { class: `toast toast-${kind}`, text: message });
  toastRegion.append(t);
  setTimeout(() => t.remove(), kind === "error" ? 8000 : 4500);
}

// ------------------------------------------------------- overlays (a11y)
const FOCUSABLE = 'a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])';
/**
 * Opens a modal dialog or a right-hand drawer. Escape closes, focus is trapped
 * and returned to the opener. Returns { close, body, footer, root }.
 */
export function openOverlay({ title, kind = "dialog", onClose, wide = false }) {
  const opener = document.activeElement;
  const titleId = `ov-${Math.random().toString(36).slice(2, 8)}`;
  const body = el("div", { class: "ov-body" });
  const footer = el("div", { class: "ov-footer" });
  const closeBtn = el("button", { class: "btn btn-ghost icon-btn", type: "button", "aria-label": "Close" }, "✕");
  const panel = el("div", {
    class: `ov-panel ov-${kind}${wide ? " ov-wide" : ""}`, role: "dialog",
    "aria-modal": "true", "aria-labelledby": titleId, tabindex: "-1",
  }, el("div", { class: "ov-head" }, el("h2", { id: titleId, text: title }), closeBtn), body, footer);
  const root = el("div", { class: "ov-root" }, el("div", { class: "ov-scrim" }), panel);
  document.body.append(root);
  document.body.classList.add("no-scroll");
  let closed = false;
  const close = (result) => {
    if (closed) return;
    closed = true;
    root.remove();
    document.removeEventListener("keydown", onKey, true);
    if (!document.querySelector(".ov-root")) document.body.classList.remove("no-scroll");
    if (opener && opener.focus && document.contains(opener)) opener.focus();
    if (onClose) onClose(result);
  };
  function onKey(e) {
    const all = document.querySelectorAll(".ov-root");
    if (root !== all[all.length - 1]) return;
    if (e.key === "Escape") { e.stopPropagation(); close(); return; }
    if (e.key !== "Tab") return;
    const items = [...panel.querySelectorAll(FOCUSABLE)].filter((n) => n.offsetParent !== null);
    if (!items.length) { e.preventDefault(); panel.focus(); return; }
    const first = items[0];
    const last = items[items.length - 1];
    if (e.shiftKey && (document.activeElement === first || document.activeElement === panel)) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  }
  document.addEventListener("keydown", onKey, true);
  root.querySelector(".ov-scrim").addEventListener("click", () => close());
  closeBtn.addEventListener("click", () => close());
  requestAnimationFrame(() => { (panel.querySelector("[autofocus]") || closeBtn).focus(); });
  return { close, body, footer, root };
}

/** Closes every open overlay (used on sign-out / route change). */
export function closeAllOverlays() {
  document.querySelectorAll(".ov-root").forEach((n) => n.remove());
  document.body.classList.remove("no-scroll");
}

/** Promise<boolean> confirm dialog. */
export function confirmDialog({ title, message, confirmLabel = "Confirm", danger = false, details }) {
  return new Promise((resolve) => {
    let result = false;
    const ov = openOverlay({ title, onClose: () => resolve(result) });
    ov.body.append(el("p", { text: message }), details || "");
    const cancel = el("button", { class: "btn", type: "button", onClick: () => ov.close() }, "Cancel");
    const ok = el("button", { class: `btn ${danger ? "btn-danger" : "btn-primary"}`, type: "button",
      onClick: () => { result = true; ov.close(); } }, confirmLabel);
    ov.footer.append(cancel, ok);
    cancel.focus();
  });
}

// ------------------------------------------------------------ page states
export function loadingState(text = "Loading…") {
  return el("div", { class: "state", role: "status" }, el("div", { class: "spinner", "aria-hidden": "true" }), el("p", { text }));
}
export function emptyState(title, hint) {
  return el("div", { class: "state" }, el("h3", { text: title }), hint ? el("p", { class: "muted", text: hint }) : null);
}
export function errorState(err, retry) {
  const code = err && err.code ? String(err.code) : "";
  const msg = code.endsWith("permission-denied")
    ? "You don't have permission to read this data. Your role may have changed - try signing in again."
    : code.endsWith("failed-precondition")
      ? "This view needs a database index that hasn't been deployed yet. Ask an administrator to run: firebase deploy --only firestore:indexes"
      : (err && err.message) || "Something went wrong.";
  return el("div", { class: "state state-error", role: "alert" }, el("h3", { text: "Couldn't load this data" }), el("p", { text: msg }),
    retry ? el("button", { class: "btn", type: "button", onClick: retry }, "Try again") : null);
}

// ------------------------------------------------------------- data table
/**
 * columns: [{ key, label, value(row) -> sortable primitive, render?(row) -> Node|string, numeric? }]
 * Returns { el, setRows(rows) }. Click a header button to sort; rows are keyboard-activatable.
 */
export function dataTable({ columns, caption, onRowClick, pageSize = 100, emptyTitle = "Nothing to show", emptyHint, defaultSort }) {
  let rows = [];
  let sort = defaultSort || null; // { key, dir }
  let shown = pageSize;
  const wrap = el("div", { class: "table-wrap", tabindex: "0", role: "region", "aria-label": `${caption} (scrollable)` });
  const more = el("div", { class: "table-more" });
  const root = el("div", {}, wrap, more);

  function render() {
    const list = rows.slice();
    if (sort) {
      const col = columns.find((c) => c.key === sort.key);
      if (col) {
        const dir = sort.dir === "asc" ? 1 : -1;
        list.sort((a, b) => {
          const x = col.value(a);
          const y = col.value(b);
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return (x < y ? -1 : x > y ? 1 : 0) * dir;
        });
      }
    }
    mount(more);
    if (!list.length) { mount(wrap, emptyState(emptyTitle, emptyHint)); return; }
    const head = el("tr", {}, columns.map((c) => {
      const active = sort && sort.key === c.key;
      return el("th", { scope: "col", "aria-sort": active ? (sort.dir === "asc" ? "ascending" : "descending") : "none", class: c.numeric ? "num" : "" },
        el("button", { class: "th-btn", type: "button", onClick: () => {
          sort = { key: c.key, dir: active && sort.dir === "asc" ? "desc" : "asc" };
          render();
        } }, c.label, el("span", { "aria-hidden": "true", class: "sort-ind", text: active ? (sort.dir === "asc" ? " ▲" : " ▼") : "" })));
    }));
    const body = el("tbody", {}, list.slice(0, shown).map((r) =>
      el("tr", onRowClick ? { class: "clickable", tabindex: "0", onClick: () => onRowClick(r),
        onKeydown: (e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); onRowClick(r); } } } : {},
      columns.map((c) => el("td", { class: c.numeric ? "num" : "" }, c.render ? c.render(r) : (c.value(r) ?? "-"))))));
    mount(wrap, el("table", { class: "data" }, el("caption", { class: "sr-only", text: caption }), el("thead", {}, head), body));
    if (list.length > shown) {
      mount(more, el("button", { class: "btn", type: "button", onClick: () => { shown += pageSize; render(); } },
        `Show more (${list.length - shown} remaining)`));
    } else {
      mount(more, el("p", { class: "muted small", text: `${list.length} row${list.length === 1 ? "" : "s"}` }));
    }
  }
  return { el: root, setRows(r) { rows = r; shown = pageSize; render(); }, refresh(r) { rows = r; render(); } };
}

/** Labelled form field helper. */
export function field(label, input, hint) {
  const id = `f-${Math.random().toString(36).slice(2, 8)}`;
  input.id = id;
  return el("div", { class: "field" }, el("label", { for: id, text: label }), input, hint ? el("p", { class: "muted small", text: hint }) : null);
}
export function debounce(fn, ms = 200) { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; }
