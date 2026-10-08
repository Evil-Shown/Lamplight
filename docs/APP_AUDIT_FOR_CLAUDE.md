# Library+ (SLIIT Quick Book) — Complete Application Audit

> **Purpose of this document:** a self-contained, exhaustive description of an existing Flutter mobile app — every screen, feature, component, flow, backend surface, and design token — so that an AI assistant (Claude) can generate a **complete frontend design build-up prompt** (or redesign system) without ever seeing the code.
>
> **How to use:** feed this whole file to Claude and ask for whatever design artefact is needed (full redesign prompt, Figma-ready screen specs, design-system tokens, new-screen designs). Every fact below is from the real codebase as of October 2026. Nothing is aspirational unless marked **[gap]**.

---

## 1. Product identity

| Field | Value |
|-------|-------|
| **Product name** | Library+ (in-app strings: `Library+`, portal name `SLIIT QUICK BOOK`) |
| **One-liner** | Library book reservation & reading-room seat booking system for a university campus (SLIIT) |
| **Users** | Two roles: **Student** and **Staff** (librarian). Role chosen at sign-in in the current build. |
| **Core jobs** | ① Find & reserve library books for pickup ② Find & reserve reading-room seats on a floor map ③ Join waitlists when a resource is taken ④ Show a QR pass that staff verify with a live camera scanner ⑤ Staff dashboard to operate the dispatch queue |
| **Platforms** | Android (primary, release APK 70MB), iOS (configured, buildable on macOS), Web + Windows (runnable for UI work) |
| **Backend** | Firebase project `sliit-quick-book` — Firebase Auth (Email/Password + provisioning), Cloud Firestore (real-time streams), Firebase Cloud Messaging + local notifications |
| **Status** | Working end-to-end app: real auth, real-time Firestore data, atomic seat booking, camera QR scanning, device notifications, waitlist promotion. ~11,000 lines of Dart. |

**Vibe / brand direction:** "Modern Editorial & Warm Academic" — campus-blue Material 3, off-white cool paper background, white cards with hairline borders, single strong blue for actions, semantic colour reserved strictly for status, uppercase letter-spaced micro-labels, generous whitespace, light motion (stagger-in, press-scale, count-up, shimmer skeletons, hero flight for book covers). Full light **and** dark theme.

---

## 2. Tech stack & architecture

```
Flutter (Material 3, Dart 3, null-safety)
├── state          : AppState extends ChangeNotifier + AppScope (InheritedNotifier) — no DI packages
├── routing        : No named routes — MaterialApp home + Navigator.push(MaterialPageRoute)
├── shell          : IndexedStack + NavigationBar, role-aware tab set (5 tabs)
├── backend        : firebase_core, firebase_auth, cloud_firestore, firebase_messaging,
│                    flutter_local_notifications, mobile_scanner, qr_flutter,
│                    google_fonts (Inter), intl, dbus-free pure Dart elsewhere
├── data           : FirestoreService (singleton, all Firestore+Auth I/O, converters,
│                    transactions, collection-group queries)
│                    MockData (seed + offline/test fixture)
├── models         : plain Dart value classes (Book, Seat, BookReservation, SeatBooking,
│                    WaitlistEntry, AppNotification, UserProfile, QueueEntry,
│                    FloorOccupancy, NotificationPreferences + enums)
└── tests          : flutter_test — 28 passing (screen sweep renders every screen at
                     1080×2400 dpr3 catching overflows + behaviour tests)
```

**Layering rule (enforced):** widgets → `AppState` → `FirestoreService` → Firestore. Widgets never touch FirebaseAuth/FirebaseFirestore directly.

**Real-time model:** `AppState` holds live lists (books, seats, reservations, bookings, waitlist, notifications, queue) fed by Firestore `.snapshots()` streams; writes are optimistic (insert locally) then persisted; snapshots reconcile. A `lastSyncedAt` timestamp powers "Live · updated just now" freshness indicators; when Firebase is unreachable the app degrades to seeded mock data labelled "Offline — showing cached".

---

## 3. Design system (exact tokens)

