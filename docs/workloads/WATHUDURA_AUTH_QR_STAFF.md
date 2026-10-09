# Wathudura (L K) — Auth, home, QR check-in & staff workload

**Owner:** Wathudura L K
**Reg. No:** IT23617100
**Module:** IT3060 HCI · Milestone 02 §3.4 + Milestone 03 implementation
**Scope:** **Login / session, Home dashboard, student QR pass + active session, staff scanner & verification, staff dashboard** — **frontend and backend**.

This file is Wathudura's working spec. Do **not** paste it unchanged into the 35-page PDF (AI similarity must stay below 50%). Rewrite in your own words for the report; use this for coding, viva, CRUD evidence, and deviation notes.

Related: M02 extract §3.4, FR14 (joint) + FR18 + FR19 + NFR04, `docs/UI_DESIGN.md`, `docs/FRONTEND_DESIGN.md`, `docs/BACKEND_DESIGN.md`, `docs/DATA_MODEL.md`, `docs/REPORT_AND_VIVA.md`.

> Reg-no note: M02's cover tables swap Wathudura/Pathiranage reg numbers in one place — confirm **IT23617100 = Wathudura** against the M03 cover page before submitting.

---

## 1. Milestone 02 §3.4 — design alternatives (completed)

Compare at least three auth + check-in approaches before Figma; record the decision.

| Variant | Strength | Weakness | Decision |
|---------|----------|----------|----------|
| **A. Email + password form only** | Familiar, no dependencies | Typing on mobile is slow; staff must pre-create accounts | **Base (kept)** |
| **B. QR-on-glass check-in** (student shows pass, staff scans) | No hardware beyond two phones; works offline-ish | Needs trust in the pass + replay protection | **Selected (core flow)** |
| **C. NFC tap check-in** | Fastest at the door | Requires tags/readers the library doesn't own | **Rejected** |

**Final design (A + B):** institution-email **sign-in that provisions the account on first use** (no separate register form to abandon), role switcher (student/staff) for the two navigation shells, then a **QR-on-glass** loop: student pass (`users/{uid}/bookings` QR) → staff **live camera scanner** → **server-side verification** → one-tap check-in. Status is never colour-only: valid / already-used / expired / not-recognised each get icon + headline + copy (NFR06).

Downstream screens that belong to this same flow (Wathudura):

| Figma | App file | Intent |
|-------|----------|--------|
| Login / Register | `lib/features/auth/login_screen.dart` | Sign-in + role entry point |
| Home | `lib/features/home/home_screen.dart` | Role-aware dashboard, today's session, quick actions |
| QR Ticket | `lib/features/qr/qr_ticket_screen.dart` | Student pass for check-in |
| Active Session | `lib/features/qr/active_session_screen.dart` | Live session after check-in |
| Staff Dashboard | `lib/features/staff/staff_dashboard_screen.dart` | Queue search, stats, dispatch list |
| Staff Scanner | `lib/features/staff/staff_scanner_screen.dart` | Live camera verification |
| Verification Result | `lib/features/staff/verification_result_screen.dart` | Valid / rejected states + confirm |

Damitha's seat booking and Kalutotage's book flow **produce** the records; Wathudura's screens **verify and operate** on them. Home "Reserve a Seat" deep-links into Damitha's map.

---

## 2. Requirements Wathudura must satisfy

| ID | Requirement | Wathudura's screens |
|----|-------------|---------------------|
| FR18 | Notify users of status changes | Notifications feed (events this flow writes) |
| FR19 | QR-based seat check-in | QR Ticket, Staff Scanner, Verification Result |
| FR14 | Notify waiting-list users when a seat frees up | Joint with Yatawata — check-in/cancel triggers promotion |
| NFR04 | Admin functions limited to authorised users | Login role model, Staff Dashboard/Scanner |
| NFR01 / NFR03 / NFR06 | Clear UI, accurate state, text+colour status | All of the above |

Usability tasks from M02 (run on the **APK**): sign in, find today's session from Home, show the pass, scan it as staff and explain each verification outcome.

**CRUD (minimum two working ops — Wathudura should ship all four):**

| Op | User action | Frontend | Backend |
|----|-------------|----------|---------|
| **C** Create | Sign-in session; verification check-in | Login, Scanner → Result | `FirestoreService.signIn` (provisions `users/{uid}`), `consumeVerifiedCode` |
| **R** Read | Home cards, queue, verification lookup | Home, Staff Dashboard, Result | `AppState` streams; `verifyCode` collection-group query |
| **U** Update | Check-in a booking; queue entry status | Result confirm, Dashboard actions | `consumeVerifiedCode`, `updateQueueStatus` |
| **D** Delete | Dismiss queue entry | Dashboard | `deleteQueueEntry` |

