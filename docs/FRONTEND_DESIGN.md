# Lamplight Flutter Frontend Design

## 1. Target structure

Adopt feature-first clean boundaries without overengineering:

- **Presentation:** screens, reusable widgets, route parameters, UI state.
- **Application:** controllers/notifiers and use cases.
- **Domain:** immutable entities, policies, repository interfaces, failures.
- **Data:** Firebase/local implementations, DTOs, mappers.

Recommended packages:

- `flutter_riverpod` for async state and dependency injection.
- `go_router` for routes, auth/role redirects, and deep links.
- `freezed`, `json_serializable`, `build_runner` for models.
- FlutterFire plugins: core, auth, Firestore, Functions, Messaging, App Check, Analytics, Crashlytics, Performance, Remote Config, Storage as needed.
- `google_sign_in`, `mobile_scanner`, `qr_flutter`, `permission_handler` only if scanner APIs do not cover permission UX.
- `shared_preferences` for non-sensitive UX settings and `flutter_secure_storage` only for app-owned sensitive values.

## 2. Application bootstrap

Bootstrap order:

1. Ensure Flutter binding.
2. Load environment/flavor config.
3. Initialise Firebase from generated options.
4. Activate App Check (debug provider only in dev).
5. Install Flutter/zone error handlers and Crashlytics.
6. Configure background FCM handler.
7. Load local preferences.
8. Run app; auth/router handles session destination.

Bootstrap failure must show a retryable full-screen error rather than hanging on splash.

## 3. Navigation

Use typed route names/paths:

```text
/login
/home
/books
/books/search
/books/:bookId
/reservations/:reservationId
/seats
/seats/:seatId
/bookings
/qr/:reservationId
/notifications
/settings
/staff
/staff/scanner
/staff/verification/:eventId
```

Redirect logic:

- No auth → `/login`.
- Auth without completed profile → profile bootstrap/loading.
- Staff route without staff/admin claim → safe Home + access-denied message.
- Notification deep link validates target availability before opening.

## 4. State ownership

- Auth provider exposes session, claims, profile, bootstrap/error states.
- Each feature has repository providers and focused async controllers.
- Firestore streams are converted to immutable domain objects.
- Form and animation state stays local to the widget.
- Avoid one global mutable `AppState`; it rebuilds unrelated features and mixes business rules with storage.

Use explicit UI states:

```text
initial | loading | data | empty | refreshing | offlineData | error
```

## 5. Repository interfaces

Define interfaces before Firebase implementations:

- `AuthRepository`
- `UserRepository`
- `BookRepository`
- `SeatRepository`
- `ReservationRepository`
- `WaitlistRepository`
- `NotificationRepository`
- `QrRepository`
- `StaffRepository`
- `PolicyRepository`

Keep `Fake*Repository` implementations backed by current `MockData` for unit tests, UI development, and deterministic demos.

## 6. Error handling

Map SDK exceptions to domain failures:

- Network unavailable
- Permission denied
- Unauthenticated/session expired
- Resource unavailable/conflict
- Reservation limit reached
- Invalid/expired/replayed QR
- Rate limited
- Unknown with support reference

Screens should never display raw Firebase exception strings. Mutations preserve entered data and expose retry only when safe/idempotent.

## 7. Offline behavior

- Firestore cache may show previously loaded books, seats, reservations, and notifications.
- Show “Offline” and last-updated timestamp.
- Do not claim a booking succeeded until callable function confirms.
- Do not queue conflict-sensitive reservations silently.
- Safe preference/read-state updates may retry when connectivity returns.
- QR verification requiring server authority shows “Cannot verify offline,” with a policy-defined manual fallback.

## 8. Authentication UI integration

- Listen to `authStateChanges`/`idTokenChanges`.
- Native Google sign-in obtains Google credentials, then signs into Firebase Auth.
- Refresh claims after staff role changes using token refresh.
- Store profile data separately from Auth identity.
- Never infer staff from email text or a client toggle.

## 9. Camera and QR frontend

- Add Android camera permission and iOS `NSCameraUsageDescription`.
- Explain purpose before requesting permission.
- Handle denied/permanently denied with Settings link.
- Use `mobile_scanner`; debounce scans and stop scanner while verifying.
- Parse only the outer token/version format locally; server decides validity.
- Never log scanned token contents.
- QR display refreshes short-lived token before expiry and handles screenshot/replay policy.

## 10. Notifications and deep links

- Request notification permission contextually, after explaining value.
- Save FCM tokens per device and update on refresh.
- Handle foreground messages with in-app banner and notification feed refresh.
- Background/tap messages route by stable `type` + entity ID, not arbitrary URLs.
- Remove tokens on sign-out if policy requires; server cleans invalid tokens after send failures.

## 11. Performance

- Use pagination and indexed queries.
- Select only necessary documents; avoid N+1 reads.
- Cache cover images with bounded disk/memory policy.
- Use const widgets, granular providers, and list item keys.
- Measure startup, search, seat map, and scanner with Flutter DevTools and Firebase Performance.
- Keep expensive filtering/ranking off the build method.

## 12. Accessibility and localisation

- Add `Semantics` to status-heavy controls and seat cells.
- Support text scaling and reduced motion.
- Put all user-facing strings into Flutter localisation resources.
- Use locale-aware dates/numbers; store timestamps in UTC.
- Do not concatenate translated sentence fragments.

## 13. Migration sequence

1. Add environment bootstrap, error boundary, and router.
2. Introduce domain models/repositories while retaining fake implementations.
3. Split auth and profile from `AppState`.
4. Migrate books, seats, reservations, waitlists, notifications, QR, then staff.
5. Replace `MockData` access in widgets with providers.
6. Add Firebase implementations and emulator integration tests.
7. Remove obsolete `AppScope`, stale models, and legacy `ledger_widgets.dart` naming after parity.

## 14. Frontend definition of done

- No direct Firebase calls from widgets.
- No client-side role or reservation authority.
- All routes work from cold-start deep links.
- Loading/error/offline/permission states exist.
- Screen-reader, text-scale, and small-device checks pass.
- Unit, widget, golden, and integration tests cover critical flows.
