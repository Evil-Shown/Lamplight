# Library+ App — Full UI & Architecture Audit

> Standalone brief describing the current state of the codebase and UI.
> Written so another engineer (or AI agent) can reason about the app and
> produce accurate change prompts without reading the source.

---

## 1. Project overview

- **App**: Library+ — university library book reservation & reading-room seat booking prototype ("SLIIT QUICK BOOK" portal branding, UNILAG/Campus Commons labels).
- **Stack**: Flutter 3.47 (stable), Dart 3.13, Material 3. Runs on web (Chrome), Windows desktop, Android, iOS.
- **Dependencies** (pubspec.yaml): `google_fonts ^6.2.1` (Inter), `intl ^0.19.0`, `qr_flutter ^4.1.0`, `cupertino_icons`. **No state-management package, no DI, no router package, no DB** — deliberately self-contained mock-data prototype.
- **Size**: ~31 Dart files under `lib/`, largest: `core/widgets/shared_widgets.dart` (~1,345 lines), `features/home/home_screen.dart` (~950), `features/seats/seat_map_screen.dart` (~640), `features/seats/seat_detail_screen.dart` (~560), `core/theme/app_theme.dart` (~540).
- **Quality gates**: `flutter analyze` — 0 issues; `flutter test` — 27 tests (2 suites) all passing.

---

## 2. Architecture

### 2.1 Layer map

```
lib/
├── main.dart                      # entry: runApp(const LibraryApp())
├── app.dart                       # root widget: state sync + MaterialApp
├── app_shell.dart                 # tab shell + floating glass nav bar
├── core/
│   ├── constants/app_constants.dart   # AppStrings, AppSpacing, touch targets
│   ├── state/app_state.dart           # AppState (ChangeNotifier) + AppScope
│   ├── theme/app_theme.dart           # AppColors, AppRadii, AppShadows,
│   │                                  #   AppGradients, AppText, AppTheme
│   └── widgets/
│       ├── app_frame.dart             # phone-width frame on wide screens
│       ├── ledger_widgets.dart        # splash, CampusMark, StatePill
│       └── shared_widgets.dart        # the design-system component library
├── data/mock/mock_data.dart       # MockData statics (books, seats, builders)
├── models/models.dart             # immutable model classes + enums
└── features/                      # one folder per feature, plain widgets
    ├── account/  auth/  books/  home/  notifications/  qr/
    ├── reservations/  seats/  settings/  staff/  waitlist/
    └── ... (24 screens total)
```

### 2.2 State management (hand-rolled, no packages)

- **`AppState extends ChangeNotifier`** (`core/state/app_state.dart`) is the single source of truth. Holds: `profile` (auth), `reservations`, `bookings`, `waitlist`, `notifications`, `queue`, `_seatStatus` (map of seat-id → status overrides after booking/cancelling), `preferences` (notification channels), `themeMode`.
- All mutations are methods on AppState (`reserveBook`, `cancelReservation`, `reserveSeat`, `cancelSeatBooking`, `checkIn`, `joinWaitlist`, `leaveWaitlist`, `approveQueueEntry`, `dismissQueueEntry`, `updatePreferences`, `setThemeMode`, `signIn`, `signOut`). Most also insert an `AppNotification` and call `notifyListeners()`.
- **`AppScope extends InheritedNotifier<AppState>`** exposes state down the tree:
  - `AppScope.of(context)` — subscribe (rebuild on change)
  - `AppScope.read(context)` — one-off read for callbacks
- Derived getters compute views: `activeReservations` (sorted by pickup deadline), `reservationHistory`, `todayBooking`, `unreadNotifications`, `books`, `seats` (mock seats merged with `_seatStatus` overrides).

### 2.3 App root & theme switching

