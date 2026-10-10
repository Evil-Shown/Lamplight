# Lamplight Data Model

## 1. Conventions

- Firestore document IDs are opaque; human references are separate fields.
- Timestamps use server timestamps and UTC.
- Every mutable operational document has `createdAt`, `updatedAt`, and optional `version`.
- Status values are enumerated and validated in Functions/Rules.
- Denormalised display snapshots are allowed on reservations so historical records remain understandable.
- Personal data is minimised; do not put emails/student IDs into broadly readable collections.

## 2. Collections

### `/users/{uid}`

Fields: display name, email, institution ID if approved, role mirror, profile status, preferred campus, locale, accessibility preferences, created/updated/last-login timestamps.

Subcollections:

- `/devices/{deviceId}`: FCM token, platform, locale, app version, enabled, timestamps.
- `/private/preferences`: notification channels, reminders, quiet hours.

### `/libraries/{libraryId}`

Name, campus, timezone, location, operating hours, active flag.

Subcollections:

- `/floors/{floorId}`: name, order, map asset/version.
- `/seats/{seatId}`: label, floor, zone, coordinates, amenities, accessibility, operational status.
- `/policies/{policyId}`: slot length, limits, grace periods, pickup windows.

### `/books/{bookId}`

Title, normalised title, authors, normalised authors, ISBNs, subjects, description, cover URL, catalogue source/version, aggregate availability, shelf summaries, updated timestamp.

### `/bookCopies/{copyId}`

Book ID, barcode, library, shelf, status (`available`, `reserved`, `loaned`, `maintenance`), due date, active reservation reference.

Restrict detailed copy data to staff where appropriate; student queries use book availability projections.

### `/reservations/{reservationId}`

Common fields:

- Owner UID.
- Type (`book`, `seat`).
- Status (`pending`, `confirmed`, `ready`, `checked_in`, `completed`, `cancelled`, `expired`, `no_show`).
- Human reference.
- Resource/library IDs.
- Resource display snapshot.
- Created, confirmed, cancelled, expired, completed timestamps.
- Policy snapshot/version.
- Idempotency key.

Book fields: book/copy ID, pickup location, pickup deadline, collected timestamp.

Seat fields: seat ID, start/end, check-in deadline, checked-in/out timestamps.

### `/seatSlots/{slotId}`

Deterministic ID formed from seat and UTC slot. Stores reservation ID, owner UID, start/end, and status. Written only by trusted functions. Used to guarantee uniqueness.

### `/waitlistEntries/{entryId}`

Owner UID, resource type/ID, preference snapshot, status (`waiting`, `offered`, `claimed`, `declined`, `expired`, `removed`), priority/join timestamp, position projection, active offer ID.

### `/waitlistOffers/{offerId}`

Entry/resource IDs, offered UID, issued/expiry timestamps, status, claimed reservation ID. Trusted writes only.

### `/notifications/{notificationId}`

Owner UID, type, title/body or template data, related entity ID, channel statuses, read timestamp, created timestamp, deep-link key. User may update only read/dismiss fields.

### `/qrTokens/{tokenId}`

Use only if replay/state tracking is required. Store token ID/nonce hash, reservation ID, purpose, issued/expiry/consumed timestamps, and consuming staff/location. Never store the raw signed token.

### `/auditEvents/{eventId}`

Actor UID/role, action, target type/ID, reason, result, location, request ID, timestamp, safe metadata. Append-only and staff/admin read restricted.

### `/systemConfig/{document}`

Feature flags and policy references that are not secrets. Secrets stay in Secret Manager.

## 3. Index plan

Expected composite indexes:

- Reservations by owner UID + type + status + relevant deadline/start.
- Reservations by library + status + start/deadline for staff.
- Waitlist by resource + status + priority/join time.
- Notifications by owner UID + created timestamp.
- Seats by library/floor/zone/operational status.
- Books by normalised searchable fields and availability when supported.

Only add indexes required by actual queries; document each query beside repository code.

## 4. Retention

- Active operational records retained while needed.
- Completed/cancelled reservations retained according to institution policy, then anonymised or deleted.
- Device tokens removed after sign-out/invalidation.
- QR nonce records retained only for replay/audit window.
- Audit logs retained under approved policy with restricted access.
- Analytics uses aggregation and avoids personal content.

## 5. Data migrations

- Include schema version on documents where shape evolution is likely.
- Functions support old/new fields during rolling migration.
- Run idempotent Admin SDK migration scripts in staging first.
- Back up/export production before destructive migrations.
- Never make the mobile release depend on an instantaneous full migration.
