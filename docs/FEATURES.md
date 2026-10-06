# Library+ Feature Catalogue

Status terms: **Implemented prototype**, **Partial**, **Planned**, or **Later**.

## 1. Authentication and onboarding

- Splash and session restoration — prototype splash exists; Firebase session restoration planned.
- Google sign-in — planned through Firebase Authentication and `google_sign_in`.
- Institution-domain restriction — planned and enforced in a callable function/profile bootstrap.
- Student/faculty profile creation — planned.
- Staff/admin role assignment — planned through trusted administration and custom claims.
- Email/password or institution SSO — optional later; do not present inactive buttons in production.
- Register screen — planned only if non-Google accounts are permitted.
- Terms, privacy consent, and notification permission education — planned.
- Sign-out and account removal request — sign-out prototype exists; deletion workflow planned.

Acceptance:

- Unauthenticated users cannot access protected data.
- A Google user receives exactly one profile document.
- Client input cannot grant staff/admin privileges.
- Blocked domains receive an actionable error without creating privileged data.

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

- Reserve an available copy — partial/mock.
- Atomic copy allocation and duplicate-prevention — planned backend transaction.
- Reservation confirmation and pickup deadline — implemented prototype; server authority planned.
- Active/history views — partial.
- Cancel with explicit consequence — implemented for books.
- Automatic expiry and next-waitlisted-user promotion — planned scheduled function.
- Secure pickup QR and staff verification — planned.

## 5. Seat discovery

- Visual floor map and status legend — implemented prototype.
- Floor, zone, power, monitor, window, accessibility, and group/quiet filters — partial.
- List alternative for accessibility and small screens — planned.
- Recommendation with a visible reason — partial; ranking logic planned.
- Live occupancy and stale timestamp — planned.
- Seat detail with distance/near-entrance information — planned.

## 6. Seat reservations

- Select date and time slot — planned; current prototype fixes the time.
- Atomic conflict checking — planned.
- Confirmation, QR pass, calendar export, and reminder scheduling — partial/planned.
- Cancellation with policy explanation — planned.
- Grace period, check-in deadline, no-show release, and strike policy — planned/configurable.
- Active session and early checkout — partial.

## 7. Waitlists

- Book and seat waitlists — partial; current state incorrectly treats all entries as seats.
- Preference-aware seat waitlisting — partial.
- Position, estimated wait, and status — partial/mock.
- Promotion offer with claim deadline — planned.
- Accept/decline offer and automatic next-user promotion — planned.
- Push notification and deep link to claim — planned.

## 8. QR and camera

- Student QR display for seat check-in — implemented prototype.
- Book pickup QR — planned.
- Staff camera scanner — planned; current scanner is simulated.
- Permission education, denied/permanently-denied recovery, flashlight, camera switch, and manual-code fallback — planned.
- Server verification for validity, ownership, audience, location, expiry, nonce, and replay — planned.
- Valid, expired, cancelled, already-used, wrong-location, and malformed result states — planned.

## 9. Notifications

- In-app notification feed — implemented prototype.
- Read/unread state, categories, bulk mark-read, and deep links — planned.
- Push notifications through FCM — planned.
- Reminder-before-start, reminder-before-expiry, and waitlist updates — model exists; UI/backend planned.
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

- Dashboard, queue search/filter, and summary metrics — implemented prototype/mock.
- Camera scanner and verification result — planned.
- Book pickup and seat check-in workflows — planned.
- No-show confirmation, grace extension, cancellation, and manual override — planned with audit reason.
- Reservation lookup by reference/user/resource — planned.
- Occupancy and waitlist operations — planned.
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