- `app.dart` — `LibraryApp` owns one `AppState`. An `AnimatedBuilder` on the state wraps `MaterialApp` so that **before every rebuild** it syncs the global flag `AppColors.isDark = state.themeMode == ThemeMode.dark`. Then:
  - `theme: AppTheme.light()`, `darkTheme: AppTheme.dark()`, `themeMode: state.themeMode`
  - `builder:` wraps everything in `AppFrame`
  - `home: _AppEntry` → splash once (`AnimatedSwitcher`, 450 ms) → `_SignedInGate` → `AppShell` if signed in else `LoginScreen`
- **Dark-mode mechanism (important quirk):** `AppColors` members are **static getters, not const values**. Each returns the light or dark variant depending on `AppColors.isDark`. Because colors resolve at build time from a mutable global, screens keep the same `AppColors.x` syntax in both themes — the trade-off is that **colors can never appear inside `const` expressions** (const constructors referencing AppColors will not compile). The Settings screen has a Light/Dark toggle; system mode is not offered.

### 2.4 Navigation

- **No named routes / go_router.** Two patterns only:
  1. **Bottom tab shell** — `AppShell` (`app_shell.dart`): `IndexedStack` of 5 tab screens + a custom floating nav bar. Tabs are role-aware:
     - Student: `Home · Seats · Books · Bookings · Profile` → HomeScreen, SeatMapScreen, BookSearchScreen, ReservationsScreen, AccountScreen
     - Staff: `Home · Seats · Catalog · Bookings · Staff` → StaffDashboardScreen, SeatMapScreen, BookSearchScreen, ReservationsScreen, StaffDashboardScreen
  2. **`Navigator.push(MaterialPageRoute(...))`** for every drill-in screen (detail, confirmation, settings, waitlist, QR, staff scanner…).
- Cross-tab jumps use the static `AppShell.switchTab(context, AppTab.bookings)` helper.
- Page transitions are a custom `_SoftPageTransitionsBuilder` (fade + 3% upward slide, easeOutCubic) registered for all platforms.
- `AppFrame` centers the app in a 430 pt phone column with a border and shadow on wide screens (web/desktop).

### 2.5 Data layer

- `models/models.dart` — immutable classes with `copyWith` where needed: `Book` (id, title, author, subject, isbn, availability, shelfLocation, copiesAvailable, coverColor ARGB int), `Seat` (label, floor, section, status, category, power/monitor/window/standingDesk flags, row/col for the 4×4 grid, `zoneLabel` getter), `SeatBooking`, `BookReservation`, `WaitlistEntry`, `AppNotification`, `QueueEntry`, `UserProfile` (name/studentId/email/role), `NotificationPreferences`.
- Enums: `BookAvailability {available, onLoan, waitlisted}`, `SeatStatus {available, limited, occupied}`, `SeatCategory {quietZone, collaborative, individualPod}`, `ReservationStatus`, `WaitlistType`, `NotificationChannel`, `UserRole {student, staff}`.
- `data/mock/mock_data.dart` — `MockData.books` (7 titles incl. Clean Code, Pragmatic Programmer, Atomic Habits…), `MockData.seats` (16, 4×4), builder functions for reservations/bookings/waitlist/notifications/queue, `floorOccupancy` (per-floor density for the home meter bars), `student` and `staff` profiles. Book covers load from OpenLibrary by ISBN with a generated gradient "spine plate" fallback.

---

## 3. Design system (`core/`)

### 3.1 Color (`AppColors`)

- **Light (default)**: cool off-white page `#F4F6FC`, white surfaces, hairline borders `#E6EAF4`, one confident blue `#1A56DB` (brand), violet accent `#6D5BF5`, cyan `#12B5CE`, gold `#D9A441`. Text: near-black `#0C1526` / slate `#56657F` / faint `#94A3B8`. Status: green `#16A34A`, amber `#E8890C`, red `#DC2626`, each with a soft tinted background (`successSoft` etc.).
- **Dark**: deep navy canvas `#0B1120`, surface `#141D31`, lifted primary `#4C82E8`, lighter text `#EDF2FB`, borders `#24304A`, dark-soft status tints.
- Seat-map semantic colors: `seatAvailable` green, `seatLimited` amber, `seatOccupied` red, `seatSelected` blue.
- `coverPalette`: 8 fixed ARGB ints hashed by title to generate book-cover plates.

