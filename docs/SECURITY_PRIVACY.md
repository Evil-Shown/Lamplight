# Lamplight Security and Privacy Plan

## 1. Threat model

Protect against:

- Unauthenticated access and horizontal data access between users.
- Client-side role escalation.
- Double booking, forged status changes, and clock manipulation.
- QR forgery, screenshot replay, and repeated scanning.
- Stolen devices/sessions and leaked FCM tokens.
- Malicious or automated function calls.
- Sensitive information in logs, analytics, screenshots, or push notifications.
- Misconfigured Firestore Rules, Storage Rules, or Firebase project environments.

## 2. Security controls

### Identity and authorisation

- Firebase Authentication with verified Google identity.
- Institution-domain policy where required.
- Custom claims for `staff` and `admin`; default role is `student`.
- Server-side checks in every privileged callable function.
- Deny-by-default Firestore/Storage Rules.
- Re-authentication for sensitive account actions where appropriate.

### Application integrity

- Firebase App Check enforced after staged rollout.
- Play Integrity for Android and App Attest/DeviceCheck for Apple.
- Debug tokens limited to dev project and CI.
- Rate limits and idempotency on callable operations.

### Data protection

- TLS and Firebase-managed encryption at rest.
- Minimal profile fields; avoid copying personal identifiers into notifications/audit metadata.
- Secrets in Secret Manager, not client code or Remote Config.
- FCM payloads contain minimal generic content; sensitive details load after authentication.
- No raw QR tokens in logs or analytics.

## 3. QR security

- Signed, versioned, short-lived token.
- Purpose and audience binding.
- Server-time expiry.
- One-time nonce/replay detection for check-in/pickup.
- Server verifies current reservation state and scanner role/location.
- Scanner debounces frames and hides token content.
- Manual fallback requires staff authentication and creates an audit reason.

## 4. Camera privacy

- Request camera only when staff opens Scanner.
- Explain the purpose before system permission.
- Do not record or upload video frames.
- Process frames locally for barcode detection; send only decoded token to verification API.
- Provide permission-denied recovery and manual entry.
- Include camera-use disclosure in privacy policy and store listing.

## 5. Privacy lifecycle

- Publish privacy notice covering identity, reservations, device tokens, camera processing, analytics, retention, and support contact.
- Define lawful/institutional basis and approved retention with SLIIT/library stakeholders.
- Provide access/correction and deletion/export request channels.
- On sign-out: clear sensitive in-memory state and local caches; unregister device where policy requires.
- On account deletion: anonymise or retain operational records only under documented policy.

## 6. Rules testing

Emulator tests must prove:

- Anonymous access denied.
- User A cannot read/write User B profile, reservations, waitlist, notifications, or devices.
- Client cannot create confirmed reservations or alter ownership/status.
- Student cannot access staff queries/actions.
- Staff access is limited to required operational fields.
- Audit/QR nonce records are not client-writable.
- Field validation rejects extra/invalid/oversized data.

## 7. Secure development

- Dependency updates and vulnerability scanning.
- Secret scanning and protected branches.
- Review all Rules/Functions changes.
- Use separate Firebase projects and least-privilege service accounts.
- Enable MFA for administrators.
- Rotate signing keys and credentials on schedule or incident.
- Store release signing keys outside the repository.

## 8. Incident response

1. Detect via alerts, logs, user report, or anomaly.
2. Contain with feature flag, claim revocation, App Check/rule tightening, token/key rotation.
3. Preserve safe evidence and determine affected users/data.
4. Remediate and deploy through staging.
5. Notify stakeholders/users where policy or law requires.
6. Document root cause and preventive actions.

## 9. Security release gate

- Rules emulator suite passes.
- No default `com.example` package ID or debug release signing.
- App Check configured per flavor.
- Staff claims tested against expired/refreshing tokens.
- QR replay/expiry/wrong-location tests pass.
- Privacy policy and permission strings approved.
- No sensitive values found in logs, analytics, crash reports, or repository.
