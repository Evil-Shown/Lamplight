// Books catalogue management. Writes mirror FirestoreService.addBook / editBook / setCopies.
// Reads are paged (orderBy title, limit 200, "Load more"); not live, so edits update the list locally.
import { el, mount, chip, dataTable, field, openOverlay, confirmDialog, toast, loadingState, errorState } from "../ui.js";
import { db, F } from "../firebase.js";
import { pageHeader, toolbar, searchBox } from "./_common.js";

const PAGE = 200;
const searchKey = (s) => String(s ?? "").trim().toLowerCase(); // same as lib/data/book_search.dart

export function validateBook(v) {
  const errors = {};
  const title = v.title.trim(), author = v.author.trim();
  if (!title) errors.title = "Title is required."; else if (title.length > 200) errors.title = "Keep the title under 200 characters.";
  if (!author) errors.author = "Author is required."; else if (author.length > 200) errors.author = "Keep the author under 200 characters.";
  if (v.isbn.trim() && !/^[0-9Xx-]{10,17}$/.test(v.isbn.trim())) errors.isbn = "ISBN should be 10-13 digits (hyphens allowed).";
  if (v.subject.trim().length > 100) errors.subject = "Keep the subject under 100 characters.";
  if (v.description.length > 2000) errors.description = "Keep the description under 2000 characters.";
  Object.assign(errors, validateCopies(v.copiesAvailable, v.copiesTotal));
  return errors;
}
export function validateCopies(avail, total) {
  const errors = {};
  const a = Number(avail);
  if (String(avail).trim() === "" || !Number.isInteger(a) || a < 0 || a > 9999) errors.copiesAvailable = "Enter a whole number from 0 to 9999.";
  if (String(total).trim() !== "") {
    const t = Number(total);
    if (!Number.isInteger(t) || t < 0 || t > 9999) errors.copiesTotal = "Enter a whole number from 0 to 9999.";
    else if (!errors.copiesAvailable && t < a) errors.copiesTotal = "Total can't be less than the copies available.";
  }
  return errors;
}
const availabilityFor = (n) => (n > 0 ? "available" : "onLoan"); // as setCopies

function fromDoc(d) { return { id: d.id, ...d.data() }; }

