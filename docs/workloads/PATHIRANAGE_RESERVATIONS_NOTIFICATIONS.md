# Pathiranage (S.S.) — My Reservations, cancellation & notifications workload

**Owner:** Pathiranage S.S.
**Reg. No:** IT23607446
**Module:** IT3060 HCI · Milestone 02 §3.3 + Milestone 03 implementation
**Scope:** **My Reservations (books / seats / waiting tabs), reservation details, cancel flow, notifications feed** — **frontend and backend**.

This file is Pathiranage's working spec. Do **not** paste it unchanged into the 35-page PDF (AI similarity must stay below 50%). Rewrite in your own words for the report; use this for coding, viva, CRUD evidence, and deviation notes.

Related: M02 extract §3.3, FR06 + FR15 + FR16 + FR17, `docs/UI_DESIGN.md`, `docs/FRONTEND_DESIGN.md`, `docs/BACKEND_DESIGN.md`, `docs/DATA_MODEL.md`, `docs/REPORT_AND_VIVA.md`.

> Reg-no note: M02's cover tables swap Wathudura/Pathiranage reg numbers in one place — confirm **IT23607446 = Pathiranage** against the M03 cover page before submitting.

---

## 1. Milestone 02 §3.3 — design alternatives (completed)

Compare at least three reservation-list layouts before Figma; record the decision.

| Variant | Strength | Weakness | Decision |
|---------|----------|----------|----------|
| **A. Single mixed list** (books + seats together) | One screen | Can't answer "what am I picking up today?" at a glance | **Rejected** |
| **B. Tabbed list — Books / Seats / Waiting** | Matches the three mental queries; scales | Tab state must survive navigation | **Selected** |
| **C. Calendar/timeline view** | Shows the day visually | Heavy for a 3–6 item dataset | **Later** |

**Final design (B):** a **tabbed reservations hub** — Books (hold shelf with pickup deadlines), Seats (active sessions + history), Waiting (live queue positions). Each row opens a **detail page**; destructive actions sit behind an explicit **confirm dialog** with consequences spelled out (FR15). The **notifications feed** is the system's voice: every create/cancel/promotion lands there (FR17/FR18), and unread state makes "what changed since I looked" answerable.

Downstream screens that belong to this same flow (Pathiranage):

| Figma | App file | Intent |
|-------|----------|--------|
| My Reservations | `lib/features/reservations/reservations_screen.dart` | Books / Seats / Waiting tabs |
| Reservation Details | `lib/features/books/reservation_detail_screen.dart` | One hold: meta, QR entry, cancel |
| Cancel Dialog → Cancelled | confirm dialog + `lib/features/books/reservation_cancelled_screen.dart` | Confirm-with-consequence, receipt |
| Notifications | `lib/features/notifications/notifications_screen.dart` | Live feed of status changes |

Data producers: Kalutotage writes book reservations, Yatawata writes seat bookings/waitlist entries; Pathiranage **consumes and curates** — plus owns cancel (D), read-state (U) and the notification documents every member's events create.

---

## 2. Requirements Pathiranage must satisfy

| ID | Requirement | Pathiranage's screens |
|----|-------------|----------------------|
| FR06 | Show the user's active book reservations | My Reservations → Books tab, Details |
| FR15 | Cancellation or expiry of reservations | Cancel Dialog, Books/Seats tabs |
| FR16 | Send reservation reminders | Notifications (pickup-by / session-start reminders) |
| FR17 | Provide reservation confirmations | Both success screens + notification on create |
| NFR01 / NFR03 / NFR06 | Clear UI, accurate state, text+colour status | All of the above |

Usability tasks from M02 (run on the **APK**): find "what am I picking up", cancel a hold and explain the consequence shown, tell whether a notification is new.

**CRUD (minimum two working ops — Pathiranage should ship all four):**

