# Library+ UI/UX Design Specification

## 1. Direction

The production visual language is the current **campus blue** Figma-aligned design, not the retired cream/gold “Ledger” concept in the old root `UI-mockup.md`.

The product should feel calm, trustworthy, academic, and operationally clear. Blue communicates primary actions and identity; green means available/success; amber means attention or limited availability; red means destructive/invalid. Every status includes text and/or an icon so colour is never the only signal.

## 2. Foundations

### Layout

- Base mobile reference: 390×844 logical pixels.
- Horizontal page margin: 16px; 20–24px for focused detail/confirmation layouts.
- Spacing system: 4, 8, 12, 16, 20, 24, 32, 40.
- Touch targets: minimum 48×48dp.
- Content max width on web/tablet preview: 430px for mobile shell; future tablet layouts may use two panes.
- Respect safe areas, keyboard insets, text scaling, and navigation bars.

### Colour tokens

Use named semantic tokens from `app_theme.dart`; do not hardcode colours in screens.

- Background: cool off-white (`#F4F6FC` family).
- Surface: white.
- Primary: campus blue (`#1A56DB`).
- Primary pressed: darker blue.
- Secondary accent: violet/cyan only for controlled gradients and highlights.
- Text primary: near-black navy.
- Text secondary: slate.
- Border: cool light grey.
- Success: green; warning: amber; error: red; neutral: slate.

All text/background combinations must meet WCAG AA contrast. Validate actual token pairs with automated contrast tooling.

### Typography

- Font: Inter through bundled assets where possible; avoid runtime font-network dependency in production.
- Display: 22–32px, 700–800.
- Title: 16–20px, 600–700.
- Body: 14–16px, 400–500.
- Caption/metadata: 12–13px; never place essential body content below 14px.
- Support system text scaling through at least 200% without clipping critical actions.

### Shape and elevation

- Radii: 8 small, 12 controls, 16 cards, 20 prominent panels, 28 hero, pill for status chips.
- Prefer borders and subtle elevation. Use strong shadows only for primary floating/hero elements.
- Avoid excessive gradients; reserve them for brand hero, primary success, and staff identity areas.

### Icons and imagery

- Material rounded icons with consistent optical size.
- Every icon-only control requires a tooltip/semantic label.
- Book covers use real catalogue art where licensed, cached locally, with deterministic colour/title fallback.
- Login imagery must have documented licensing and a local fallback.

## 3. Navigation

### Student bottom navigation

Home · Seats · Books · Bookings · Profile

### Staff bottom navigation

Home · Seats · Catalog · Bookings · Staff

Staff Home must not duplicate the exact Staff tab. Recommended split:

- Home: operational overview and alerts.
- Staff: scanner, reservation lookup, queues, and tools.

Use persistent tab state with an `IndexedStack`/stateful shell. Detail routes sit above the shell. Deep links must select the correct tab and then open the route.

## 4. Reusable components

Maintain documented variants and states for:

- App scaffold and centred app bar.
- Primary, secondary, tertiary, and destructive buttons.
- Search field with clear/loading/error states.
- Surface card and interactive list card.
- Book cover and book result card.
- Seat tile: available, limited, occupied, selected, reserved by me, inaccessible.
- Status pill with text/icon.
- Filter chip, segmented tabs, bottom sheet, dialog.
- Notification row with read/unread/category.
- QR pass and scanner overlay.
- Empty, loading skeleton, offline, permission denied, recoverable error, fatal error.
- Confirmation hero and action footer.
- Form field with label, helper, validation, and password visibility.

Component APIs should use semantic properties (`status`, `tone`, `isSelected`) rather than accepting arbitrary colours.

## 5. Screen specifications

### Splash and authentication

- Splash: 1–1.5 seconds maximum unless bootstrap requires longer; show progress only when needed.
- Login: campus logo, concise value statement, “Continue with Google” primary button, privacy/terms links.
- Remove fake email/password, smartcard, or SSO controls until functional.
- Error states: cancelled sign-in, offline, blocked domain, disabled account, unknown error.
- Staff users sign in through the same Google flow; role determines destination.

### Home