---

## 3. Frontend — how it should look and behave

Campus-blue design (`AppColors`, Inter, 16px margins, 48dp targets). Motion stays light.

### 3.1 Login (P-01)

1. Campus mark + headline + filled rounded fields + stadium buttons.
2. Sign-in normalises the identifier to an `@sliit.lk` email and calls Firebase Auth; **first sign-in provisions** the auth user + `users/{uid}` profile (no dead "Register" button — FEATURES.md forbids inactive CTAs).
3. Role switcher (Student / Staff) seeds the profile role; **NFR04 honest wording**: the prototype picks role at sign-in; production enforces staff via custom claims — say this in the viva, don't hide it.
4. Busy state on the button while auth runs; failure surfaces a snack, never a silent return.
5. Session restoration: cold start resumes the Firebase session (`AppState.restoreSession`) — splash → shell directly.

### 3.2 Home

1. Header: avatar + greeting from the live profile.
2. **Today's session** card (next seat booking) with QR entry; hold-shelf strip (first ready book); queue/occupancy summaries; quick actions (Books / Seats / QR / Reservations / Notifications badge).
3. All data from `AppState` streams — Home must never import `MockData` for display.

### 3.3 QR pass + Active Session

1. Pass renders `booking.qrCode` (`qr_flutter`) with seat/date/time meta and a brightness hint.
2. Check-in button marks `checkedInAt` (Firestore) → Active Session shows live status and early checkout.
3. The pass code is what staff verification matches — keep the format stable (`LIB-2026-…`).

### 3.4 Staff Scanner (P-14) — live camera

1. `mobile_scanner` viewfinder with the branded frame + sweep; manual-code fallback for desktop/simulator/denied camera (fallback state is explicit, not a dead frame).
2. On detect: debounce (`_handling`) → `FirestoreService.verifyCode(code)` → push Verification Result. Also verify on manual submit.
3. Torch toggle + camera switch are cheap wins on top of `MobileScannerController` — add if time allows.

### 3.5 Verification Result (P-15)

Real states, each with icon + headline + body (never colour-only):

| State | Detection | Action |
|-------|-----------|--------|
| Valid seat pass | active booking, not checked in | **Confirm Check-in** → `consumeVerifiedCode` → Active Session |
| Already checked in | `checkedInAt != null` | Inform, no action |
| Cancelled / expired / completed | status field | Reject with reason |
| Not recognised | `verifyCode` returned null | Reject, rescan |

