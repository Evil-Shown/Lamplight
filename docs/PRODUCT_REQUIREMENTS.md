# Library+ Product Requirements

## 1. Purpose

Library+ is a mobile-first system for discovering and reserving library books, finding and booking reading-room seats, joining waitlists, receiving reminders, and checking in with QR codes. It also gives authorised library staff tools to verify reservations, manage no-shows, and monitor demand.

This specification combines:

- Assignment 1 user research and requirements.
- Assignment 2 prototype, interaction flows, and usability plan.
- The current Flutter implementation on `feature/UI-mockup`.
- Production requirements needed for Firebase, security, camera scanning, notifications, and release.

## 2. Research basis

Use these findings to resolve product trade-offs:

- 57.3% of 119 respondents had failed to find a wanted book.
- About 60% experienced seat scarcity at least sometimes.
- Faster book reservation was the strongest adoption driver.
- Users preferred automatic seat recommendations and floor/area filters over a raw list.
- App, SMS, and email confirmation preferences were nearly evenly split.
- Users preferred explicit cancellation confirmation and a grace period over immediate forfeiture.
- Waitlisting was the preferred response when no seat was available.
- QR seat check-in was the most requested QR feature.

Known source inconsistencies are documented in `DECISIONS.md`; production planning uses 119 responses as the canonical research sample.

## 3. Users and roles

### Student / faculty member

Can search the catalogue, view availability, reserve books, browse and reserve seats, join waitlists, manage reservations, display QR passes, receive notifications, and manage personal preferences.

### Library staff

Can perform all relevant catalogue and seat tasks plus scan QR passes, verify pickups/check-ins, manage no-shows, inspect queues, and update operational status. Staff access must be enforced server-side.

### Administrator

Manages staff roles, library locations, floors, seats, policy values, catalogue synchronisation, notification templates, and audit review. Administration may initially use Firebase Console or a later web portal.

### IT support

Maintains environments, credentials, monitoring, backups, incident response, and release infrastructure. IT support does not automatically receive access to personal reservation data.

## 4. Product principles

1. Show availability before asking users to commit.
2. Keep common tasks reachable in three primary actions or fewer from Home.
3. Never use colour as the only status signal.
4. Confirm consequential actions and explain their result.
5. Treat the backend as authoritative for availability, roles, QR validity, and time.
6. Prefer secure, expiring tokens over IDs embedded directly in QR codes.
7. Remain useful under slow or temporarily unavailable networks.
8. Preserve privacy: users see their own records; staff see only what their role needs.

## 5. Functional requirements

The assignment requirements remain canonical:

- **FR01–FR04:** catalogue search by title, ISBN, author, and subject; availability and relevant details.
- **FR05–FR07:** reserve books, display active reservations, and confirm successful reservations.
- **FR08–FR10:** display seats and attributes, filter by preference, and recommend suitable seats.
- **FR11–FR12:** reserve seats for a selected date/time and confirm the reservation.
- **FR13–FR15:** join waitlists; notify users when capacity becomes available; support cancellation, grace periods, and expiry.
- **FR16–FR18:** reminders, confirmations, and status-change notifications through configured channels.
- **FR19:** QR-based seat check-in and staff verification.

Production extensions:

- Real Google sign-in and optional institution-domain restriction.
- Server-enforced student/staff/admin roles.
- Device registration and push notification handling.
- Book pickup QR support in addition to seat check-in.
- Read/unread notification state and deep links.
- Reservation conflict prevention and idempotent operations.
- Audit records for staff actions and QR verification.
- Configurable operating hours, slot lengths, grace periods, and reservation limits.
- Account deletion/data-export workflow where policy requires it.

## 6. Non-functional requirements

- **NFR01 Usability:** clear language, consistent navigation, visible feedback, and usability-test targets from Assignment 2.
- **NFR02 Performance:** cached first paint; common reads target p95 under 2 seconds on normal mobile networks; transactional actions target p95 under 3 seconds.
- **NFR03 Reliability:** Firestore transactions or callable functions prevent double booking and stale inventory writes.
- **NFR04 Authorisation:** custom claims and Firestore Rules restrict staff/admin operations.
- **NFR05 Privacy:** least privilege, encrypted transport/storage, minimal personal data, auditable privileged access.
- **NFR06 Accessibility:** WCAG 2.1 AA intent, scalable text, semantic labels, 48dp targets, sufficient contrast, reduced-motion support.
- **NFR07 Availability:** monitored Firebase services, graceful degradation, documented incident recovery, and production backups/export strategy.

Additional quality targets:

- Crash-free sessions above 99.5%.
- No known high-severity security-rule findings at release.
- At least 80% task completion and mean SEQ at least 5.5/7 in moderated usability tests.
- Zero duplicate active reservations for the same resource/time slot.

## 7. Scope

### Minimum viable production release

- Google authentication, profile bootstrap, roles, and sign-out.
- Book search/detail/reserve/cancel/pickup state.
- Seat map/filter/recommend/reserve/cancel/check-in.
- Unified reservations and waitlist views.
- Secure QR generation and staff camera scanning.
- In-app and push notifications.
- Firebase Rules, App Check, Cloud Functions, Crashlytics, Analytics, and Emulator tests.
- Accessibility, offline/error states, privacy information, and store-ready configuration.

### Later phases

- SMS/email providers, institution SSO, personalised recommendations, indoor navigation, web administration portal, advanced reporting, multi-campus support, and integration with an existing library-management system.

## 8. Explicit non-goals for the first release

- Replacing the institution's full library-management system.
- Storing payment details.
- Fully offline booking or check-in.
- Allowing client applications to directly assign staff/admin roles.
- Claiming real-time accuracy without a source-of-truth catalogue/seat integration.

## 9. Success metrics

- Search-to-reservation completion rate.
- Seat recommendation acceptance rate.
- Median time to find and reserve a seat.
- No-show rate before and after QR/grace-period enforcement.
- Waitlist conversion rate.
- Notification delivery/open rate by channel.
- QR verification success/failure and fraud/replay rejection counts.
- Task success, errors, assistance, time-on-task, and SEQ from Assignment 2 tasks T1–T8.

## 10. Definition of done

A feature is complete only when it has:

1. Approved UX states: loading, empty, error, offline, success, and permission denial.
2. Domain model, repository, backend contract, security rules, and audit implications.
3. Unit/widget/integration/rules tests.
4. Analytics and operational observability where appropriate.
5. Accessibility review and text-scale testing.
6. Documentation and acceptance criteria updated.
7. Successful staging verification on physical Android and iOS devices.
