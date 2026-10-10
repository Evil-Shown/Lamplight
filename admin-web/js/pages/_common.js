// Shared page plumbing: header, live indicator, watch-with-states.
import { el, mount, loadingState, errorState, fmtTime, debounce } from "../ui.js";
import { watch, restart, onUsersChanged } from "../store.js";

export function pageHeader(title, subtitle, ...actions) {
  return el("div", { class: "page-head" },
    el("div", {}, el("h2", { class: "page-h", text: title }), subtitle ? el("p", { class: "muted", text: subtitle }) : null),
    el("div", { class: "page-actions" }, actions));
}

/** Live/offline badge + "Last updated". update(snaps) after each snapshot. */
export function liveIndicator() {
  const dot = el("span", { class: "dot", "aria-hidden": "true" });
  const label = el("span", { class: "live-label", text: "Connecting…" });
  const updated = el("span", { class: "muted small", text: "" });
  const root = el("div", { class: "live", role: "status" }, dot, label, updated);
  function update(snaps) {
    const list = Object.values(snaps).filter(Boolean);
    const loaded = list.length && list.every((s) => s.loaded);
    const failed = list.some((s) => s.error);
    const cached = list.some((s) => s.fromCache) || !navigator.onLine;
    const state = failed ? "error" : !loaded ? "connecting" : cached ? "offline" : "live";
    root.dataset.state = state;
    label.textContent = { live: "Live", offline: "Offline - showing saved data", error: "Connection problem", connecting: "Connecting…" }[state];
    const t = list.map((s) => s.updatedAt).filter(Boolean).sort((a, b) => b - a)[0];
    updated.textContent = t ? `Last updated ${fmtTime(t)}` : "";
  }
  return { el: root, update };
}

/**
 * Watches sources, shows loading/error states in `target`, and calls
 * render(snaps) once everything has loaded without error. Returns cleanup.
 * `rerenderOnUsers` re-calls render when student names resolve.
 */
export function watchView(target, keys, render, { onSnap, rerenderOnUsers = false } = {}) {
  mount(target, loadingState());
  let last = null;
  const run = () => {
    if (!last) return;
    if (onSnap) onSnap(last);
    const vals = keys.map((k) => last[k]);
    const bad = vals.find((s) => s && s.error);
    if (bad) {
      mount(target, errorState(bad.error, () => keys.forEach(restart)));
      return;
    }
    if (vals.some((s) => !s || !s.loaded)) { return; }
    render(last, target);
  };
  const unsub = watch(keys, (snaps) => { last = snaps; run(); });
  const unUsers = rerenderOnUsers ? onUsersChanged(debounce(run, 150)) : () => {};
  return () => { unsub(); unUsers(); };
}

export function toolbar(...children) { return el("div", { class: "toolbar" }, children); }
export function selectBox(label, options, value, onChange) {
  const sel = el("select", {}, options.map(([v, t]) => el("option", { value: v, text: t })));
  sel.value = value;
  sel.addEventListener("change", () => onChange(sel.value));
  const id = `s-${Math.random().toString(36).slice(2, 8)}`;
  sel.id = id;
  return el("div", { class: "tool" }, el("label", { for: id, text: label }), sel);
}
export function searchBox(label, placeholder, onInput) {
  const input = el("input", { type: "search", placeholder, autocomplete: "off" });
  input.addEventListener("input", debounce(() => onInput(input.value), 150));
  const id = `q-${Math.random().toString(36).slice(2, 8)}`;
  input.id = id;
  return { el: el("div", { class: "tool tool-grow" }, el("label", { for: id, text: label }), input), input };
}
export function kv(pairs) {
  return el("dl", { class: "kv" }, pairs.filter(Boolean).flatMap(([k, v]) => [el("dt", { text: k }), el("dd", {}, v ?? "-")]));
}
