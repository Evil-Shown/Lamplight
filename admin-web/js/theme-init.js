// Classic script (CSP-friendly, no inline): applies the saved theme before first paint.
(function () {
  try {
    var t = localStorage.getItem("lamplight-admin-theme");
    if (t === "light" || t === "dark") document.documentElement.setAttribute("data-theme", t);
  } catch (e) { /* storage unavailable: follow the OS preference */ }
})();
