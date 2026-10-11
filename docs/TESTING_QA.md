# Lamplight Testing and Quality Plan

## 1. Test pyramid

### Unit tests

- Domain status transitions and policies.
- Seat overlap and slot calculations.
- Recommendation ranking.
- Search normalisation/filtering.
- Date/time and operating-hours logic.
- DTO mapping and error mapping.
- QR outer-format parsing (not cryptographic authority).
- Controllers with fake repositories.
- Cloud Function validators, transactions, notification selection, waitlist promotion, and expiry.

### Widget tests

- Every screen: loading, data, empty, error, offline, and permission states.
- Navigation actions and form validation.
- Student/staff shells and route guards.
- Cancellation confirmation and disabled/busy actions.
- Text scaling and narrow viewport overflow.
- Scanner permission/result UI using fake scanner controller.

### Golden tests

Critical screens at reference sizes:

- Login, Home, book results/detail.
- Seat map/detail/filter sheet.
- Reservations, QR pass, notification feed.
- Staff dashboard/scanner/results.
- Error, empty, and offline components.

Use stable fonts/assets and deliberately approve visual changes.

### Firebase Emulator tests

- Firestore Rules ownership/role matrix.
- Functions with Auth/App Check context.
- Reservation conflicts and idempotency.
- Waitlist promotion and expiry.
- Notification record creation.
- QR valid/expired/replayed/wrong-role cases.
- Index-backed queries and seed scripts.

### Integration tests

- Google auth through a test strategy/fake where provider automation is impractical.
- Book search → reserve → reservations → cancel.
- Seat filter → slot → reserve → QR → staff verify → active session.
- Full seat → waitlist → offer → claim.
- Push payload → cold-start deep link.
- Sign-out clears protected UI/cache.

Run physical-device smoke tests for camera, push, Google auth, and deep links.

## 2. Assignment usability tests

Retain Assignment 2 tasks T1–T8:

- Find quiet/power seat.
- Reserve selected seat/time.
- Join waitlist.
- Search and reserve HCI book.
- Find/cancel reservation.
- Interpret notification.
- Open/explain QR pass.
- Staff scan/verify.

Targets:

- At least 80% successful completion.
- No moderator assistance.
- At most one wrong action per task.
- Mean SEQ at least 5.5/7.

Do not invent results. Record anonymised participants, consent, completion, timing, errors, assistance, SEQ, issue severity, recommendations, and links to approved recordings.

Fix the test-data mismatch: seed the exact HCI title used in T4 and make it reservable for the usability scenario.

## 3. Requirement acceptance

- FR01–FR04: search modes return correct results and details include availability/shelf/due information.
- FR05–FR07: atomic reserve, visible active reservation, confirmation.
- FR08–FR10: current seats, usable map/list, preference filters and explainable recommendation.
- FR11–FR12: selectable valid slot, no double booking, confirmation.
- FR13–FR15: join, offer/notify, claim/expire/cancel/no-show.
- FR16–FR18: configured reminders/confirmations/status updates and feed/deep link.
- FR19: valid scan succeeds; invalid, expired, cancelled, replayed, wrong-location tokens fail safely.

NFRs are verified through usability, performance, Rules/security tests, accessibility checks, and operational exercises.

## 4. Accessibility QA

- Android TalkBack and iOS VoiceOver manual pass.
- Automated semantics inspection where possible.
- Text scale 100–200%.
- Contrast checks.
- Switch control/keyboard navigation.
- Reduced-motion setting.
- Camera flow accessible fallback via manual code.
- Statuses understandable without colour.

## 5. Performance QA

Measure on representative mid-range Android hardware:

- Cold/warm startup.
- First authenticated home render.
- Search result latency and scrolling.
- Seat map update/rebuild cost.
- Reservation callable latency.
- Scanner decode-to-result latency.
- Memory during long lists/camera.

Run profile/release mode, not debug. Establish p50/p95 baselines and regression thresholds.

## 6. Security QA

- Rules negative tests.
- Role escalation attempts.
- QR tampering/replay/expiry.
- Callable payload fuzzing and oversized input.
- App Check staged enforcement verification.
- Secret and dependency scans.
- Sensitive logging review.
- Release-signing and environment-isolation checks.

## 7. CI gates

On pull requests:

1. Format check.
2. `flutter analyze` with no warnings.
3. Unit/widget/golden tests.
4. Functions lint/typecheck/unit tests.
5. Emulator Rules/integration tests.
6. Dependency and secret scan.
7. Android debug build.

On release:

- Android App Bundle and iOS archive.
- Staging end-to-end test.
- Physical camera/push/auth smoke.
- Crash-free and performance baseline.
- Store metadata/privacy/permission review.

## 8. Defect severity

- Critical: security/privacy breach, data corruption, widespread inability to book/check in.
- High: critical journey blocked without workaround.
- Medium: confusion/delay or broken secondary flow.
- Low: cosmetic/minor inconvenience.

Critical/high defects block release.

## 9. Current baseline gaps

- Existing tests are primarily render smoke tests.
- No current Rules, Functions, emulator, integration, golden, camera, push, or accessibility suites.
- Existing analyzer warnings should be removed before CI becomes required.
- Current staff layout fix is local and should be committed with tests.
