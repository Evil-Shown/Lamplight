// Staff allow-list (ADMIN ONLY). Callables: listStaff() and setStaffAllowlist({emails}).
import { el, mount, field, dataTable, confirmDialog, toast, loadingState, errorState } from "../ui.js";
import { call } from "../firebase.js";
import { pageHeader } from "./_common.js";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/; // same as the server (functions/src/staffAdmin.ts)
export const normalizeEmail = (s) => String(s).trim().toLowerCase();
export function validateStaffEmail(raw, existing) {
  const e = normalizeEmail(raw);
  if (!e) return "Enter an email address.";
  if (e.length > 200 || !EMAIL_RE.test(e)) return "That doesn't look like a valid email address.";
  if (existing.includes(e)) return "That email is already on the list.";
  if (existing.length >= 200) return "The list is full (200 emails maximum).";
  return "";
}
function callError(e) {
  const code = String(e?.code || "");
  if (code.endsWith("permission-denied")) return "Only administrators can change the staff list.";
  if (code.endsWith("invalid-argument")) return e.message || "The server rejected that email list.";
  if (code.endsWith("not-found") || code.endsWith("unimplemented")) return "This needs the latest server update.";
  if (code.endsWith("unavailable")) return "Network problem. Try again.";
  return "Couldn't save the staff list. Try again.";
}

export function render({ container, role }) {
  if (role !== "admin") {
    mount(container, el("div", { class: "state state-error", role: "alert" }, el("h2", { text: "Administrators only" })));
    return;
  }
  let staff = [];
  let alive = true;
  const body = el("div", {});
  const input = el("input", { type: "email", autocomplete: "off", inputmode: "email", maxlength: 200, placeholder: "name@university.edu" });
  const err = el("p", { class: "field-error", role: "alert" });
  const addBtn = el("button", { class: "btn btn-primary", type: "submit" }, "Add");
  const table = dataTable({
    caption: "Library staff allow-list", defaultSort: { key: "email", dir: "asc" }, emptyTitle: "No staff added yet", emptyHint: "Add an email above to grant library staff access.",
    columns: [
      { key: "email", label: "Email", value: (s) => s.email, render: (s) => s.email },
      { key: "name", label: "Name", value: (s) => (s.displayName || "").toLowerCase(), render: (s) => s.displayName || "-" },
      { key: "acct", label: "Account", value: (s) => (s.hasAccount ? 1 : 0), render: (s) => s.hasAccount ? "Has signed up" : "Not signed up yet" },
      { key: "act", label: "", value: () => null, render: (s) => {
        const b = el("button", { class: "btn btn-sm btn-danger-outline", type: "button", "aria-label": `Remove ${s.email}` }, "Remove");
        b.addEventListener("click", () => remove(s, b));
        return b;
      } },
    ],
  });

  async function save(emails) {
    const res = await call("setStaffAllowlist", { emails });
    const saved = Array.isArray(res?.emails) ? res.emails : emails;
    const prev = new Map(staff.map((s) => [s.email, s]));
    staff = saved.map((e) => prev.get(e) || { email: e, hasAccount: false, uid: null, displayName: null });
    table.refresh(staff);
    return res;
  }
  async function remove(s, btn) {
    const ok = await confirmDialog({ title: "Remove staff access?", danger: true, confirmLabel: "Remove",
      message: `${s.email} will lose staff access. They are signed out of the dashboard once their session refreshes.` });
    if (!ok) return;
    btn.disabled = true;
    try { await save(staff.map((x) => x.email).filter((e) => e !== s.email)); toast("Staff member removed", "success"); }
    catch (e) { btn.disabled = false; toast(callError(e), "error"); }
  }
  const form = el("form", { novalidate: true, class: "inline-form" }, field("Add staff email", input), addBtn);
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const msg = validateStaffEmail(input.value, staff.map((s) => s.email));
    err.textContent = msg;
    if (msg) { input.focus(); return; }
    addBtn.disabled = true;
    try { await save([...staff.map((s) => s.email), normalizeEmail(input.value)]); input.value = ""; toast("Staff member added", "success"); }
    catch (e2) { toast(callError(e2), "error"); }
    addBtn.disabled = false;
  });

  async function load() {
    mount(body, loadingState());
    try {
      const res = await call("listStaff");
      if (!alive) return;
      staff = Array.isArray(res?.staff) ? res.staff : [];
      table.setRows(staff);
      mount(body, el("section", { class: "card" }, form, err, el("p", { class: "muted small", text: "Access is granted the next time that person signs in with a verified email." })),
        el("section", { class: "card" }, table.el));
    } catch (e) { if (alive) mount(body, errorState({ message: callError(e) }, load)); }
  }
  mount(container, pageHeader("Staff", "Who can use this dashboard (administrators only)."), body);
  load();
  return () => { alive = false; };
}