Book-pass variant: valid `ready` reservation → **Confirm Handover** (completes the hold — Kalutotage's pickup loop closes here).

### 3.6 Staff Dashboard

1. Queue search + filter chips (All/Active/Urgent) + four stat tiles.
2. Dispatch list **streams from Firestore `queue`** for staff profiles (`approveQueueEntry` / `dismissQueueEntry` already persist).
3. Backlog the spec calls out: real queue entries are created when a student taps "call for assistance" — add a Home quick-action that writes a `queue` doc so the dashboard isn't seeded-only.

### 3.7 Frontend architecture (Wathudura's feature)

```text
lib/features/auth/      login_screen
lib/features/home/      home_screen
lib/features/qr/        qr_ticket_screen, active_session_screen
lib/features/staff/     staff_dashboard_screen, staff_scanner_screen,
                        verification_result_screen
application/            auth via AppState/FirestoreService (widgets never
                        touch FirebaseAuth/FirebaseFirestore directly)
```

---

## 4. Backend — Firebase for Wathudura's domain

### 4.1 Collections (Wathudura-owned data)

**`users/{uid}`** — profile (name, studentId, email, role); provisioned at first sign-in.
**`users/{uid}/bookings/{id}`** — seat bookings read by Home/QR/Active Session; `checkedInAt` written by staff check-in (`consumeVerifiedCode`).
**`users/{uid}/devices/{token}`** — FCM tokens for FR14/FR18 push (registered by `NotificationService`).
**`queue/{id}`** — dispatch entries; staff-only reads/writes in spirit, signed-in in rules (prototype).
**`books` / `seats` / collection-groups `reservations`,`bookings`,`waitlist`** — read paths for verification/lookup.

### 4.2 APIs Wathudura implements / owns

| Function | Auth | Behaviour |
|----------|------|-----------|
| `signIn(identifier, role)` (exists) | Student/staff | Email/password sign-in → auto-provision → anonymous fallback offline |
| `restoreSession()` (exists) | — | Cold-start session resume |
| `verifyCode(code)` (exists) | Staff | Collection-group lookup over `bookings` + `reservations` by `qrCode`; returns kind/status/owner/times or null |
| `consumeVerifiedCode(path, kind)` (exists) | Staff | Seat: `checkedInAt = now`, status `active`. Book: status `completed` |
| `saveDeviceToken` (exists) | Signed-in | FCM token registration (FR14/FR18) |
| `createQueueEntry` (to add) | Student | Home "request assistance" → queue doc |
| `verifyQrToken` hardening (planned) | Staff | Signed tokens + nonce (`qrTokens/{id}`) for replay protection — DATA_MODEL.md |

### 4.3 Transaction sketch (check-in)

`consumeVerifiedCode` already updates the booking atomically-enough for the prototype (single-field update; Firestore applies it once). The hardening path mirrors Damitha's §4.3: verify token unspent in `qrTokens`, then update booking + mark nonce consumed in one transaction.

### 4.4 Security rules (already deployed)

- `bookings`: signed-in read (staff verification), owner write.
- `users/{uid}`: read signed-in (owner-name lookup), write owner.
- `queue`: signed-in read/write (prototype; tighten to staff claim later).
- Everything else denied by default.

### 4.5 Indexes / queries

- Collection-group `bookings` where `qrCode ==` (single-field — no composite needed; already used by `verifyCode`).
- Same for `reservations`.
- `queue` full-list stream (small dataset).

---

## 5. End-to-end flows (Wathudura)

**Happy path (T-check-in)**  Sign in → Home shows today's session → open QR pass → staff device: scanner detects code → **Valid reservation** with student identity → Confirm Check-in → student's Active Session live → second scan shows **Already checked in** (FR19).

**Rejection paths**  Cancelled booking pass → "Reservation cancelled" reject; random code → "Code not recognised" + rescan (colour + icon + text, NFR06).

**Staff queue**  Student taps assistance (once added) → queue doc appears on the dashboard → Approve flips status live on both devices (FR18 event).

**FR14 joint**  Check-in/cancel events → waitlist promotion (Yatawata's `promoteNextOnWaitlist`) → offered user's device notification via the devices collection.

---

## 6. Fidelity vs Figma (report table — fill as you go)

| Item | Figma | Implementation | OK / deviation |
|------|-------|----------------|----------------|
| Login + role entry | P-01 | Required | Must match |
| Home dashboard cards | Required | Required | Must match |
| Student QR pass | Required | Required | Must match |
| Live camera scanner | M02 "planned" | **Implemented** (`mobile_scanner`) | Exceeds prototype — justify |
| Verification state matrix | Sketches | Required | Must match |
| Staff role via switcher vs claims | M02 implied secure | **Deviation** — client-chosen in prototype; claims are the production answer (NFR04) |
| Signed QR tokens / replay protection | — | **Deviation** — static codes now; `qrTokens` planned |
| Register screen | Mockup | **Deviation** — first sign-in provisions (fewer dead ends) |

---

## 7. Tests Wathudura owns

**Functional (trace to FR):**

| ID | Case | Expect |
|----|------|--------|
| WT-01 | Sign in fresh email | Profile doc created, lands in student shell |
| WT-02 | Kill + relaunch | Session restored, no login screen |
| WT-03 | Home cards | Today's session + hold shelf from live data (no mock) |
| WT-04 | Show pass | QR renders booking code + meta |
| WT-05 | Staff scans valid pass | Valid state + identity + Confirm (FR19) |
| WT-06 | Confirm check-in | Booking `checkedInAt` set in Firestore; Active Session live |
| WT-07 | Re-scan same pass | "Already checked in", no double write |
| WT-08 | Scan unknown code | Not-recognised state + rescan |
| WT-09 | Dashboard actions | Approve/dismiss persist to `queue` (NFR04 shell) |
| WT-10 | Sign out | Session cleared, login returns, listeners torn down |

Widget tests: login busy/failure states, scanner fallback widget, verification matrix (valid/used/cancelled/unknown), dashboard filter logic. Fixtures from `MockData`.

---

## 8. Implementation order (Wathudura)

1. Torch/camera-switch on the scanner; polish denied-permission copy.
2. `createQueueEntry` + Home assistance action (dashboard goes live-write).
3. Verification hardening: signed codes or `qrTokens` nonce check (even a stub proves the design).
4. Deep-link a "session started" notification tap → Active Session.
5. Widget tests + screenshots; APK run WT-01…10.

---

## 9. Viva (Wathudura)

Be able to:

1. Sign in and explain what "auto-provision" did in Firestore (`users/{uid}`).
2. Show the two-device check-in: pass → scan → valid → Firestore `checkedInAt`.
3. Demo all four verification outcomes and why each is colour+icon+text (NFR06).
4. Explain NFR04 honestly: prototype role switcher vs custom-claims production design.
5. Name **FR14 (joint), FR18, FR19** and two CRUD ops you implemented.

Do not read this file aloud. Explain from the running app.