### 3.1 Colour — light scheme (hand-tuned, NOT ColorScheme.fromSeed)

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#0B57D0` | Actions, links, active states (campus blue) |
| `onPrimary` | `#FFFFFF` | Text on primary |
| `primaryContainer` | `#D3E3FD` | Soft blue fills, chips |
| `onPrimaryContainer` | `#041E49` | Text on primaryContainer |
| `secondary` / `cyan` | `#575E71` | Secondary accents |
| `secondaryContainer` | `#DBE2F9` | Soft slate fills |
| `tertiary` / `accent` | `#9A4A26` | Warm rust — selected seats, special highlights |
| `tertiaryContainer` | `#FFDBCF` | Soft warm fills |
| `error` | `#BA1A1A` | Destructive, occupied |
| `errorContainer` | `#FFDAD6` | Soft error fills |
| `surface` (page bg) | `#F4F6FB` | Cool off-white page |
| `surfaceContainerLow` (cards) | `#FFFFFF` | Card surfaces |
| `surfaceContainer` | `#EDF0F6` | Muted fills |
| `surfaceContainerHigh` | `#E6EAF1` | Stronger muted fills |
| `onSurface` | `#191C20` | Primary text |
| `onSurfaceVariant` | `#42474E` | Secondary text |
| `outline` | `#72777F` | Faint text |
| `outlineVariant` (borders) | `#DEE2EA` | Hairline card borders |
| success (soft bg) | derived | Success pills/callouts |
| warning (soft bg) | derived | Limited-availability states |

### 3.2 Colour — dark scheme

| Token | Hex |
|-------|-----|
| `primary` | `#A8C7FA` |
| `onPrimary` | `#062E6F` |
| `primaryContainer` | `#0842A0` |
| `surface` (page bg) | `#101418` |
| `surfaceContainerLow` (cards) | `#181C22` |
| `surfaceContainer` | `#1C2026` |
| `surfaceContainerHigh` | `#262A31` |
| `onSurface` | `#E1E2E8` |
| `onSurfaceVariant` | `#C2C7CF` |
| `outlineVariant` | `#42474E` |
| `tertiary` | `#FFB69E` |
| `error` | `#FFB4AB` |

Semantic aliases: `seatAvailable = success`, `seatLimited = warning`, `seatOccupied = error`, `seatSelected = tertiary/accent`. A book **cover palette** of 10 deterministic hex values (`0xFF1E40AF`, `#0E7490`, `#B45309`, `#9D174D`, `#5B21B6`, `#155E75`, …) generates cover art when no image exists.

### 3.3 Typography

**Inter** via `google_fonts` (bundled behaviour). `AppText` factory:

| Style | Spec |
|-------|------|
| `display(size)` | w800, ls −0.9…−1.6 — hero numbers, screen headlines |
| `title(size, w)` | w600–w800, ls −0.4 — card titles, app-bar titles |
| `body(size)` | w400, height 1.45 — copy |
| `label(size, w)` | w600–w700 — buttons, chips |
| `overline(size, ls)` | w700 uppercase + 0.8–1.8 letter-spacing — micro-labels ("CURRENT FLOOR", "TOP PICK", "RENTING TIME") |

Type scale in use: 58 (hero queue number), 30 (seat hero), 22 (success headlines), 17–19 (app bars, section headlines), 13–15.5 (card copy/titles), 11–12.5 (captions), 9–10.5 (overlines).

### 3.4 Shape, spacing, elevation

- Radii: `xs 8, sm 12, md 16, lg 20, xl 28, full 999` (stadium pills everywhere for buttons/chips).
- Spacing scale: `4, 8, 16, 24, 32, 40`; 16px screen margins; card internal padding 14–20.
- Shadows: `card` (soft 0,6,20 @8%), `raised` (0,8,28 @12%), `primary`/`glow(color)` (blue glow for selected states). Cards are **flat white + hairline border + optional tint**, not heavy elevation.
- Gradients: `brand` (blue → light blue diagonal), `hero` (deep blue aurora for hero panels), `aurora` / `auroraSoft` (animated drifting sheen behind hero content), `mint` (green success gradient), `panel` (subtle vertical).
- Touch targets ≥ 48dp; extra 96px bottom inset so scroll content clears the nav bar.
- Edge-to-edge with transparent system bars; light/dark status-bar icons synced per theme.
- Page transitions: custom soft fade+slide (`_SoftPageTransitionsBuilder`).
- Haptic vocabulary (`Haptics`): selection clicks on tabs/slots, light impact on confirms.
- Motion widgets: `StaggeredEntrance` (fade+lift sequence by index), `PressScale` (scale-down spring), `CountUp` (numbers animate up), `Skeleton`/`SkeletonCard` (shimmer placeholders), hero flight on book covers.

