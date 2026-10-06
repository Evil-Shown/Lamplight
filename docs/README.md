# Library+ Development Documentation

This directory is the implementation source of truth for completing the app. It combines the current Flutter prototype with Assignment 1 research, Assignment 2 high-fidelity prototype/testing, and the **Milestone 03** implementation/evaluation brief (working APK, CRUD, tests, consolidated report due **09.10.2026**).

## Read in this order

1. [`PRODUCT_REQUIREMENTS.md`](PRODUCT_REQUIREMENTS.md) — users, scope, FR/NFR, success criteria.
2. [`FEATURES.md`](FEATURES.md) — complete feature catalogue and acceptance intent.
3. [`HIGH_LEVEL_ARCHITECTURE.md`](HIGH_LEVEL_ARCHITECTURE.md) — system, layers, data flows, Firebase boundaries.
4. [`UI_DESIGN.md`](UI_DESIGN.md) — visual system, screens, interaction, accessibility.
5. [`FRONTEND_DESIGN.md`](FRONTEND_DESIGN.md) — Flutter structure, state, routing, offline/error handling.
6. [`BACKEND_DESIGN.md`](BACKEND_DESIGN.md) — Firebase Auth, Firestore, Functions, FCM, QR, scheduling.
7. [`DATA_MODEL.md`](DATA_MODEL.md) — collections, fields, indexes, retention, migrations.
8. [`SECURITY_PRIVACY.md`](SECURITY_PRIVACY.md) — threats, rules, QR/camera security, privacy.
9. [`INTEGRATION_WIRING.md`](INTEGRATION_WIRING.md) — platform setup and end-to-end wiring.
10. [`TESTING_QA.md`](TESTING_QA.md) — automated, emulator, usability, accessibility, performance, security.
11. [`POLISHING_RELEASE.md`](POLISHING_RELEASE.md) — UX polish, stores, operational release gates.
12. [`OPERATIONS.md`](OPERATIONS.md) — monitoring, backup, runbooks, cost, support.
13. [`IMPLEMENTATION_ROADMAP.md`](IMPLEMENTATION_ROADMAP.md) — phased execution and priorities.
14. [`DECISIONS.md`](DECISIONS.md) — settled and open product/architecture decisions.
15. [`REPORT_AND_VIVA.md`](REPORT_AND_VIVA.md) — M03 PDF structure, CRUD/viva checklist, **AI similarity must be under 50%**.
16. [`workloads/DAMITHA_SEAT_BOOKING.md`](workloads/DAMITHA_SEAT_BOOKING.md) — Damitha (Yatawata) seat map, filters, details, success, waitlist: frontend + backend.

## Reference material

- [`hci_assignments_extracted/Assignment1_HCI.md`](hci_assignments_extracted/Assignment1_HCI.md)
- [`hci_assignments_extracted/HCI_Assignment-2_WE_153_2.2.md`](hci_assignments_extracted/HCI_Assignment-2_WE_153_2.2.md)
- [`hci_assignments_extracted/Milestone03_Assignment.md`](hci_assignments_extracted/Milestone03_Assignment.md)
- [`INFORMATION_ARCHITECTURE.md`](INFORMATION_ARCHITECTURE.md) — legacy screen mapping; update alongside route implementation.
- Figma: <https://www.figma.com/design/UwmGSbPjOtHRDai9KnA02V/Library-UI>

## Current state

The repository is a high-fidelity Flutter prototype with mock, in-memory state. It is not yet production connected. Current strengths include the campus-blue design system, book/seat/reservation screens, role-aware shell, QR display, and broad render smoke tests.

Major missing production capabilities:

- Firebase authentication and server-enforced roles.
- Firestore repositories and transactional reservations.
- Secure QR token verification and real camera scanning.
- Push/reminders/waitlist automation.
- Security Rules/App Check.
- Offline/error/accessibility completion.
- CI, integration/emulator tests, monitoring, and release configuration.

## Documentation rules

- Mark prototype-only behavior clearly.
- Do not claim real-time/live data without an authoritative integration.
- Do not invent usability test results.
- The **submitted PDF** must be written in the group's own words. AI-assisted `docs/` files are working notes, not copy-paste into the report. Examiner AI percentage **must stay below 50%**.
- Update requirement acceptance criteria when behavior changes.
- Record cross-cutting decisions in `DECISIONS.md`.
- Keep Firebase Rules, indexes, Function contracts, and schema changes synchronized with these documents.
