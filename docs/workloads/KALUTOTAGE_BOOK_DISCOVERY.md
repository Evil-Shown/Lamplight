# Kalutotage (S Y) — Book discovery & reservation workload

**Owner:** Kalutotage S Y
**Reg. No:** IT23612228
**Module:** IT3060 HCI · Milestone 02 §3.2 + Milestone 03 implementation
**Scope:** **Book search → results → details → reservation success** — **frontend and backend**.

This file is Kalutotage's working spec. Do **not** paste it unchanged into the 35-page PDF (AI similarity must stay below 50%). Rewrite in your own words for the report; use this for coding, viva, CRUD evidence, and deviation notes.

Related: M02 extract §3.2, FR01–FR05 + FR07, `docs/UI_DESIGN.md`, `docs/FRONTEND_DESIGN.md`, `docs/BACKEND_DESIGN.md`, `docs/DATA_MODEL.md`, `docs/REPORT_AND_VIVA.md`.

---

## 1. Milestone 02 §3.2 — design alternatives (completed)

Compare at least three catalogue layouts before Figma; record the decision like the seat-booking table.

| Variant | Strength | Weakness | Decision |
|---------|----------|----------|----------|
| **A. Flat A–Z list** | No typing needed | Useless past ~50 books | **Rejected** |
| **B. Search-first with type tabs** | Direct (title / author / ISBN / category) | Empty state needs recent suggestions | **Selected** |
| **C. Category browse grid** | Visual discovery | Slow for known-item lookup (most students arrive with a title/ISBN) | **Kept as secondary** |

**Final design (B + C):** a **search-first catalog** with **search-type tabs**, live results under the field (no separate "press search" step), **availability visible on every card**, and the full record on a **detail page** with cover, copies, shelf, and one primary action (Reserve / Join waitlist). Availability is **never colour-only** — text pill + copy count (NFR06).

Downstream screens that belong to this same flow (Kalutotage):

| Figma | App file | Intent |
|-------|----------|--------|
| Book Search v2 "Library Catalog" | `lib/features/books/book_search_screen.dart` | Search field, type tabs, live results, barcode banner |
| Search Results | `lib/features/books/search_results_screen.dart` | Full result list for a query |
| Book Details | `lib/features/books/book_detail_screen.dart` | Record, availability, cover, reserve / waitlist |
| Reservation Success | `lib/features/books/reservation_confirmation_screen.dart` | Confirmation + pickup deadline (FR07, FR17) |

Book Search is the Catalog tab; Results/Details are pushed on top. My Reservations (Pathiranage) **consumes** the `BookReservation` documents this flow creates.

---

## 2. Requirements Kalutotage must satisfy

| ID | Requirement | Kalutotage's screens |
|----|-------------|----------------------|
| FR01 | Search for library books | Book Search |
| FR02 | Search by title, ISBN, author, subject | Book Search, Results |
| FR03 | Display current book availability | Results, Book Details |
| FR04 | Display book information before reserving | Book Details |
| FR05 | Reserve an available book | Details / result card → Reserve |
| FR07 | Confirmation after a book reservation | Reservation Success |
| NFR01 / NFR03 / NFR06 | Clear UI, accurate availability, text+colour status | All of the above |

Usability tasks from M02 (run on the **APK**): find a book by ISBN, judge availability from the card alone, reserve and read back the pickup deadline.

**CRUD (minimum two working ops — Kalutotage should ship all four):**

| Op | User action | Frontend | Backend |
|----|-------------|----------|---------|
| **C** Create | Reserve a book / join book waitlist | Details, Results card | `FirestoreService.addReservation` (`AppState.reserveBook`) |
| **R** Read | Search, browse, availability, my holds | Search, Results, Details | `FirestoreService.booksStream()` (live `books` collection) |
| **U** Update | Change query / tabs; copy count after pickup | Search field, tabs | copy-count transaction (see §4.2) |
| **D** Delete | Cancel a hold | Handled in My Reservations (Pathiranage) — coordinate so `cancelReservation` also restores copies |