---

## 4. Navigation model

**Entry flow:** `SplashScreen` (animated brand ring draws + mark lands + wordmark fades, ~1.2s) → **LoginScreen** if signed out → **AppShell** if signed in. Session restored from Firebase on cold start.

**AppShell — 5 tabs, role-aware, IndexedStack (state preserved per tab):**

| # | Student tabs | Staff tabs |
|---|--------------|------------|
| 0 | Home | Home (staff dashboard variant) |
| 1 | Seats (seat map) | Seats |
| 2 | Books (catalog) | Catalog |
| 3 | Bookings (reservations hub) | Bookings |
| 4 | Profile (account) | Staff (dashboard) |

NavigationBar: M3 style, outline→filled icon pair per destination, haptic on switch. Staff shell shows the staff dashboard at tab 4. Pushed screens use `AppScaffold` (centred title, back chevron, optional bottom action bar slot).

---

## 5. Complete screen inventory (19 screens + splash + filter sheet)

### 5.1 Login — `lib/features/auth/login_screen.dart`
- Campus mark (rounded "LP" app mark) at 68px, display headline "Reserve books and study seats.", tonal surface.
- Filled rounded text fields: university email (identifier), password w/ obscure toggle + focus behaviour.
- "Remember me" checkbox row; primary stadium button "Sign in" with busy spinner state.
- Segmented switcher for alternate sign-in paths (student/staff role entry); staff entry at bottom enables the staff tab shell.
- Behaviour: identifier normalised to `@sliit.lk`, Firebase email/password sign-in, **auto-provisions** the account + `users/{uid}` profile on first use; failure shows a snackbar; success → AppShell. Session restore skips this screen entirely. **[gap]** no dedicated register screen (by design); Google sign-in button paths not yet live.

### 5.2 Home — `lib/features/home/home_screen.dart` (student tab 0)
Sections top→bottom:
1. `_HomeHeader`: avatar (initials on brand circle) + greeting ("Good morning, {firstName}") + notification bell with unread badge.
2. `_TodaySession`: brand-aurora hero card for today's seat booking — seat label, floor/zone, time range, **QR tile** (`_QrTile`), tap → Active Session. If no booking: `_NoSessionCard` ("No seat reserved today" + Reserve CTA → Seats tab).
3. `_QuickActions`: glassy tile grid — Books, Seats, QR, Reservations, Notifications (badge) → deep-links by switching tabs/pushing routes.
4. `_ReadyForCollection`: first ready book hold — cover, title, pickup-by countdown, tap → Reservation Details.
5. `_NoiseLevelCard`: "Live library density" with `MeterBar` progress + `CountUp` occupancy %.
6. All data live from AppState streams; empty states for no-session/no-holds.

### 5.3 Seat Map — `lib/features/seats/seat_map_screen.dart` (tab 1, P-06)
1. App bar: overline "CAMPUS COMMONS" + "Seat Reservation"; back chevron only when pushed (hidden on tab).
2. Headline "Find and reserve your ideal study spot".
3. **Freshness line**: pulsing dot + "Live · updated just now" / "Offline — showing cached seat map".
4. `_ZonePicker` card: CURRENT FLOOR overline, "Floor 2 · N desks", floor dropdown (Floor 1/2/3) — **really filters** by `seat.floor`.
5. `FilterChipRow`: Quiet Area / Power Outlets / Dual Monitors quick chips (multi-select state).
6. Count line "N of M seats available" + **Filters** text-button → bottom sheet.
7. `SegmentedTabs` **Map | List** toggle (accessibility list mode).
8. `_RecommendedCard` (TOP PICK): seat label, reason line ("Quiet · Power outlet · Near window"), Available pill, "Select Spot" stadium button → details. Empty variant: "No free seat matches these filters" card.
9. Map mode: `_SeatGridCard` — 4×4 circular seat badges (52px) with diagonal colour gradients, per-status shadows/glow, label text, power-dot micro indicator, **check-badge overlay when reserved by the signed-in user**; entrance/stairwell footer. Empty grid slots render blank (filters preserve 4×4 positions).
10. `_Legend` wrap: Available (n) / Limited (n) / Full (n) / Selected / **Yours ×n** — dot + text, never colour-only.
11. List mode: `_SeatList` rows — label, zone · floor, status pill, tap → detail.
12. Selecting a seat (map or list) raises a sticky `BottomActionBar`: "Seat {label} · Selected" + Continue → Seat Details.

