# Lamplight Feature Catalogue

Status terms: **Implemented prototype**, **Partial**, **Planned**, or **Later**.

## 1. Authentication and onboarding

- Splash and session restoration — **implemented** (Firebase Auth session restored on cold start).
- Email/password sign-in with automatic account provisioning — **implemented** (`@sliit.lk` domain, auto-creates the auth user and `users/{uid}` profile on first sign-in).
- Institution-domain restriction — partial; identifier is normalised to `@sliit.lk` client-side.
- Student/faculty profile creation — **implemented** (Firestore `users/{uid}` bootstrap).
- Staff/admin role assignment — prototype (role chosen at sign-in; production should use custom claims).
- Register screen — not needed; first sign-in provisions the account.
- Terms, privacy consent, and notification permission education — notification permission prompt implemented.
- Sign-out and account removal request — sign-out **implemented** (revokes session and tears down listeners).

Acceptance:

- Unauthenticated users cannot access protected data (enforced by `firestore.rules`).
- A user receives exactly one profile document (`users/{uid}`).
- Blocked domains receive an actionable error.

## 2. Home

- Greeting and role-aware dashboard — implemented prototype.
- Current seat session, book pickup, queue, and occupancy summary — partial/mock.
- Quick actions for books, seats, QR, reservations, and notifications — partial.
- Real-time campus/floor occupancy — planned.
- Offline/stale-data indicator — planned.

## 3. Book discovery

- Search by title, author, ISBN, and subject — implemented prototype.
- Recent/popular searches and category browsing — partial.
- Availability, copy count, shelf, description, and expected return — due-date data planned.
- Cover image with deterministic fallback and caching — partial.
- Pagination and search indexing — planned; use Algolia/Typesense if Firestore prefix search becomes insufficient.
- Catalogue synchronisation with source library system — integration-dependent.

## 4. Book reservations and pickup

- Reserve an available copy — **implemented** (persisted to `users/{uid}/reservations`).
- Atomic copy allocation and duplicate-prevention — partial (client-side copy count; backend transaction for seats exists).
- Reservation confirmation and pickup deadline — **implemented** (7-day pickup window, server-persisted).
- Active/history views — **implemented** (live Firestore feed).
- Cancel with explicit consequence — **implemented**; cancellation offers the copy to the next waitlisted user.
- Automatic expiry and next-waitlisted-user promotion — partial (promotion on cancel implemented; scheduled expiry is a Cloud Function, planned).
- Secure pickup QR and staff verification — **implemented** (QR pass + staff collection-group lookup verification).

## 5. Seat discovery

- Visual floor map and status legend — implemented prototype.
- Floor, zone, power, monitor, window, accessibility, and group/quiet filters — partial.
- List alternative for accessibility and small screens — planned.
- Recommendation with a visible reason — partial; ranking logic planned.
- Live occupancy and stale timestamp — planned.
- Seat detail with distance/near-entrance information — planned.

## 6. Seat reservations

- Select date and time slot — **implemented** (date picker + time slots persisted to Firestore).
- Atomic conflict checking — **implemented** (Firestore transaction: seat flips to `occupied` only while `available`; losing racers are reverted).
- Confirmation, QR pass, calendar export, and reminder scheduling — partial (confirmation + QR pass implemented; calendar export planned).
- Cancellation with policy explanation — **implemented**; releases the seat and promotes the next waitlisted user.
- Grace period, check-in deadline, no-show release, and strike policy — planned/configurable.
- Active session and early checkout — **implemented** (live session state synced to Firestore).

## 7. Waitlists

- Book and seat waitlists — **implemented** (`users/{uid}/waitlist` in Firestore).
- Preference-aware seat waitlisting — **implemented**.
- Position, estimated wait, and status — **implemented** (live position from join order).
- Promotion offer with claim deadline — **implemented** (on cancellation the first waiting user is flipped to `offered` and notified).
- Accept/decline offer and automatic next-user promotion — partial (offer notification delivered; accept/decline UI planned).
- Push notification and deep link to claim — **implemented** (notification document written to the promoted user's feed → device notification).

## 8. QR and camera

- Student QR display for seat check-in — **implemented**.
- Book pickup QR — **implemented**.
- Staff camera scanner — **implemented** (`mobile_scanner` live camera with branded viewfinder; manual-code fallback).
- Permission education, denied/permanently-denied recovery, flashlight, camera switch — partial (fallback state shown; flashlight/camera switch planned).
- Server verification for validity, ownership, audience, location, expiry, nonce, and replay — partial (validity, ownership, and state verified server-side via collection-group query; nonce/replay planned).
- Valid, expired, cancelled, already-used, wrong-location, and malformed result states — **implemented** (valid / already checked-in / cancelled / expired / completed / not-recognised).

## 9. Notifications

- In-app notification feed — **implemented** (live Firestore feed).
- Read/unread state, categories, bulk mark-read, and deep links — partial (feed implemented; read-state planned).
- Push notifications through FCM — **implemented** (FCM permission prompt, token registration under `users/{uid}/devices`, foreground push display).
- Reminder-before-start, reminder-before-expiry, and waitlist updates — partial (waitlist offers delivered as device notifications; scheduled reminders planned).
- Email/SMS channels — later/provider-dependent.
- Quiet hours and timezone-aware delivery — planned.

## 10. Profile and settings

- Identity card and role — implemented prototype.
- Notification preferences — partial.
- Accessibility settings: large text guidance, reduced motion, high contrast/system settings — planned.
- Language/localisation — planned after English production release.
- Privacy, export/delete request, support, legal links, app version — planned.
- Staff-only visibility switch — current no-op; replace with a clearly defined privacy policy or remove.

## 11. Staff operations

- Dashboard, queue search/filter, and summary metrics — **implemented** (queue synced from Firestore for staff).
- Camera scanner and verification result — **implemented** (real camera + Firestore verification).
- Book pickup and seat check-in workflows — **implemented** (`consumeVerifiedCode` persists check-in/collection).
- No-show confirmation, grace extension, cancellation, and manual override — planned with audit reason.
- Reservation lookup by reference/user/resource — **implemented** (lookup by reservation code).
- Occupancy and waitlist operations — partial (live occupancy from seat status; waitlist ops via promotion).
- Admin-only configuration and role management — later web portal.

## 12. Cross-cutting platform features

- Offline read cache and retry queue for safe idempotent actions.
- Pull-to-refresh and last-updated labels.
- Global error mapping and support reference IDs.
- Remote Config for policy values and feature flags.
- Analytics events with no sensitive QR payloads or personal search content.
- Crashlytics and Performance Monitoring.
- App Check and abuse/rate controls.
- Deep links from push notifications.
- Responsive Android/iOS layout and optional web read-only support.

## 13. Requirement traceability

- FR01–FR04: Book discovery.
- FR05–FR07: Book reservation/pickup.
- FR08–FR10: Seat discovery.
- FR11–FR12: Seat reservation.
- FR13–FR15: Waitlists, cancellation, expiry, and no-shows.
- FR16–FR18: Notifications and reminders.
- FR19: QR check-in and verification.
- NFR01–NFR07: addressed across UI, architecture, security, testing, and operations documents.

Detailed acceptance scenarios belong in `TESTING_QA.md`; implementation order is in `IMPLEMENTATION_ROADMAP.md`.