---

## 3. Frontend — how it should look and behave

Campus-blue design (`AppColors`, Inter, 16px margins, 48dp targets). Motion (stagger, press scale) stays light.

### 3.1 Book Search (Catalog tab)

**Layout (top → bottom):**

1. Header with live-status pill — reuse the **Live / Offline** freshness pattern from the seat map (`AppState.lastSyncedAt`).
2. Search field with leading icon; typing filters **live** — results appear below without a submit button.
3. Search-type tabs: Title / Author / ISBN / Category. Default **Title** tab also matches author+subject (forgiving search); other tabs are strict to their field.
4. Result cards: cover swatch, title, author, **availability pill + copies**, shelf code, and a Reserve action on available rows.
5. Barcode banner: either wire it to a real ISBN scan (`mobile_scanner` is already a dependency — scanning fills the ISBN tab) or **remove it**. A decorative scanner is a viva liability.

### 3.2 Results

Full-page list for the current query with the same card, plus an empty state: "No books match '<q>'" + suggestions (check spelling / try another tab). Results screen and inline results must use the **same matching function** — extract one `BookSearch.query(books, q, type)` helper so they can never diverge.

### 3.3 Book Details

Hero with cover colour, title, author, subject/ISBN. Availability callout: copies + shelf for available; waitlist invitation when 0 copies. Amenity-free but must show **due date when on loan** (`Book.dueDate`, already modelled). Primary action:

- Available → **Reserve book** → `ReservationConfirmationScreen` (FR05 → FR07).
- 0 copies → **Join waitlist** — currently only a snackbar. Route through the **waitlist joined screen** (`WaitlistJoinedScreen`) so the user sees their **position** (FR13 parity with seats), and pass `type: WaitlistType.book`.

### 3.4 Reservation Success

Confirms the hold: book, reservation id, **pickup-by deadline (7 days)**, pickup location. Actions: view pass / Done → My Reservations. The reservation must already be in Firestore when this screen shows (`AppState.reserveBook` writes through).

### 3.5 Frontend architecture (Kalutotage's feature)

```text
lib/features/books/
  presentation/   book_search, search_results, book_detail, confirmation
  application/    book_search_controller, recommendation-free (search only)
  domain/         Book, BookReservation, BookSearch (pure query fn)
```

Widgets never touch `FirebaseFirestore.instance` — reads come from `AppState.books` (populated by `FirestoreService.booksStream()`), writes go through `AppState` methods. Keep mock `MockData.books` as the offline/test fixture.

---

## 4. Backend — Firebase for Kalutotage's domain

### 4.1 Collections (Kalutotage-owned data)

**`/books/{bookId}`** — title, author, subject, isbn, availability (`available|onLoan|waitlisted`), `shelfLocation`, `copiesAvailable`, description, `coverColor`, `dueDate` (Timestamp) — seeded from `MockData.books` on first run (`FirestoreService.seedIfEmpty`).

**`users/{uid}/reservations/{id}`** — bookId, reservedAt, pickupBy, pickupLocation, qrCode, status. Written by **Reserve**, read by My Reservations, consumed by staff book-handover verification (`FirestoreService.verifyCode` already queries this collection group).

### 4.2 APIs Kalutotage implements / owns

| Function | Auth | Behaviour |
|----------|------|-----------|
| `reserveBook(book)` (exists) | Student | Optimistic insert + Firestore write; notification doc; returns reservation |
| `reserveBookUnique(book)` (to add) | Student | **Transaction**: reject if an active reservation for the same bookId already exists (duplicate guard), decrement `copiesAvailable`, flip availability at 0 |
| `restoreCopyOnCancel` (coordinate with Pathiranage) | Owner/staff | Cancel increments `copiesAvailable` back |
| `seedIfEmpty` (exists) | — | Seeds the catalogue once |

### 4.3 Transaction sketch (reserve with copy decrement)