### 5.4 Seat Filter Sheet — `lib/features/seats/seat_filter_sheet.dart` (P-06A)
Modal bottom sheet: Filters title + reset icon; Floor segmented tabs; Study-area checkboxes (Quiet Zone / Collaborative Space / Individual Pod); Facilities checkboxes (Power Outlet / Monitor Screen / Standing Desk); Reset + Apply Filters buttons. `SeatFilters.matches()` honours floor, categories, power, monitor, standing desk.

### 5.5 Seat Details — `lib/features/seats/seat_detail_screen.dart` (P-07)
1. `GradientHero`: overline "FLOOR 2 · QUIET ZONE", display "Seat 2C", sub-caption, status pills ("Available Now" pulsing / "Limited availability" / "Currently occupied"; "Dual 4K monitors" if present).
2. `_ZoneStrip`: three zone mini-cards (Quiet Wing / Power Wing / Panel Hub), active ones highlighted.
3. "Renting time" card: date row (e.g. "Today, 24 Oct 2026") with **Change** → `showDatePicker` (today → +14 days; past slots auto-cleared).
4. "Select available time slot": `_SlotRow` list — time ranges with **live availability** ("N of M desks left" from Firestore occupancy), popularity badges ("Most popular", "Popular"), selected ring, past slots disabled, haptic on select.
5. "Included seat amenities" card: desk lamp, lumbar chair, acoustic partition + conditional rows (dual monitors / standing desk / 65W power).
6. Info callout: "Freshly serviced in 5 min".
7. Bottom bar: **available** → "Reserve Seat {label}" (disabled until a future slot chosen; shows "Choose a time slot" hint + selected slot caption) → atomic reserve → Booking Confirmation. **occupied** → "Join waiting list" → Waitlist Screen with this seat. Conflict (another user won the seat) → snackbar "Seat was just taken — pick another".

### 5.6 Booking Confirmation — `lib/features/seats/booking_confirmation_screen.dart` (P-08)
Mint-gradient hero: animated check circle, "Booking Confirmed!", subline. Details card: Seat (label + zone), Floor, Date, Time range, **Booking ID** (blue). QR callout. Actions: **Show QR pass** → QrTicketScreen (passes `SeatBooking`), **Done** → pop to shell.

### 5.7 Waitlist Screen — `lib/features/waitlist/waitlist_screen.dart` (P-09)
Warning callout ("Seat {label} is currently unavailable…"), "Your preferences" chip wrap (zone, power, window, floor), giant **#position** display (58px, counts up), "Your position in queue", "Estimated wait: about 45 minutes" (labelled estimate), notification promise callout, **Join waiting list** (disabled→"Already on the waitlist" if dup) → persists to Firestore → pushes Joined screen, Cancel secondary button. Receives the real `Seat` (no hardcoding).

### 5.8 Waitlist Joined — `lib/features/waitlist/waitlist_joined_screen.dart` (P-09A)
Spring-scale bell icon, "Joined Waiting List", details card: Seat Preference, Floor, Queue Position #n (blue), Estimated Wait "~45 minutes". Done action.

### 5.9 Book Search / Catalog — `lib/features/books/book_search_screen.dart` (tab 2, book-search-v2)
1. "Library Catalog" header with live-status pill.
2. Search field ("Search by title, author, ISBN…") — **live filtering**, no submit step.
3. Search-type tabs: Title / Author / ISBN / Category (Title tab forgivingly matches author+subject too; ISBN normalises dashes).
4. `_CatalogCard` live results: cover (BookCover w/ hero tag), title, author, availability pill + copies, shelf code, Reserve action on available rows.
5. `_BarcodeBanner`: dark ISBN-scanner promo strip — **[gap]** decorative; wire to `mobile_scanner` or remove.
6. "Show all" expansion (`_showAll`); tap card → Book Details; Reserve → creates reservation → Reservation Confirmation.

### 5.10 Search Results — `lib/features/books/search_results_screen.dart`
Full-page results for a query; `_ResultRow` list (cover thumb, title, author, availability); empty state; same matching logic as inline results.

### 5.11 Book Details — `lib/features/books/book_detail_screen.dart`
Cover hero (BookCover, deterministic colour plate fallback), title/author/subject/ISBN, description, availability callout ("3 copies available. Located on shelf B2-14." success tone / "All copies are out. Join the waitlist…" warning tone), due date when on loan. Bottom bar: **RESERVE BOOK** → confirmation, or **JOIN WAITLIST** when 0 copies **[gap]** waitlist-join shows only a snackbar — should route through position screen.

