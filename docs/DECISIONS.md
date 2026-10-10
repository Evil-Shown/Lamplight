# Lamplight Architecture and Product Decisions

## ADR-001 — Campus-blue design is authoritative

**Decision:** Use the current Figma-aligned campus-blue/Inter design. The root “Ledger” document is historical.

**Reason:** Assignment 2 specifies navy/blue, Inter, mobile frames, status colours, and shared components; current code follows this direction.

## ADR-002 — Firebase with trusted Functions

**Decision:** Use Firebase Auth/Firestore/Functions/FCM/App Check. Direct reads are allowed where Rules suffice; conflict-sensitive and privileged writes use Cloud Functions.

**Reason:** Prevent client-authoritative roles, double bookings, clock manipulation, and forged QR/check-in state.

## ADR-003 — Google is the first authentication provider

**Decision:** Implement Google sign-in first, optionally restricted to institution domains. Do not ship fake password/smartcard/SSO controls.

## ADR-004 — Custom claims authorise staff/admin

**Decision:** Firebase custom claims are authoritative for staff/admin; profile role mirror is display-only. Only trusted Admin SDK workflows assign roles.

## ADR-005 — Secure short-lived QR token

**Decision:** QR codes contain a signed, expiring, purpose-bound token, not a raw reservation ID. Verification is server-side with replay protection.

## ADR-006 — Feature-first layered Flutter

**Decision:** Keep feature folders but introduce presentation/application/domain/data boundaries, repositories, Riverpod, and `go_router`.

## ADR-007 — Fake repositories remain supported

**Decision:** Convert `MockData` into deterministic fakes for tests/UI demos while Firebase implementations become production defaults.

## ADR-008 — Canonical research figures

**Decision:** Use 119 total respondents and 12 library staff for planning because the detailed breakdown totals 119. Preserve the source conflict (117 valid responses and one table showing 13 staff) in documentation.

## ADR-009 — Canonical requirements

**Decision:** FR01–FR19 and NFR01–NFR07 from Assignment 1 are canonical. Assignment 2 maps prototype screens but does not remove backend NFR02/NFR05/NFR07.

## ADR-010 — Student navigation

**Decision:** Home · Seats · Books · Bookings · Profile. Waitlist belongs inside Bookings, not a separate primary tab.

## ADR-011 — Staff navigation

**Decision:** Home and Staff must be distinct. Home is overview; Staff contains scanner/lookup/queue tools.

## ADR-012 — Firestore is not full-text search

**Decision:** Begin with normalised structured/prefix search for limited catalogue scope; adopt Algolia/Typesense when scale, ranking, or typo tolerance requires it.

## ADR-013 — Offline writes are conservative

**Decision:** Cached reads are supported, but reservation/check-in actions require authoritative server success and are not silently queued.

## ADR-014 — User-test data must match tasks

**Decision:** Seed the exact reservable “Introduction to Human Computer Interaction” item used in Assignment 2 T4, or formally update the task wording.

## Open decisions

- Final product name/subtitle and institution branding approval.
- Institution domain(s), alumni/faculty account policy, and SSO timing.
- Source library-management system and integration protocol.
- Fixed vs arbitrary seat slot lengths.
- No-show strike/override policy.
- Email/SMS providers and funding.
- Data retention periods and legal approval.
- Multi-campus scope for first production release.