export function render({ container }) {
  let books = [];           // loaded browse pages
  let cursor = null, more = false, loading = false, query = "", searchResults = null, alive = true;
  const body = el("div", {});
  const table = dataTable({
    caption: "Books", pageSize: 100, defaultSort: { key: "title", dir: "asc" }, emptyTitle: "No books found", emptyHint: "Try a different search, or add a book.",
    columns: [
      { key: "title", label: "Title", value: (b) => (b.title || "").toLowerCase(), render: (b) => b.title || "-" },
      { key: "author", label: "Author", value: (b) => (b.author || "").toLowerCase(), render: (b) => b.author || "-" },
      { key: "subject", label: "Subject", value: (b) => (b.subject || "").toLowerCase(), render: (b) => b.subject || "-" },
      { key: "shelf", label: "Shelf", value: (b) => (b.shelfLocation || "").toLowerCase(), render: (b) => b.shelfLocation || "-" },
      { key: "copies", label: "Copies", numeric: true, value: (b) => b.copiesAvailable ?? 0,
        render: (b) => `${b.copiesAvailable ?? 0}${b.copiesTotal != null ? ` / ${b.copiesTotal}` : ""}` },
      { key: "avail", label: "Status", value: (b) => b.availability || "", render: (b) => chip(b.availability || "available") },
      { key: "act", label: "Actions", value: () => null, render: (b) => el("div", { class: "row-actions" },
        el("button", { class: "btn btn-sm", type: "button", onClick: () => editDialog(b) }, "Edit"),
        el("button", { class: "btn btn-sm", type: "button", onClick: () => copiesDialog(b) }, "Copies")) },
    ],
  });
  const loadMoreBtn = el("button", { class: "btn", type: "button", onClick: () => loadPage() }, "Load more books");
  const footer = el("div", { class: "table-more" });

  function visible() {
    if (query.trim() && searchResults) return searchResults;
    return books;
  }
  function draw() {
    table.refresh(visible());
    mount(footer, !searchResults && more ? loadMoreBtn : el("p", { class: "muted small", text: searchResults ? "Search matches titles/authors starting with your text, plus loaded books containing it." : "All books loaded." }));
  }
  function applyLocal(id, patch) {
    for (const list of [books, searchResults || []]) { const i = list.findIndex((x) => x.id === id); if (i >= 0) list[i] = { ...list[i], ...patch }; }
    draw();
  }

  async function loadPage() {
    if (loading) return;
    loading = true; loadMoreBtn.disabled = true;
    try {
      const q = cursor
        ? F.query(F.collection(db, "books"), F.orderBy("title"), F.startAfter(cursor), F.limit(PAGE))
        : F.query(F.collection(db, "books"), F.orderBy("title"), F.limit(PAGE));
      const snap = await F.getDocs(q);
      books = books.concat(snap.docs.map(fromDoc));
      cursor = snap.docs[snap.docs.length - 1] || cursor;
      more = snap.docs.length === PAGE;
      if (alive) { mount(body, el("section", { class: "card" }, table.el, footer)); draw(); }
    } catch (e) {
      if (alive && !books.length) mount(body, errorState(e, () => { mount(body, loadingState()); loadPage(); }));
      else toast("Couldn't load more books.", "error");
    }
    loading = false; loadMoreBtn.disabled = false;
  }

  async function runSearch(text) {
    query = text;
    const k = searchKey(text);
    if (!k) { searchResults = null; draw(); return; }
    const local = books.filter((b) => `${b.title} ${b.author} ${b.isbn}`.toLowerCase().includes(k));
    searchResults = local; draw();
    try {
      const end = k + "";
      const [t, a] = await Promise.all(["titleLower", "authorLower"].map((f) =>
        F.getDocs(F.query(F.collection(db, "books"), F.orderBy(f), F.startAt(k), F.endAt(end), F.limit(PAGE)))));
      if (searchKey(query) !== k || !alive) return; // stale
      const merged = new Map(local.map((b) => [b.id, b]));
      for (const d of [...t.docs, ...a.docs]) if (!merged.has(d.id)) merged.set(d.id, fromDoc(d));
      searchResults = [...merged.values()]; draw();
    } catch (e) { toast("Server search failed; showing loaded books only.", "error"); }
  }

  // ------------------------------------------------------------ dialogs
  function bookForm(initial) {
    const mk = (type, val, attrs) => el(type === "textarea" ? "textarea" : "input", { ...(type === "textarea" ? { rows: 3 } : { type }), ...attrs });
    const inputs = {
      title: mk("text", "", { maxlength: 200, required: true, autofocus: true }), author: mk("text", "", { maxlength: 200, required: true }),
      subject: mk("text", "", { maxlength: 100 }), isbn: mk("text", "", { maxlength: 17, inputmode: "numeric" }),
      shelfLocation: mk("text", "", { maxlength: 100 }), copiesAvailable: mk("number", "", { min: 0, max: 9999, step: 1, inputmode: "numeric" }),
      copiesTotal: mk("number", "", { min: 0, max: 9999, step: 1, inputmode: "numeric" }), description: mk("textarea", "", { maxlength: 2000 }),
    };
    for (const k of Object.keys(inputs)) inputs[k].value = initial[k] ?? "";
    const errEls = {};
    const wrap = (k, label, hint) => {
      const f = field(label, inputs[k], hint);
      errEls[k] = el("p", { class: "field-error", role: "alert" }); f.append(errEls[k]); return f;
    };
    const node = el("form", { novalidate: true, class: "form-grid" },
      wrap("title", "Title"), wrap("author", "Author"), wrap("subject", "Subject"), wrap("isbn", "ISBN (optional)"), wrap("shelfLocation", "Shelf location"),
      wrap("copiesAvailable", "Copies available"), wrap("copiesTotal", "Total copies (optional)"), wrap("description", "Description"));
    const read = () => Object.fromEntries(Object.entries(inputs).map(([k, i]) => [k, i.value]));
    const show = (errors) => { for (const k of Object.keys(inputs)) { errEls[k].textContent = errors[k] || ""; inputs[k].setAttribute("aria-invalid", errors[k] ? "true" : "false"); } };
    return { node, read, show, inputs };
  }
  function editDialog(b) {
    const isNew = !b;
    const ov = openOverlay({ title: isNew ? "Add book" : `Edit "${b.title}"`, wide: true });
    const f = bookForm(isNew ? { copiesAvailable: 1 } : b);
    ov.body.append(f.node);
    const save = el("button", { class: "btn btn-primary", type: "button", text: isNew ? "Add book" : "Save changes" });
    ov.footer.append(el("button", { class: "btn", type: "button", onClick: () => ov.close() }, "Cancel"), save);
    const submit = async () => {
      const v = f.read(); const errors = validateBook(v); f.show(errors);
      const first = Object.keys(errors)[0];
      if (first) { f.inputs[first].focus(); return; }
      const avail = Number(v.copiesAvailable);
      const data = {
        title: v.title.trim(), author: v.author.trim(), titleLower: searchKey(v.title), authorLower: searchKey(v.author),
        subject: v.subject.trim(), isbn: v.isbn.trim(), shelfLocation: v.shelfLocation.trim(), description: v.description.trim(),
        copiesAvailable: avail, availability: availabilityFor(avail),
        ...(String(v.copiesTotal).trim() !== "" ? { copiesTotal: Number(v.copiesTotal) } : {}),
      };
      save.disabled = true;
      try {
        if (isNew) {
          const ref = F.doc(F.collection(db, "books"));
          await F.setDoc(ref, { ...data, dueDate: null, coverColor: null, createdAt: F.serverTimestamp() });
          books.unshift({ id: ref.id, ...data }); toast("Book added", "success");
          if (alive) { mount(body, el("section", { class: "card" }, table.el, footer)); draw(); }
        } else {
          await F.setDoc(F.doc(db, "books", b.id), data, { merge: true });
          applyLocal(b.id, data); toast("Book saved", "success");
        }
        ov.close();
      } catch (e) {
        save.disabled = false;
        toast(e?.code === "permission-denied" ? "Your role isn't allowed to change books." : "Couldn't save. Try again.", "error");
      }
    };
    save.addEventListener("click", submit);
    f.node.addEventListener("submit", (e) => { e.preventDefault(); submit(); });
  }
  function copiesDialog(b) {
    const ov = openOverlay({ title: `Copies of "${b.title}"` });
    const avail = el("input", { type: "number", min: 0, max: 9999, step: 1, inputmode: "numeric", autofocus: true, value: b.copiesAvailable ?? 0 });
    const total = el("input", { type: "number", min: 0, max: 9999, step: 1, inputmode: "numeric", value: b.copiesTotal ?? "" });
    const e1 = el("p", { class: "field-error", role: "alert" }), e2 = el("p", { class: "field-error", role: "alert" });
    ov.body.append(field("Copies available", avail), e1, field("Total copies (optional)", total), e2,
      el("p", { class: "muted small", text: "Reservations and returns adjust these automatically; only correct them if the shelf count is wrong." }));
    const save = el("button", { class: "btn btn-primary", type: "button" }, "Update copies");
    ov.footer.append(el("button", { class: "btn", type: "button", onClick: () => ov.close() }, "Cancel"), save);
    save.addEventListener("click", async () => {
      const errors = validateCopies(avail.value, total.value);
      e1.textContent = errors.copiesAvailable || ""; e2.textContent = errors.copiesTotal || "";
      if (Object.keys(errors).length) return;
      const n = Number(avail.value);
      if (n === 0 || n < (b.copiesAvailable ?? 0)) {
        const ok = await confirmDialog({ title: "Lower the available copies?", danger: true, confirmLabel: "Update copies",
          message: n === 0 ? `"${b.title}" will show as on loan and students can only join its waiting list.` : `Available copies of "${b.title}" go from ${b.copiesAvailable ?? 0} down to ${n}.` });
        if (!ok) return;
      }
      const patch = { copiesAvailable: n, availability: availabilityFor(n), ...(String(total.value).trim() !== "" ? { copiesTotal: Number(total.value) } : {}) };
      save.disabled = true;
      try { await F.updateDoc(F.doc(db, "books", b.id), patch); applyLocal(b.id, patch); toast("Copies updated", "success"); ov.close(); }
      catch (e) { save.disabled = false; toast(e?.code === "permission-denied" ? "Your role isn't allowed to change books." : "Couldn't update copies. Try again.", "error"); }
    });
  }

  const search = searchBox("Search", "Title, author or ISBN", runSearch);
  const add = el("button", { class: "btn btn-primary", type: "button", onClick: () => editDialog(null) }, "Add book");
  mount(container, pageHeader("Books", "Catalogue and copy counts.", add), toolbar(search.el), body);
  mount(body, loadingState("Loading books…"));
  loadPage();
  return () => { alive = false; };
}
