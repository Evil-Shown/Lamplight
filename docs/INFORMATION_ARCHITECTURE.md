# Information Architecture — Library App

> **Migration notice (2026-10-07):** This original Assignment-era screen checklist contains deleted file paths and an outdated primary navigation. Use [`README.md`](README.md), [`FEATURES.md`](FEATURES.md), [`UI_DESIGN.md`](UI_DESIGN.md), and [`HIGH_LEVEL_ARCHITECTURE.md`](HIGH_LEVEL_ARCHITECTURE.md) as the implementation source of truth. During the `go_router` migration, replace this file with generated/verified route documentation.

## Current canonical primary navigation

- Student: Home · Seats · Books · Bookings · Profile.
- Staff: Home · Seats · Catalog · Bookings · Staff.
- Waitlists are inside Bookings and feature flows, not a primary tab.

## Current replacement paths

- Unified reservations: `features/reservations/reservations_screen.dart`.
- Notification feed: `features/notifications/notifications_screen.dart`.
- Notification settings: `features/settings/settings_screen.dart`.
- Student QR display: `features/qr/qr_ticket_screen.dart`.
- Staff scanner: `features/staff/staff_scanner_screen.dart` (currently simulated).

Screen checklist mapped to functional requirements (FR01–FR19).

## Navigation

| Tab | Primary screens |
|-----|-----------------|
| Home | Dashboard, quick actions, active items |
| Books | Search → Detail → Confirm → My Reservations |
| Seats | Map/List → Detail → Confirm → My Bookings |
| Waitlist | Queue list, grace countdown |
| Account | Profile, privacy, accessibility, notification settings |

---

## Book module (FR01–FR07)

| Screen | File | FRs |
|--------|------|-----|
| Book search (title/author/subject/ISBN) | `features/books/book_search_screen.dart` | FR01 |
| Availability + shelf + due date | `features/books/book_detail_screen.dart` | FR02, FR03 |
| Reserve → confirmation | `features/books/reservation_confirmation_screen.dart` | FR04, FR05 |
| My active reservations | `features/books/my_reservations_screen.dart` | FR06, FR07 |

---

## Seat module (FR08–FR12)

| Screen | File | FRs |
|--------|------|-----|
| Visual seat map + list toggle | `features/seats/seat_map_screen.dart` | FR08, FR09 |
| Floor/section filters | `features/seats/seat_map_screen.dart` | FR09 |
| Seat attributes (power, quiet/group, distance) | `features/seats/seat_detail_screen.dart` | FR10, FR11 |
| Book seat → confirmation | `features/seats/booking_confirmation_screen.dart` | FR12 |
| My active bookings | `features/seats/my_bookings_screen.dart` | FR12 |

---

## Waitlist & no-show (FR13–FR15)

| Screen | File | FRs |
|--------|------|-----|
| Join waitlist (from book/seat detail) | Detail screens + snackbar | FR13 |
| Waitlist queue + position | `features/waitlist/waitlist_screen.dart` | FR13, FR14 |
| Grace-period countdown / auto-release UI | `waitlist_screen.dart`, `my_bookings_screen.dart` | FR15 |

---

## Notifications (FR16–FR18)

| Screen | File | FRs |
|--------|------|-----|
| Push / email / SMS toggles | `features/notifications/notification_settings_screen.dart` | FR16 |
| Reminder before start / expiry | `notification_settings_screen.dart` | FR17, FR18 |

---

## QR (FR19)

| Screen | File | FRs |
|--------|------|-----|
| Seat check-in scanner | `features/qr/qr_scan_screen.dart` | FR19 |
| Book pickup scanner | `features/qr/qr_scan_screen.dart` | FR19 |

---

## Account & NFRs

| Screen | File | NFRs |
|--------|------|------|
| Staff-only reservation visibility | `features/account/account_screen.dart` | NFR04, NFR05 |
| Large text + high contrast toggles | `features/account/account_screen.dart` | NFR06 |
| 48dp minimum tap targets | `core/constants/app_constants.dart` | NFR06 |

---

## Figma page structure (recommended)

When populating [Library UI](https://www.figma.com/design/UwmGSbPjOtHRDai9KnA02V/Library-UI):

1. **01 — Books** — Search, Detail, Confirm, My Reservations
2. **02 — Seats** — Map, List, Detail, Confirm, My Bookings
3. **03 — Waitlist** — List, Countdown states
4. **04 — Notifications** — Settings
5. **05 — QR** — Check-in, Pickup
6. **06 — Account** — Profile, Privacy, Accessibility
7. **07 — Prototypes** — Click-through flows for usability testing