### 3.2 Shape, shadow, gradient

- `AppRadii`: xs 8 / sm 12 / md 16 / lg 20 / xl 28 / full (pill).
- `AppShadows`: `card` (soft 12 blur), `raised` (two-part 18+36 blur), `layered(tint)` (colored bloom + neutral drop — what makes featured cards read as layered), `glow(tint)` (ambient bloom for primary actions/selected states), `primary`.
- `AppGradients`: `brand`, `hero` (dark panel), `aurora` (signature blue→violet sweep used on hero cards and the QR tile), `auroraSoft` (light tint), `mint`, `panel` (deep navy for staff/dark surfaces), `tint(color)`, `cover(base)` (vertical book-cover gradient with highlight/shadow stops).

### 3.3 Typography (`AppText`)

Single family — **Inter** via google_fonts — one factory per role: `display(size, w700-800, tight ls)`, `title(600-700)`, `body(400)`, `label(600)`, `overline` (uppercase, wide letter-spacing, faint grey). Hierarchy is carried by weight/size only.

### 3.4 Component library (`shared_widgets.dart`)

Every screen composes from these; there is essentially no ad-hoc styling:

| Component | Role |
|---|---|
| `AppScaffold` | standard chrome: centered title, back chevron, `bottomBar` slot |
| `SurfaceCard` | white rounded card, hairline border; `tint` → colored layered shadow; `gradient`, `elevated`, `onTap` (wraps in PressScale) |
| `GradientHero` | gradient panel with a slow shimmer sheen sweep (4.2 s loop, respects `disableAnimationsOf`) — used for today's session, seat hero |
| `SectionLabel` / `SectionHeader` | uppercase grey overline; header with optional right action |
| `StatusPill` | tinted pill, optional icon or `_PulseDot` (1.1 s pulsing opacity) |
| `Callout` (+`CalloutTone`) | tinted info/success/warning/danger message block |
| `EmptyState` | icon circle + headline + optional CTA |
| `FilterChipRow` | horizontal pill chips w/ icons |
| `SegmentedTabs` | sunken track + sliding white thumb |
| `BottomActionBar` | sticky bordered bottom bar with SafeArea |
| `PrimaryButton` (+`ButtonTone`) | 52 pt full-width button, primary/secondary/danger/neutral |
| `SettingRow`, `IconBadge`, `InfoRow` | settings rows, icon squares, label/value rows |
| `BookCover` | OpenLibrary cover image w/ generated plate fallback + `heroTag` for Hero flights |
| `MeterBar` | animated rounded progress (density bars) |
| `StatTile` | staff dashboard stat cards with `CountUp` |
| `Skeleton` / `SkeletonCard` | shimmering placeholder blocks |
| `SuccessCheck` | spring-in check circle for success screens |
| `StaggeredEntrance` | index-based fade+lift entrance (55 ms step) |
| `PressScale` | scale-down-on-press feedback + light haptic |
| `CountUp` | number count-up animation |
| `Haptics` | tap / selection / success / danger impact vocabulary |

`ledger_widgets.dart` adds `CampusMark` (rounded gradient "L" mark), the animated splash, and `StatePill` (check-in "STATE: VERIFIED" style pill).

---

## 4. Current UI, screen by screen

