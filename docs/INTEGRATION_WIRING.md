# Lamplight Integration and Wiring Plan

## 1. Environment setup

Create `dev`, `staging`, and `prod` flavors with unique:

- Firebase project/app registrations.
- Android application ID and iOS bundle ID.
- App name/icon suffix.
- `firebase_options.dart`.
- App Check providers.
- OAuth client configuration.
- Deep-link domains and notification settings.

Run FlutterFire CLI per environment. Never commit service-account keys.

## 2. Package and platform wiring

### Flutter

Add Firebase core/auth/Firestore/Functions/Messaging/App Check/Analytics/Crashlytics/Performance/Remote Config, Google Sign-In, scanner, router, state management, serialization, connectivity/cache, and test dependencies.

### Android

- Replace `com.example.library_app`.
- Add release signing through secure CI secrets.
- Register SHA-1/SHA-256 for each environment.
- Add camera and notification permissions as required by SDK level.
- Configure intent filters for deep links.
- Add notification channel definitions/icons.
- Register Play Integrity/App Check.

### iOS

- Replace bundle ID and configure signing.
- Add Google reversed client ID/URL scheme.
- Add `NSCameraUsageDescription`.
- Configure push notifications, background modes, APNs key, and associated domains.
- Register App Attest/DeviceCheck.

## 3. Dependency wiring

Use providers/constructors:

```text
Firebase SDK clients
  -> remote data sources
  -> repository implementations
  -> use cases/controllers
  -> screen state/widgets
```

Tests override repositories with fakes. Widgets never access `FirebaseFirestore.instance` or `FirebaseFunctions.instance` directly.

## 4. Feature wiring order

### Authentication

Auth stream → profile bootstrap → claims/profile provider → router redirect → role-aware shell.

### Books

Search provider → book repository query → result state → detail stream → callable reserve → reservation route → notification listener.

### Seats

Library/floor provider → seat status stream → filters/recommendation → time-slot query → callable reserve → confirmation → QR eligibility.

### Reservations

Signed-in UID stream → grouped reservation queries → detail → callable cancel/check-out → optimistic busy state → authoritative stream update.

### Waitlist

Join callable → entry stream → offer notification/deep link → claim callable → reservation confirmation.

### QR

Owner requests display token → QR widget/refresh timer. Staff scanner decodes → verify callable → result screen → optional confirm callable.

### Notifications

FCM token refresh → device registration function/write → message handler → local banner/feed refresh → deep-link router.

## 5. Function result contract

All callable functions return:

```json
{
  "ok": true,
  "requestId": "opaque-id",
  "data": {},
  "serverTime": "timestamp"
}
```

Failures use stable codes such as:

- `unauthenticated`
- `permission-denied`
- `resource-unavailable`
- `reservation-conflict`
- `limit-reached`
- `outside-operating-hours`
- `qr-expired`
- `qr-replayed`
- `invalid-argument`

UI maps codes to localised copy. `requestId` is shown only for support/debugging.

## 6. Push/deep-link contract

FCM data payload:

```json
{
  "schema": "1",
  "type": "waitlist_offer",
  "entityId": "opaque-id"
}
```

Supported types include reservation confirmed/cancelled/expiring, seat start reminder, waitlist offer, pickup ready, and policy alert. The client fetches protected details after opening.

## 7. Remote Config

Suitable values:

- Feature visibility/rollout.
- Minimum supported app version.
- Non-security UI copy and maintenance banner.
- Analytics sampling.

Security/booking policy must remain server-enforced even if mirrored in Remote Config for display.

## 8. Local development

- Use Firebase Emulator Suite for Auth, Firestore, Functions, and Storage.
- Seed deterministic users, books, seats, reservations, and waitlists.
- Keep current `MockData` for pure widget tests.
- Provide scripts for emulator start, seed, test, and reset.
- Use fake camera token input for automated scanner tests.

## 9. External integrations

Define adapters for:

- Library-management/catalogue system.
- Email provider.
- SMS provider.
- Optional full-text search provider.

Each adapter has retry/backoff, idempotency, timeout, safe logging, and dead-letter/manual reconciliation strategy.

## 10. Wiring verification checklist

- Cold start signed out/signed in.
- Claims refresh changes role routes safely.
- Offline cached reads do not falsely confirm writes.
- Every push type opens the correct route from foreground/background/terminated state.
- Camera permissions work on first request, denial, permanent denial, and settings recovery.
- QR verification result matches server state under replay/expiry.
- Dev cannot access production and production builds cannot use emulator endpoints.