1. Read `books/{id}` — must have `copiesAvailable > 0`.
2. Query user's reservations — no active one for this `bookId` (else return existing id).
3. Write reservation `ready` with `pickupBy = now + 7d`; decrement copies; availability → `waitlisted` at 0.
4. Confirmation notification doc (FR07/FR17).

### 4.4 Security rules (books)

Already deployed in `firestore.rules`: signed-in users read `books/{**}`; writes allowed signed-in for seeding (tighten to staff claim in production). Personal reservations are owner-only writes; staff can read for QR verification.

### 4.5 Indexes / queries

- `books` by `availability` (catalog filters later).
- Reservations collection-group by `qrCode` (exists — staff verification).
- Reserve-duplicate guard: query `users/{uid}/reservations` where `status != cancelled` and match `bookId` client-side (single user — no composite index needed).

---

## 5. End-to-end flows (Kalutotage)

**Happy path (T-discovery)**  Catalog tab → type "cle" under Title → live result *Clean Code* (pill: Available · 3 copies) → Details shows shelf B2-14 → Reserve → Success with pickup-by date → hold visible in My Reservations → Books.

**Waitlist path**  Open *Code Complete* (0 copies) → Join waitlist → joined screen with **#position** → when a copy is returned (cancel/return flow), notification arrives (FR14, owned jointly).

**Duplicate path**  Reserve the same book twice → second attempt blocked with "You already hold a reservation for this title."

---

## 6. Fidelity vs Figma (report table — fill as you go)

| Item | Figma | Implementation | OK / deviation |
|------|-------|----------------|----------------|
| Search-first catalog + type tabs | Book Search v2 | Required | Must match |
| Live results under field | Required | Required | Must match |
| Availability pill + copies on cards | Required | Required | Must match |
| Detail with copies/shelf/description | Required | Required | Must match |
| Success screen | P-Book Success | Required | Must match |
| Barcode scanner banner | In mockup | **Deviation** — implement real ISBN scan or cut (justify) |
| Client-side search vs Algolia | Prototype fake | Firestore + client query | Justify: 16-book corpus; note Algolia path for scale |

---

## 7. Tests Kalutotage owns

**Functional (trace to FR):**

| ID | Case | Expect |
|----|------|--------|
| BT-01 | Open catalog | Header + live pill + field + default results (FR01) |
| BT-02 | Type "cle" (Title) | Clean Code surfaces live (FR02) |
| BT-03 | ISBN tab with 9780132350884 | Exactly Clean Code (FR02) |
| BT-04 | Available card | Pill + copies visible, not colour-only (FR03) |
| BT-05 | Open details | Cover, copies, shelf, description, due date if on loan (FR04) |
| BT-06 | Reserve available | Success + reservation doc in Firestore (FR05, FR07) |
| BT-07 | Reserve duplicate | Blocked with message (guard) |
| BT-08 | 0-copy book | Join waitlist → position screen (FR13 parity) |
| BT-09 | No-match query | Friendly empty state, no crash |

Widget tests: search field filters live; type tabs change matches; detail available vs 0-copy actions; confirmation shows pickup deadline. Reuse `MockData.books` as the fixture.

---

## 8. Implementation order (Kalutotage)

1. Extract shared `BookSearch.query`; wire Results screen to it.
2. Reserve-duplicate guard + copy-count transaction (§4.3).
3. Book waitlist parity: `WaitlistType.book` + joined screen with position.
4. Barcode banner → real ISBN scan (or cut).
5. Live/Offline pill on catalog header; empty states.
6. Widget tests + screenshots for the report; APK run-through BT-01…09.

---

## 9. Viva (Kalutotage)

Be able to:

1. Search by ISBN and explain the four type tabs and forgiving default.
2. Reserve a book and show the Firestore reservation document + pickup deadline.
3. Explain the duplicate guard and copy decrement (or honestly show it as backlog).
4. Name **FR01–FR05 + FR07** and two CRUD ops you implemented.
5. Name one Figma deviation (barcode scanner / client-side search) and why.

Do not read this file aloud. Explain from the running app.