### Home tab (`features/home/home_screen.dart`) — **dark hero dashboard** (Stitch redesign)
- Always-dark navy canvas (`#0A0F1E`) regardless of theme mode; status-bar forced light.
- Header: gradient avatar circle w/ initials, "CAMPUS COMMONS" overline + "Home." title, circular bell button with unread badge.
- "ONLINE CAMPUS · MAIN LIBRARY" status pill (green dot).
- Time-aware greeting ("Good morning, {firstName}") + subtitle.
- **Today's session hero**: `GradientHero` aurora panel — "TODAY'S STUDY SESSION" overline, Confirmed pill, seat label at 32 pt, floor/section, facility pills (`FREE POWER` green-highlight, `FAST WI-FI`, `DAYLIGHT`), time range + "Starts in Xm" chip.
- **Quick actions** 2×2: dark glass tiles (`#151D33`, border `#232D48`) with tinted icon squares (Search books / Reserve a seat / My bookings) + **QR check-in** tile in blue gradient (highest-contrast action).
- **Ready for collection**: card w/ book cover, amber "Due {date}" chip, days-left counter, green-dot "Ready for pickup · Shelf {loc}".
- **Noise-level card**: "Silent Room & Study Wing", "32 dB · Quiet study zone", determinate progress bar at 0.32, "Live" chip.
- The **floating nav bar flips to dark-glass styling while the Home tab is active** (white 6% fill, white borders, `primaryBright` tint for selected).

### Seats tab — Seat map (`features/seats/seat_map_screen.dart`)
- AppBar-less custom header: "CAMPUS COMMONS" overline + "Seat Reservation" title.
- Headline "Find and reserve your ideal study spot".
- `_ZonePicker` card: icon square, "ZONE SELECTION" overline, "Floor N · M desks", floor dropdown.
- Filter chips: Quiet Area / Power Outlets / Dual Monitors (wired to `SeatFilters`; sheet has more).
- Availability line ("N of M seats available") + Filters button opening `SeatFilterSheet` (modal bottom sheet).
- `SegmentedTabs` Map/List view switch.
- **Recommended card**: aurora-soft gradient, auto_awesome icon, "Recommended for most students" + seat label + match reasons + filled "Select" pill button.
- **Map view**: `SurfaceCard` with the **4×4 circular seat grid** — gradient-filled circles, white labels, power-dot indicator, selected seat glows; footer "ENTRANCE · STAIRWELL A". Legend with live counts (Available (n) / Limited / Full / Selected).
- **List view**: compact rows with status pills.
- Selecting a seat reveals a sticky `BottomActionBar`: left column "Seat {label} · Selected · today", right **Continue →** button → pushes `SeatDetailScreen`.

### Seat detail (`features/seats/seat_detail_screen.dart`)
- `GradientHero` seat card: "FLOOR N · ZONE" overline, seat label 30 pt, "Single desk · quiet zone" subtitle, availability pill (+ "Dual 4K monitors" pill if applicable).
- **Zone strip**: 3 mini cards (Quiet Wing / Power Wing / Panel Hub) — the seat's own zone highlighted.
- "Renting time" card: date row ("Today, d MMM yyyy") + Change → date picker (today +14 days).
- **Time-slot list**: full-width selectable rows with radio check, label, gold "MOST POPULAR"/"POPULAR" badges, availability notes ("2 of 20 desks left"); past slots disabled.
- **Amenities checklist** (green checks): desk lamp, lumbar mesh chair, acoustic partition, + conditional dual 4K monitors / standing desk / 65W USB-C power.
- Info callout: "Freshly serviced in 5 min".
- Bottom bar: "Selected {slot}" caption + **Reserve Seat {label}** (or "Join waiting list" when occupied → `WaitlistScreen`). Reserving calls `reserveSeat(seat, start:, end:)` → pushes `BookingConfirmationScreen`.

### Books tab — Library Catalog (`features/books/book_search_screen.dart`) (Stitch redesign)
- "CAMPUS COMMONS / Library Catalog" header + green "LIVE CATALOG" pill.
- "Find a Book" display heading + subtitle.
- Rounded search field (live filtering as you type).
- `SegmentedTabs`: Title / Author / ISBN / Category.
- "{n} Books Found" + static "Relevant ▾" sort chip.
- **Result cards**: book cover (Hero tag `book-{id}`), title, author · subject, availability pill (Available/On Loan/Waitlist), "Shelf {loc}", two actions — outlined **View Details** and filled **Reserve Copy** (or muted **Join Waitlist** when unavailable). Reserve → `reserveBook` → `ReservationConfirmationScreen`.
- "View all N results" → pushes `SearchResultsScreen` (skeleton-loading list → results, hero flight into `BookDetailScreen`).
- **Barcode Scanner banner**: dark panel, scan icon, "Scan a physical copy to find it on the shelf" → opens full results.