### 5.12 Reservation Confirmation (book) — `lib/features/books/reservation_confirmation_screen.dart` (FR07/FR17)
Success hero (SuccessCheck), reservation summary (book, **pickup-by deadline 7 days**, pickup location, reservation id), callout, Done → My Reservations.

### 5.13 My Reservations — `lib/features/reservations/reservations_screen.dart` (tab 3, container-3)
Segmented tabs **Books | Seats | Waiting**:
- **Books**: hold-shelf cards — cover, title, status pill (Ready/Expiring soon/Cancelled), pickup-by countdown; tap → Reservation Details; empty state.
- **Seats**: active booking card (seat, date, time, QR entry, Cancel booking → `cancelSeatBooking` frees seat + promotes waitlist) + cancelled history.
- **Waiting**: waitlist entries — title, subtitle, "~45 min" estimate, giant #position (CountUp), **Leave queue** action.
Reservation Details (pushed): full meta card + **QR pass entry** + confirm-then-cancel AlertDialog ("This action cannot be undone" + consequence) → Reservation Cancelled receipt screen.

### 5.14 Notifications — `lib/features/notifications/notifications_screen.dart`
Live Firestore feed of tinted cards — tone-coloured icon badge (success/info/warning/danger), headline, body, relative timestamp ("12 min ago"). Empty state "Nothing new". **[gap]** read/unread state, mark-all, deep links, reminders (specified in Pathiranage's workload; not built).

### 5.15 QR Ticket — `lib/features/qr/qr_ticket_screen.dart`
Large QR render of `booking.qrCode` (qr_flutter), seat label + date/time meta, "Show this at the entrance" guidance, check-in action (marks `checkedInAt`).

### 5.16 Active Session — `lib/features/qr/active_session_screen.dart`
Live session dashboard: brand hero with seat + time remaining, `_EntitlementTile` grid (power, monitor, zone entitlements), checkout action, state synced to Firestore.

### 5.17 Staff Dashboard — `lib/features/staff/staff_dashboard_screen.dart` (staff tab 4, P-13)
Staff header with CampusMark, queue search field, filter chips (All/Active/Urgent), four `StatTile` stats (with CountUp), dispatch `_QueueRow` list (student name, id, location, requested-at, status pill) with per-row Approve/Dismiss actions persisting to Firestore. Streams live for staff profiles.

### 5.18 Staff Scanner — `lib/features/staff/staff_scanner_screen.dart` (P-14)
"Scan a student reservation pass" caption; 1:1 dark scan surface with **live `mobile_scanner` camera** under a branded `_ViewfinderFrame` (4 corner brackets) + animated sweep line; camera-unavailable fallback card (desktop/denied); manual-code entry field + "Verify Entered Code" button; privacy caption. Debounced detect → Firestore verification → result screen.

### 5.19 Verification Result — `lib/features/staff/verification_result_screen.dart` (P-15)
State banner (icon + headline + body, success/error tone): **Valid reservation / Valid book reservation / Already checked in / Reservation cancelled / expired / completed / Code not recognised**. Details card: seat label (or book-title initial) tile, student name + ID (from Firestore owner lookup), location, time/pickup-by, code caption, Verified/Rejected pill. Actions: **Confirm Check-in / Confirm Handover** (persists `checkedInAt`/`completed` to Firestore → Active Session for seat passes) or **Scan Again**; **Report an Issue** danger button → snackbar.

### 5.20 Account / Profile — `lib/features/account/account_screen.dart` (student tab 4)
`_IdentityCard` (avatar, name, student ID, role) + `_MemberStats` (Books held / Seats booked / Waiting counts), Privacy section (Staff-only visibility toggle **[gap]** cosmetic), Quick links (Notifications, Settings, Help & support), **Sign out** (revokes Firebase session, tears down streams, returns to Login).

### 5.21 Settings — `lib/features/settings/settings_screen.dart`
Notification methods toggles (push/email/SMS + reminder-before-start/expiry + waitlist updates — `NotificationPreferences` model), Appearance: light/dark/system `_ThemePicker` (live theme switch), Other settings rows. Value Proposition screen (onboarding "why Library+" feature cards) also present.

---

## 6. Feature inventory (requirements traceability)

| FR | Requirement | Status |
|----|-------------|--------|
| FR01–02 | Search books by title/ISBN/author/subject | ✅ live, client-side over Firestore catalogue |
| FR03–04 | Availability + book info before reserving | ✅ live counts, shelf, copies, due date |
| FR05 | Reserve an available book | ✅ persisted to `users/{uid}/reservations` **[gap]** duplicate-guard + copy decrement transaction specified, not built |
| FR06 | Show active book reservations | ✅ tabbed hub with live streams |
| FR07 | Confirmation after book reservation | ✅ success screen + notification doc |
| FR08 | Display available seats | ✅ 4×4 live map + legend + counts |
| FR09 | Seat information (power/quiet/window) | ✅ details + amenity rows |
| FR10 | Identify seats by preference | ✅ filter sheet + TOP PICK recommendation w/ reasons |
| FR11 | Reserve an available seat | ✅ date + slot picker, **Firestore transaction (atomic, conflict-safe)** |
| FR12 | Confirmation after seat reservation | ✅ P-08 + QR pass |
| FR13 | Join a waiting list | ✅ seat waitlist with live position; **[gap]** book waitlist parity |
| FR14 | Notify when a seat frees up | ✅ cancel frees resource → first waiting user flipped to `offered` → notification doc → **device notification via FCM+local notif** |
| FR15 | Cancellation with consequence | ✅ confirm dialog → receipt → resource freed → promotion |
| FR16 | Reservation reminders | ❌ **[gap]** specified (idempotent 24h/1h client reminders), not built |
| FR17 | Confirmations | ✅ both success screens write notification docs |
| FR18 | Notify status changes | ✅ in-app feed live + FCM foreground push + local device notifications |
| FR19 | QR-based seat check-in | ✅ student pass + **real camera scanner** + server verification + check-in persistence |
| NFR04 | Authorised staff only | ⚠️ role at sign-in (prototype); custom claims specified for production |

**Live backend capabilities:** Firebase Auth sign-in/auto-provision/session-restore; Firestore real-time streams for books, seats, per-user reservations/bookings/waitlist/notifications/queue; atomic seat-booking transaction (loser reverted by snapshot); collection-group QR verification (code → booking/reservation + owner identity); waitlist promotion on cancel; FCM token registration under `users/{uid}/devices`; foreground push → local notifications; offline resilience to seeded mock data with "Offline" labelling; Firestore security rules deployed (owner-only personal data, signed-in shared catalogue, cross-user waitlist offers).

---

## 7. Component library (all reusable widgets)

**Surfaces:** `SurfaceCard` (white rounded card, hairline border, optional tint/press/elevation) · `GlassTile` (soft glassy tile) · `GradientHero` (gradient panel + animated drifting sheen) · `AppScaffold` (centred-title app bar + optional `BottomActionBar` slot) · `BottomActionBar` (sticky primary-action bar).
**Content:** `SectionLabel` / `SectionHeader` · `InfoRow` (label/value split) · `StatusPill` (tinted pill, optional pulse dot) · `Callout` (tinted info/success/warning/danger banner) · `EmptyState` (icon circle + headline + CTA) · `MeterBar` (progress track) · `StatTile` (staff stats) · `StatePill` ("VERIFIED"-style) · `CampusMark` (LP brand mark) · `SplashScreen` (animated ring-draw choreography, `_BrandRingPainter`).
**Controls:** `PrimaryButton` (stadium, 4 tones, icon slots, disabled/busy) · `SegmentedTabs` (2–3-way pill switcher) · `FilterChipRow` (multi-select chips w/ icon builder) · `SettingRow` (icon square + label + chevron/toggle) · `IconBadge` (rounded icon square) · `BookCover` (OpenLibrary image → deterministic colour spine plate, hero flight).
**Feedback/motion:** `StaggeredEntrance` · `PressScale` · `CountUp` · `Skeleton` / `SkeletonCard` · `SuccessCheck` · `Haptics` (selection/light/impact vocabulary).

---

## 8. Data model (Firestore)

```
books/{id}                    title, author, subject, isbn, availability(available|onLoan|waitlisted),
                              shelfLocation, copiesAvailable, description, coverColor, dueDate
seats/{id}                    label(2C), floor, section, row, col, category(quietZone|collaborative|individualPod),
                              status(available|limited|occupied), hasPowerOutlet, hasMonitor, nearWindow, standingDesk
queue/{id}                    studentName, studentId, location, requestedAt, status(active|pending|expired)
users/{uid}                   name, studentId, email, role(student|staff), reservationsVisibleToStaffOnly
  ├ reservations/{id}         bookId, reservedAt, pickupBy, pickupLocation, qrCode, status(ready|active|expiringSoon|completed|cancelled)
  ├ bookings/{id}             seatId, date, startTime, endTime, qrCode, status(active|…), checkedInAt
  ├ waitlist/{id}             type(book|seat), title, subtitle, position, joinedAt, estimatedWaitMinutes, seatPreference, status(waiting|offered)
  ├ notifications/{id}        title, body, timestamp, tone(info|success|warning|danger), iconCodePoint
  └ devices/{token}           token, platform, updatedAt
```
**ID/QR conventions:** reservations `BR-2026-1xx` + QR `LIB-BR-2026-1xx`; seat bookings `LIB-2026-485x` (QR == id). Staff verification runs a **collection-group query** `where('qrCode' == code)` across all users' bookings then reservations, joining owner name/ID from `users/{uid}`.

**App-side value objects:** `Book`, `Seat` (+`matchReasons`, `zoneLabel`), `BookReservation`, `SeatBooking`, `WaitlistEntry`, `AppNotification`, `QueueEntry`, `UserProfile` (+firstName), `NotificationPreferences`, `FloorOccupancy`, `FeatureHighlight`; enums `BookAvailability, SeatStatus, SeatCategory, WaitlistType, NotificationChannel, UserRole, ReservationStatus, QueueStatus, BannerToneKind`.

---

## 9. Key user journeys (end-to-end)

1. **Seat happy path:** Login → Home "Reserve a Seat" → Seat Map (Live pill) → Floor 2 → Quiet+Power chips → TOP PICK 2C ("Quiet · Power outlet · Near window") → Details → pick date + 10:00–12:00 slot → Reserve → P-08 success → QR pass → (staff scans → Valid → Confirm Check-in → student's Active Session live; second scan → Already checked in).
2. **Seat conflict:** two students reserve the same slot → Firestore transaction lets exactly one win → loser sees "Seat was just taken — pick another" → map refreshes occupied.
3. **Waitlist:** occupied 2C → Join waiting list (#2, ~45 min estimate) → seat cancelled elsewhere → promotion flips entry to offered + notification doc → **device notification** "Waitlist spot open" → feed deep-link.
4. **Book path:** Catalog → type "cle" (Title tab) → Clean Code card (Available · 3 copies) → Details (shelf B2-14) → RESERVE BOOK → confirmation w/ 7-day pickup deadline → appears in My Reservations → Books; cancel → confirm dialog (consequence) → receipt → copy freed → next waitlisted user offered.
5. **Auth:** cold start with session → splash → shell directly (restore); sign out → login.

---

## 10. Known gaps / backlog (explicit, for honest redesign scope)

1. Book waitlist join lacks the position screen (snackbar only) — seat-side is complete.
2. Notifications: no read/unread state, mark-all, deep links, or 24h/1h reminders yet (all specified in workloads, model fields exist).
3. Barcode banner in catalog is decorative (mobile_scanner already a dependency).
4. Book reserve lacks duplicate-guard + copy-count transaction.
5. Staff role is client-chosen at sign-in (production = custom claims); queue entries are seeded/provoked rather than student-initiated.
6. QR codes are static strings (signed tokens + `qrTokens/{nonce}` replay protection planned).
7. Home occupancy uses live seat data; per-slot availability is floor-level (shared across slots).
8. Staff-only visibility toggle is cosmetic.

---

## 11. Repo facts

- **Path:** `Library Mobile App`; branches: `feature/UI-mockup` (main line), `feature/damitha/seat-booking`.
- **Files:** 38 Dart files, ~11k lines; screens under `lib/features/{auth,home,books,seats,reservations,waitlist,notifications,qr,staff,account,settings}`.
- **Toolchain:** Flutter (stable, Dart 3), Android Gradle Plugin 9.1 / Kotlin 2.2.20 (pinned), `flutterfire configure` managed config (`firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`), `firebase.json` + deployed `firestore.rules`.
- **Quality gates:** `flutter analyze` clean; 28 widget tests incl. overflow-catching screen sweep at 1080×2400; release APK builds green (70MB).
- **Emulator:** Android AVD `Library_API36` (API 36, Play).