- Greeting, notification action, current date/location.
- Highest-priority card first: active seat session, expiring pickup, or waitlist offer.
- Four quick actions maximum above the fold.
- Ready-for-collection card with deadline and route to QR/details.
- Floor occupancy with last-updated time and explicit “estimated/live” wording.

### Book search and results

- Search field at top; search mode chips: Title, Author, ISBN, Subject.
- Recent/popular suggestions before search.
- Results show cover, title, author, availability text, shelf/copy summary.
- Filters/sort in bottom sheet; preserve query when returning from details.
- Empty state differentiates no results from service failure.

### Book details

- Availability and primary action visible without excessive scrolling.
- Show title, author, ISBN, subject, description, shelf, available copies, expected return when unavailable.
- Available: “Reserve for pickup.”
- Unavailable: “Join waitlist.”
- Explain pickup deadline before confirmation.

### Seat map

- Floor selector, occupancy summary, filter button, and recommendation card.
- Grid uses labels and patterns/icons in addition to colour.
- Provide Map/List switch; list is essential for screen readers and dense layouts.
- Recommendation states why the seat matches (quiet + power + window).
- Display data freshness.

### Seat details and time selection

- Seat label, floor/zone, amenity icons with text.
- Date picker and valid time-slot selector.
- Disable invalid/past/conflicting slots with explanation.
- Show policy and check-in deadline before booking.

### Reservations

- Tabs: Books · Seats · Waiting; optional History filter inside each.
- Cards show status, key time/deadline, location, and one primary action.
- Cancellation uses a confirmation dialog stating consequences.
- Empty action switches to the relevant root tab, not `Navigator.pop`.

### Waitlist

- Show resource/preferences, current position, estimated wait as an estimate, and notification status.
- Promotion offer is visually urgent but not alarming: claim countdown + accept/decline.
- Explain that position can change.

### QR pass

- High-contrast QR on white with adequate quiet zone.
- Show reservation reference, resource, valid window, status, and refresh indicator.
- Never show the signing secret or raw personal data.
- Screenshot policy must be explicit; short-lived tokens reduce screenshot replay.

### Staff scanner

- Pre-permission education screen.
- Camera preview with scan frame, flashlight, camera switch, and manual code entry.
- Pause scanning while verification is in flight and debounce duplicate frames.
- Result states: valid, expired, cancelled, already used, wrong location, malformed, offline/unverifiable.
- Valid result shows minimal identity data, resource, time, and “Confirm” if policy requires a human step.

### Notifications and settings

- Notifications grouped by Today/Earlier with read state and deep-link destination.
- Settings expose push/email/SMS availability honestly.
- Include reminders, waitlist updates, quiet hours, accessibility, language, help, privacy, terms, version.

## 6. Motion

- 150–250ms for control transitions; 300–450ms for route/hero changes.
- Retain stagger, count-up, shimmer, pulse, and press-scale only where they convey state.
- Avoid infinite decorative animation on long lists.
- Respect `MediaQuery.disableAnimations` and reduce or remove non-essential motion.
- Scanner and QR verification feedback must be immediate and not depend solely on animation.

## 7. Accessibility checklist

- Semantic names/values/hints for seats, QR controls, and icon buttons.
- Logical focus and traversal order.
- 48dp targets and adequate target spacing.
- Text scale 1.0, 1.3, 1.6, and 2.0 tested.
- Portrait plus common small-screen tests; landscape where camera scanning is supported.
- Contrast AA; do not encode status only with hue.
- Screen-reader announcements for reservation success, errors, countdown expiry, and scanner result.
- Keyboard navigation on web/tablet.

## 8. Content style

- Use sentence case and direct verbs: “Reserve seat,” “Join waitlist,” “Cancel reservation.”
- Explain consequences before destructive actions.
- Avoid claiming “live” unless data has a reliable live source.
- Display local dates/times with timezone awareness.
- Error messages state what happened, whether data is safe, and the next action.

## 9. Design QA

Every screen must be reviewed at:

- 320px and 390px widths.
- Text scale 1.0 and 2.0.
- Light theme; dark theme is optional until designed fully.
- Loading, empty, offline, permission-denied, error, and success states.
- Student and staff roles.
- Realistic long names, titles, and translated text expansion.

Figma and Flutter tokens/components must stay aligned. Any deliberate divergence requires an entry in `DECISIONS.md`.