| Op | User action | Frontend | Backend |
|----|-------------|----------|---------|
| **C** Create | Notification documents on events (implicit) | — | `FirestoreService.addNotification` from every member's flows |
| **R** Read | Reservations tabs, details, feed | All screens | `AppState.activeReservations / bookings / waitlist / notifications` (live Firestore streams) |
| **U** Update | Mark read / mark all; cancel | Feed, Details | `markNotificationRead` / `markAllRead` (to add), `updateReservationStatus('cancelled')` (exists) |
| **D** Delete | Cancel reservation / cancel seat booking | Details dialog, Seats tab | `cancelReservation` + `cancelSeatBooking` (exist; both free the resource and promote the waitlist) |

---

## 3. Frontend — how it should look and behave

Campus-blue design (`AppColors`, Inter, 16px margins, 48dp targets). Motion stays light.

### 3.1 My Reservations (tabbed hub)

1. **Books tab** — hold-shelf cards: cover swatch, title, **pickup-by countdown** ("Pick up by Fri, 3 Oct · 4 days left"), status pill (Ready / Expiring soon / Cancelled). Tap → Details. Empty state: "Nothing on your shelf" + Browse CTA.
2. **Seats tab** — active booking card (seat label, date, time, QR entry, **Cancel booking**) + cancelled history. Cancel uses `cancelSeatBooking` (the seat frees + waitlist promotes — FR15 done right).
3. **Waiting tab** — waitlist entries with **#position**, estimated wait labelled *estimate*, **Leave queue** (U op). Tapping opens the joined screen.

### 3.2 Reservation Details

Full record: book, reservation id, reserved-at, pickup-by, pickup location, QR pass entry. **Cancel reservation** behind a confirm dialog that states the consequence ("The copy returns to the shelf and the next person waiting is offered it"). On confirm → `cancelReservation` → cancelled receipt screen.

### 3.3 Notifications feed (FR16/FR18)

1. Tinted cards (tone-coloured icon + headline + body + relative time) — already live from Firestore.
2. **Add read/unread**: `readAt` timestamp on the doc; unread cards get a dot + stronger tint; the shell badge shows **unread count, not total** (`unreadNotifications` should count unread only).
3. **Mark all read** action in the app bar; tapping a card marks it read.
4. **Deep links** (partial): a card carries `relatedId`-style data — tapping a "Seat Reservation Confirmed" card should land on the QR ticket / session, a book card on reservation details. Store a `link` field in `_notificationToMap` and switch on it.
5. **Reminders (FR16)**: generate notification docs client-side — on app start, scan active reservations/bookings: pickup within 24h → "Pickup expires tomorrow"; seat session starts within 1h → "Session starts soon". Idempotent via deterministic ids (`rem-<reservationId>-<kind>`); scheduled/FCM delivery is the Cloud-Functions upgrade path, note it as a deviation.

### 3.4 Frontend architecture (Pathiranage's feature)

```text
lib/features/reservations/
  presentation/   reservations_screen (3 tabs), detail, cancelled
  application/    reservations_controller, cancel_flow
lib/features/notifications/
  presentation/   notifications_screen
  application/    notification_controller (read-state, reminders)
```

Reads via `AppState` streams; writes via `AppState`/`FirestoreService` only. `MockData.buildReservations/buildNotifications` remain the test fixtures.

---

## 4. Backend — Firebase for Pathiranage's domain

### 4.1 Collections (Pathiranage-owned data)

**`users/{uid}/reservations/{id}`** — book holds; status `ready|active|expiringSoon|completed|cancelled`.
**`users/{uid}/bookings/{id}`** — seat bookings; `checkedInAt`, `status`.
**`users/{uid}/waitlist/{id}`** — waiting entries; position/estimate display.
**`users/{uid}/notifications/{id}`** — title, body, timestamp, tone, iconCodePoint; **add `readAt`** and **`link`** (deep-link key). Rules: owner read/update; any signed-in user may **create** (waitlist promotion writes cross-user — already in `firestore.rules`).

### 4.2 APIs Pathiranage implements / owns

| Function | Auth | Behaviour |
|----------|------|-----------|
| `cancelReservation(id)` (exists) | Owner | Marks `cancelled`, notification, **offers copy to next waitlisted user** (FR14/FR15) |
| `cancelSeatBooking(id)` (exists) | Owner | Deletes booking doc, frees seat, promotes waitlist |
| `markNotificationRead(id)` (to add) | Owner | Sets `readAt` server timestamp |
| `markAllNotificationsRead()` (to add) | Owner | Batch update over unread docs |
| `generateDueReminders()` (to add) | Client job | Idempotent reminder docs for 24h-pickup / 1h-session (FR16) |

