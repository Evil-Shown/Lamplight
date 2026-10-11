// Login page (shown to signed-out visitors only).
import { el, mount, field } from "../ui.js";
import { signInEmail, signInGoogle, resetPassword, resendVerification, recheckVerification, signOutNow, friendlyAuthError } from "../auth.js";

export function renderLogin(root, st) {
  const msg = el("p", { class: "form-msg", role: "alert" });
  const info = el("p", { class: "form-msg form-ok", role: "status" });
  const setMsg = (t) => { msg.textContent = t || ""; };
  const setInfo = (t) => { info.textContent = t || ""; };
  if (st.notice) setMsg(st.notice.text);

  const card = el("main", { class: "login-card", id: "main" });
  const brand = el("div", { class: "login-brand" }, el("img", { src: "favicon.png", alt: "", width: "48", height: "48" }),
    el("h1", { text: "Lamplight Staff" }), el("p", { class: "muted", text: "Library administration dashboard" }));
  root.className = "login-page";

  if (st.status === "unverified") {
    const email = st.user.email || "your email address";
    const resend = el("button", { class: "btn btn-primary", type: "button" }, "Resend verification email");
    resend.addEventListener("click", async () => {
      resend.disabled = true; setMsg(""); setInfo("");
      try { await resendVerification(); setInfo("Verification email sent. Check your inbox (and spam)."); }
      catch (e) { setMsg(e && e.code === "auth/too-many-requests" ? friendlyAuthError(e) : "Couldn't send the email. Try again shortly."); }
      resend.disabled = false;
    });
    const recheck = el("button", { class: "btn", type: "button" }, "I've verified, continue");
    recheck.addEventListener("click", async () => {
      setMsg(""); try { await recheckVerification(); if (!st.user.emailVerified) setMsg("Still not verified. Open the link in the email first."); }
      catch { setMsg("Couldn't re-check right now. Try again."); }
    });
    mount(root, card);
    mount(card, brand, el("h2", { text: "Verify your email" }),
      el("p", { text: `${email} hasn't been verified yet. Staff access needs a verified email. Open the link we sent you, or request a new one.` }),
      msg, info, el("div", { class: "row" }, resend, recheck),
      el("p", {}, el("button", { class: "link-btn", type: "button", onClick: () => signOutNow() }, "Use a different account")));
    return;
  }

  if (st.status === "checking") {
    mount(root, card);
    mount(card, brand, el("div", { class: "state", role: "status" }, el("div", { class: "spinner", "aria-hidden": "true" }), el("p", { text: "Checking your access…" })));
    return;
  }

  const email = el("input", { type: "email", autocomplete: "username", required: true, inputmode: "email", autofocus: true });
  const pw = el("input", { type: "password", autocomplete: "current-password", required: true });
  const submit = el("button", { class: "btn btn-primary btn-block", type: "submit" }, "Sign in");
  const google = el("button", { class: "btn btn-block", type: "button" }, "Continue with Google");
  const forgot = el("button", { class: "link-btn", type: "button" }, "Forgot password?");

  const busy = (b) => { submit.disabled = b; google.disabled = b; };
  const form = el("form", { novalidate: true }, field("Email", email), field("Password", pw), msg, info, submit);
  form.addEventListener("submit", async (e) => {
    e.preventDefault(); setMsg(""); setInfo("");
    if (!email.value.trim() || !pw.value) { setMsg("Enter your email and password."); return; }
    busy(true);
    try { await signInEmail(email.value, pw.value); }
    catch (err) { setMsg(friendlyAuthError(err)); busy(false); }
  });
  google.addEventListener("click", async () => {
    setMsg(""); setInfo(""); busy(true);
    try { await signInGoogle(); }
    catch (err) { const m = friendlyAuthError(err); if (err?.code !== "auth/popup-closed-by-user" && err?.code !== "auth/cancelled-popup-request") setMsg(m); busy(false); }
  });
  forgot.addEventListener("click", async () => {
    setMsg(""); setInfo("");
    if (!email.value.trim()) { setMsg("Type your email above first, then choose Forgot password."); email.focus(); return; }
    try { await resetPassword(email.value); } catch (err) {
      if (err && (err.code === "auth/network-request-failed" || err.code === "auth/too-many-requests")) { setMsg(friendlyAuthError(err)); return; }
    }
    // Neutral message either way: never reveal whether an account exists.
    setInfo("If an account exists for that email, a password reset link is on its way.");
  });

  mount(root, card);
  mount(card, brand, form, el("div", { class: "divider" }, el("span", { text: "or" })), google,
    el("p", { class: "center" }, forgot),
    el("p", { class: "muted small center", text: "Access is limited to library staff and administrators." }));
}
