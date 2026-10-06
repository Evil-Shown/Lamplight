# Library+ Polishing and Release Plan

## 1. Product polish

- Replace placeholder/demo text, mismatched campus names, fake version numbers, and non-functional controls.
- Use the single product name **Library+** with SLIIT-specific subtitle where approved.
- Ensure all actions have pressed, disabled, busy, success, and error states.
- Add skeletons instead of blank waiting screens.
- Add meaningful empty states that navigate correctly.
- Use consistent date/time/reference formatting.
- Verify long titles, names, and localisation expansion.
- Remove duplicate staff dashboard tab behavior.
- Rename legacy `ledger_widgets.dart` after migration.

## 2. UX completion

- Real date/time slot selection.
- Functional seat cancellation and policy confirmation.
- Book/seat waitlists with correct types.
- Due/return dates, distance/entrance attribute, QR validity window.
- Invalid/mismatch scanner results.
- Notification read state, reminders, and deep links.
- Accessibility and permission-denied paths.
- History filters and active/expired status accuracy.

## 3. Visual QA

- Match approved Figma tokens/components.
- Review 320px, 390px, tablet/web frame, text scale 2.0.
- Verify keyboard, safe-area, notches, Android navigation, and iOS home indicator.
- Confirm QR quiet zone/contrast and scanner overlay.
- Test light mode thoroughly; do not ship incomplete dark mode.
- Optimise and license all images/icons/fonts.

## 4. Platform readiness

### Android

- Final application ID, app name, launcher/adaptive icons, splash.
- Release keystore and Play App Signing.
- Target/current SDK compliance.
- Camera/notification permissions and rationale.
- SHA fingerprints, Google sign-in, App Check.
- Signed AAB and internal testing track.

### iOS

- Final bundle ID, signing/profiles, icons, launch screen.
- Camera and notification usage descriptions.
- Google URL scheme, APNs, associated domains.
- TestFlight build and review metadata.

## 5. Store and legal

- Privacy policy URL and support URL.
- Accurate Data Safety/App Privacy disclosures.
- Permission explanations and screenshots.
- Age/content rating.
- App description, keywords, promotional text, and release notes.
- Copyright/licensing review for covers, imagery, and fonts.
- In-app account deletion path or support workflow where required.

## 6. Operational readiness

- Production budgets and quota alerts.
- Crashlytics/Performance/Function alerts.
- On-call/support contacts and incident runbook.
- Backup/export and restore rehearsal.
- Role-management procedure.
- Catalogue reconciliation procedure.
- Feature flags and rollback plan.
- Minimum supported app-version strategy.

## 7. Release phases

1. **Internal alpha:** team accounts, dev/staging backend, fake catalogue allowed.
2. **Closed beta:** selected students/staff; real policy testing; no broad claims.
3. **Pilot:** one library/floor; monitored occupancy and QR operations.
4. **Production:** gradual rollout after metrics/security/usability gates.

## 8. Go/no-go checklist

- All P0/P1 roadmap items complete.
- Critical journeys pass automated and physical-device tests.
- Rules and QR security tests pass.
- No high-severity defects.
- Usability targets met or exceptions documented.
- Monitoring, budgets, backups, and incident contacts active.
- Store/privacy/camera disclosures approved.
- Production data source and operational ownership confirmed.

## 9. Post-release

- Monitor crash-free sessions, callable errors/latency, failed scans, notification delivery, no-shows, and support reports.
- Review feedback after 24 hours, 7 days, and 30 days.
- Fix critical issues through staged hotfix.
- Compare research success metrics against production analytics without collecting unnecessary personal data.
