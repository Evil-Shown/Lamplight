# Lamplight Operations and Maintenance

## 1. Environments

- Dev: local/emulator and developer Firebase project.
- Staging: production-like data shape, test users, App Distribution/TestFlight.
- Production: real users and strict access.

Production credentials/data must never be copied to dev. Use synthetic or anonymised staging data.

## 2. Monitoring

Track:

- Client crashes and non-fatal errors.
- Function error rate, p50/p95 latency, cold starts.
- Firestore reads/writes, denied requests, contention.
- Auth failures and role/bootstrap errors.
- FCM send failures and invalid device tokens.
- QR invalid/replay/wrong-location events.
- Scheduler/task failures and waitlist backlog.
- Budget and quota thresholds.

## 3. Runbooks

Maintain procedures for:

- Firebase outage/degraded service.
- Reservation transaction failures.
- Stuck waitlist offers.
- Incorrect staff role.
- QR signing-key compromise/rotation.
- Push notification outage.
- Catalogue sync drift.
- Accidental rules/index/function deployment.
- Lost release signing access.

## 4. Backups and recovery

- Schedule Firestore exports under approved retention.
- Version Functions, Rules, indexes, config, and migration scripts in git.
- Test restore into a non-production project.
- Define recovery time and recovery point objectives with stakeholders.
- Keep catalogue source of truth and reconciliation process explicit.

## 5. Data quality

- Daily reconciliation of aggregate book/seat availability.
- Detect overlapping seat reservations and impossible status transitions.
- Monitor expired reservations not released.
- Validate orphan references and notification delivery backlog.
- Provide staff escalation rather than silent automatic destructive repair.

## 6. Role administration

- Named administrators with MFA.
- Documented approval for staff access.
- Admin SDK script or protected portal assigns claims.
- Quarterly access review and immediate offboarding.
- Immutable audit event for grant/revoke.

## 7. Cost management

- Firebase budget alerts at multiple thresholds.
- Bounded queries and pagination.
- Avoid broad real-time listeners.
- Aggregate dashboards through trusted projections.
- Retention policies for audit/notification/device data.
- Review function scheduling and external email/SMS costs.

## 8. Versioning and compatibility

- Semantic app version plus build number.
- Version callable payloads and notification schemas.
- Keep backend backward compatible during mobile rollout.
- Remote Config can enforce minimum supported version only with a user-friendly update path.
- Document schema migrations and rollback.

## 9. Support

App exposes support contact and non-sensitive request/reference ID. Support staff use approved tools, do not request QR tokens/passwords, and escalate privacy/security reports immediately.
