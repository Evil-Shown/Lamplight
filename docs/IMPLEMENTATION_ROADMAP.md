# Library+ Implementation Roadmap

## Phase 0 — Baseline and decisions

- Commit the staff dashboard layout fix; clean analyzer warnings.
- Freeze canonical name, campus wording, requirements, and Figma file.
- Archive/replace stale `UI-mockup.md` and update information architecture.
- Add CI for analyze/test/build.
- Establish dev/staging/prod Firebase projects and flavors.

Exit: clean baseline, green tests, approved architecture and UI direction.

## Phase 1 — Frontend foundation

- Add typed models, result/failure types, repositories, Riverpod, `go_router`.
- Add environment bootstrap, Crashlytics error boundary, localisation framework.
- Wrap current mock data in fake repositories.
- Preserve visual parity while removing direct `AppScope/MockData` access.

Exit: current prototype works through fake repositories with route/deep-link tests.

## Phase 2 — Authentication and security foundation

- Configure FlutterFire, Google Auth, profile bootstrap, custom claims, App Check.
- Implement student/staff guards and role-admin tooling.
- Add initial Firestore Rules and emulator tests.
- Add privacy/terms/support surfaces.

Exit: real sign-in, server-enforced roles, no client role escalation.

## Phase 3 — Catalogue and book reservations

- Firestore catalogue schema/seed or external sync.
- Search/indexing, details, due dates.
- Atomic reserve/cancel/expiry and active/history UI.
- Pickup QR contract and notifications.

Exit: FR01–FR07 production-complete.

## Phase 4 — Seats and time slots

- Libraries/floors/seats schema and real status stream.
- Complete filters, list mode, recommendation reason.
- Date/time slot UI and atomic conflict prevention.
- Cancellation, grace period, no-show release.

Exit: FR08–FR12 and seat portion of FR15 complete.

## Phase 5 — Waitlists and notifications

- Book/seat waitlist types, position/offer/claim/expiry.
- FCM registration, feed read state, deep links.
- Reminder settings and scheduled delivery.
- Optional email/SMS adapters after provider approval.

Exit: FR13–FR18 complete for in-app/push channels.

## Phase 6 — QR camera and staff operations

- Secure short-lived signed QR tokens.
- Camera permission flow and `mobile_scanner`.
- Server verification and all invalid states.
- Staff dashboard split, reservation lookup, no-show/override actions, audit.

Exit: FR19 and NFR04/NFR05 enforcement complete.

## Phase 7 — Quality and HCI validation

- Unit/widget/golden/emulator/integration suites.
- Accessibility and performance passes.
- Conduct Assignment 2 T1–T8 with at least five participants.
- Fill real metrics/issue log; implement evidence-backed refinements.

Exit: usability targets met; no critical/high defects.

## Phase 8 — Pilot and production

- Store configuration, release signing, legal/privacy disclosures.
- Monitoring, budgets, backups, runbooks, role operations.
- Closed beta then one-library pilot.
- Gradual production rollout and post-release review.

## Priority backlog

### P0 — correctness/security

- Firebase auth/roles/rules/App Check.
- Transactional reservations.
- QR verification and replay prevention.
- Seat cancellation bug and accurate resource status.
- Environment separation/release signing.

### P1 — required feature completeness

- Real slot selection, waitlist promotion, reminders/push.
- Camera scanner, invalid states, notification deep links.
- Accessibility and offline/error states.
- Requirement-traced automated tests.

### P2 — polish/scale

- Search service, email/SMS, multi-campus, admin portal.
- Personalised recommendations and richer analytics.

## Suggested team parallelisation

- Track A: foundation/auth/security.
- Track B: books/catalogue.
- Track C: seats/waitlist.
- Track D: notifications/QR/staff/testing.

All tracks share reviewed domain contracts, Firestore schema, design tokens, and CI. Avoid dividing work only by screens because backend invariants cross screen ownership.
