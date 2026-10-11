// Verify a QR pass / short code via callable verifyQrPass({code, consume}).
// The callable supports consume:false (peek), so by default we only look; staff
// opt in to "Verify and check in / hand over" which consumes the pass.
import { el, mount, field, fmtDateTime, toast, confirmDialog } from "../ui.js";
import { call } from "../firebase.js";
import { pageHeader, kv } from "./_common.js";

export const OUTCOMES = {
  valid: { tone: "ok", title: "Valid", text: "The pass is valid." },
  alreadyUsed: { tone: "warn", title: "Already used", text: "This pass has already been used." },
  tooEarly: { tone: "warn", title: "Too early", text: "The booking hasn't opened for check-in yet." },
  expired: { tone: "bad", title: "Expired", text: "This pass has expired (or the booking was a no-show)." },
  cancelled: { tone: "bad", title: "Cancelled", text: "This booking or reservation was cancelled." },
  invalid: { tone: "bad", title: "Invalid", text: "The pass is missing required details." },
  malformed: { tone: "bad", title: "Invalid code", text: "That doesn't look like a Lamplight pass, or its signature didn't match." },
  ambiguous: { tone: "warn", title: "Ambiguous", text: "More than one booking uses that short code. Scan the full QR code instead." },
  notFound: { tone: "bad", title: "Not found", text: "No reservation or booking matches that code." },
};

export function verifyErrorMessage(err) {
  const code = String(err?.code || "");
  if (code.endsWith("permission-denied")) return "Your role isn't allowed to verify passes.";
  if (code.endsWith("not-found") || code.endsWith("unimplemented")) return "This needs the latest server update.";
  if (code.endsWith("unavailable") || code.endsWith("deadline-exceeded")) return "Network problem. Try again.";
  return "Verification failed. Try again.";
}

function outcomeCard(r, consumed) {
  const o = OUTCOMES[r.result] || { tone: "bad", title: "Unknown result", text: `Unexpected result: ${String(r.result)}` };
  const details = r.docPath ? kv([
    ["Type", r.kind === "seat" ? "Seat booking" : "Book reservation"],
    ["Student", `${r.ownerName || "Student"}${r.ownerStudentId ? ` (${r.ownerStudentId})` : ""}`],
    r.kind === "seat" ? ["Seat", r.seatId || "-"] : ["Book", r.bookTitle || r.bookId || "-"],
    r.kind === "seat" ? ["Window", `${fmtDateTime(r.startTime)} - ${fmtDateTime(r.endTime)}`] : ["Pickup by", fmtDateTime(r.pickupBy)],
    ["Current status", r.status || "-"],
  ]) : null;
  return el("section", { class: `outcome outcome-${o.tone}`, role: "status", "aria-live": "polite" },
    el("h3", { text: o.title }), el("p", { text: o.text }),
    r.consumed ? el("p", { class: "strong", text: r.kind === "seat" ? "Checked in. The booking is now active." : "Marked as collected." })
      : (r.result === "valid" && !consumed ? el("p", { class: "muted", text: "Nothing has been changed yet. Use \"Verify and use\" to check the student in or hand over the book." }) : null),
    details);
}

export function render({ container }) {
  const input = el("input", { type: "text", autocomplete: "off", spellcheck: "false", maxlength: 400, autofocus: true, placeholder: "Paste the QR text or type the short code" });
  const result = el("div", { class: "verify-result" });
  const peekBtn = el("button", { class: "btn btn-primary", type: "submit" }, "Check pass");
  const useBtn = el("button", { class: "btn", type: "button" }, "Verify and use");
  let lastCode = "";

  async function run(consume) {
    const code = input.value.trim();
    if (code.length < 3) { mount(result, el("p", { class: "form-msg", role: "alert", text: "Enter at least 3 characters." })); return; }
    if (consume) {
      const ok = await confirmDialog({ title: "Use this pass?", confirmLabel: "Verify and use",
        message: "This consumes the pass: a seat booking is checked in, or a book reservation is marked collected. It can't be undone here." });
      if (!ok) return;
    }
    peekBtn.disabled = useBtn.disabled = true; lastCode = code;
    mount(result, el("p", { class: "muted", role: "status", text: "Checking…" }));
    try {
      const r = await call("verifyQrPass", { code, consume });
      mount(result, outcomeCard(r || {}, consume));
      if (r?.consumed) toast("Pass used", "success");
    } catch (e) { mount(result, el("p", { class: "form-msg", role: "alert", text: verifyErrorMessage(e) })); }
    peekBtn.disabled = useBtn.disabled = false;
  }
  const form = el("form", { novalidate: true }, field("Pass code", input, "Staff-typed short codes are accepted as a fallback; full QR text is more reliable."),
    el("div", { class: "row" }, peekBtn, useBtn));
  form.addEventListener("submit", (e) => { e.preventDefault(); run(false); });
  useBtn.addEventListener("click", () => run(true));
  input.addEventListener("input", () => { if (input.value.trim() !== lastCode) mount(result); });
  mount(container, pageHeader("Verify pass", "Check a student's QR pass without changing anything, then use it when ready."),
    el("section", { class: "card narrow" }, form, result));
  return () => {};
}