### Bookings tab (`features/reservations/reservations_screen.dart`)
- Segmented Active/History tabs; active reservation cards (cover, status pills, pickup deadline) → reservation detail / QR-linked flows; cancel flow → `ReservationCancelledScreen`.

### Profile tab (`features/account/account_screen.dart`)
- Profile header, settings entry → **Settings screen**: notification-channel switches (Email/SMS/Push), **Appearance section with Light/Dark theme picker** (animated segmented pill w/ glow), language/help/about rows ("About App" → `ValuePropositionScreen`).

### Other flows
- **QR**: `QrTicketScreen` (qr_flutter pass for a booking), `ActiveSessionScreen` (checked-in state w/ StatePill + ledger widgets).
- **Waitlist**: `WaitlistScreen` (join with seat preference) → `WaitlistJoinedScreen` (queue position, CountUp).
- **Staff**: `StaffDashboardScreen` (dark panel stats w/ StatTile+CountUp, live queue approve/dismiss, scanner entry), `StaffScannerScreen` (viewfinder overlay w/ corner brackets), `VerificationResultScreen`.
- **Auth**: `LoginScreen` — campus mark, identifier field, role toggle (student/staff), sign-in → shell.
- **Notifications**: `NotificationsScreen` — list of AppNotification entries generated by state mutations.

---

## 5. Motion & interaction feel

- **Entrances**: `StaggeredEntrance` on nearly every card/list item (55 ms stagger, 14 px lift, easeOutCubic).
- **Press**: `PressScale` (0.975 scale, 130 ms) + `Haptics.tap()` on every card/chip; `selectionClick` on tabs/segments/toggles; medium impact on success flows.
- **Ambient**: shimmer sheen sweep across `GradientHero`s; `_PulseDot` in live pills; `CountUp` on stats; `MeterBar` fill tween (800 ms).
- **Transitions**: custom soft fade+slide page route; `AnimatedSwitcher` splash handover; `InkSparkle` splash factory globally.
- **Accessibility**: all motion respects `MediaQuery.disableAnimationsOf`; nav destinations have Semantics; 48 pt touch-target constant defined.

---

## 6. Testing

- `test/screen_sweep_test.dart` — renders **21 screens** at real phone size (1080×2400 @3.0) inside `AppScope+MaterialApp`, pumps fixed frames (infinite animations prevent `pumpAndSettle`), forwards FlutterErrors (records RenderFlex overflows and fails on any), asserts no exceptions. This is the layout regression net.
- `test/widget_test.dart` — splash→login handover, student shell navigation labels, staff shell swap, `reserveBook` state mutation, theme primary color check.
- Both suites rely on mock data only; no network (OpenLibrary covers fail gracefully to generated plates in tests).

---

## 7. Known constraints / quirks (worth telling any agent)

1. **Colors are runtime getters** — never put `AppColors.x` inside `const` constructors; the codebase is formatted so `dart fix` + analyze catch violations.
2. **Home tab is intentionally always dark** — it hardcodes its own dark palette (local `Color(0xFF0A0F1E)` etc.) instead of `AppColors`, and the shell nav bar receives `dark: index == AppTab.home`.
3. **Theme = Light/Dark toggle only** (no system option); synced via global `AppColors.isDark` in `app.dart` before `MaterialApp` builds.
4. **State is app-global mock data** — refresh resets; no persistence.
5. **`AppFrame` phone column** — all screens assume ≤430 pt width; the sweep test enforces no overflow at 360 logical px, which is why several texts use `Flexible + ellipsis`.
6. **Static-false `Timezone` note** — slot availability strings ("2 of 20 desks left") are presentational mocks, not computed from data.
7. **Stitch design source**: `stitch/screens/*.png` (4 mockups: home dashboard, seat map, seat details, book search) are the design references the current UI implements; the downloaded HTML files were auth-gated and deleted.