### 4.3 Update sketch (mark all read)

1. Query `users/{uid}/notifications` where `readAt == null`.
2. Batch `update({'readAt': Timestamp.now()})`.
3. Badge recomputes from the live snapshot — no manual notify bookkeeping.

### 4.4 Security rules (already deployed)

- `reservations`, `bookings`: owner read/write (staff read for QR verification).
- `notifications`: owner read/update; signed-in create (cross-user promotion).
- Seat/queue docs staff-operated per Wathudura's file.

### 4.5 Indexes / queries

- Notifications by `readAt` (single-field, no composite needed).
- Reminders scan: user's own `reservations`/`bookings` — single-user queries.

---

## 5. End-to-end flows (Pathiranage)

**Cancel (T-cancel)**  My Reservations → Books → open hold → Cancel → dialog states consequence → confirm → receipt screen → Books tab shows it under history → copy restored to shelf → next waitlisted user's device gets the offer notification (works together with Yatawata's promotion).

**Notification lifecycle**  Any create/cancel lands in the feed as **unread** → badge increments → open card (marks read; deep-links) → "Mark all read" clears the badge.

**Reminder (FR16)**  Hold a book with pickup-by tomorrow → next app open → "Pickup expires tomorrow" notification exists, exactly once (relaunch → no duplicate).

---

## 6. Fidelity vs Figma (report table — fill as you go)

| Item | Figma | Implementation | OK / deviation |
|------|-------|----------------|----------------|
| Tabbed hub Books/Seats/Waiting | Required | Required | Must match |
| Confirm-before-cancel with consequence | Required | Required | Must match |
| Cancelled receipt screen | Required | Required | Must match |
| Tinted notification cards | Required | Required | Must match |
| Unread dots + badge + mark-all | M02 discussed | **Deviation** — post-prototype addition (justify: FR18 needs "new") |
| Client reminders vs scheduled functions | — | **Deviation** — client-side idempotent, Functions later |

---

## 7. Tests Pathiranage owns

**Functional (trace to FR):**

| ID | Case | Expect |
|----|------|--------|
| RT-01 | Books tab | Only book holds, pickup-by visible (FR06) |
| RT-02 | Seats tab | Active session + QR entry + cancel (FR15) |
| RT-03 | Cancel hold → dialog | Consequence text, confirm/cancel (FR15) |
| RT-04 | Confirm cancel | Receipt + status cancelled in Firestore + waitlist promotion |
| RT-05 | Notification on cancel | Feed shows unread "Reservation Cancelled" (FR18) |
| RT-06 | Tap unread card | Marks read; badge decrements (U op) |
| RT-07 | Mark all read | Badge clears; dots gone |
| RT-08 | Reminder scan | 24h-pickup reminder created once (FR16) |
| RT-09 | Leave queue | Waiting entry removed, positions fine |

Widget tests: tab switching, confirm dialog blocks direct cancel, feed renders tone cards, unread badge math. Fixtures from `MockData`.

---

## 8. Implementation order (Pathiranage)

1. `readAt` field + unread badge math + tap-to-read.
2. `markAllNotificationsRead` batch + app-bar action.
3. Deep-link `link` field + card tap navigation (QR / details).
4. Reminder generator (idempotent) + app-start hook.
5. Seats tab cancel polish (already correct API) + empty states.
6. Widget tests + screenshots; APK run RT-01…09.

---

## 9. Viva (Pathiranage)

Be able to:

1. Show all three tabs and explain which member's data each consumes.
2. Cancel a hold and narrate the full chain: dialog → Firestore update → receipt → waitlist promotion → notification.
3. Show unread/read state changing live from Firestore.
4. Name **FR06, FR15, FR16, FR17** and two CRUD ops you implemented.
5. Name one deviation (client reminders vs Functions) and why it still satisfies FR16.

Do not read this file aloud. Explain from the running app.
