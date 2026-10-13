# Lamplight: Manual Functional Test Cases (TC01 to TC28)

Written for: the group, the examiner and anyone repeating the tests on a phone.

These are the device-level tests for the 28 functional cases in the Milestone 03 report (Section 8). Each case lists its steps, expected result and requirement. Record the result, tester and date after each run. Do not mark a case Pass unless you ran it on the installed build.

## Environment

- **Build:** release APK (`flutter build apk --release`) or `flutter run` on an Android phone. Record the device model and Android version.
- **Network:** Wi-Fi or 4G for every run. TC28 needs a stated connection.
- **Backend:** cases marked **Live** need the Cloud Functions and rules deployed to the Firebase project. Without them, the case cannot pass.
- **Accounts** (create or confirm before the run):
  - `Student A`: `student@lamplight.test`
  - `Student B`: a second student account, for the two-user cases (TC11, TC14)
  - `Staff`: `staff@lamplight.test`
  - Use the passwords you set. Do not write them in this file.
- **Test data:** search for "Introduction to Human Computer Interaction" for TC01 and TC05. Use a book with copies above zero and one with zero for TC03 and TC06. Set copies to zero from the staff Catalog screen if needed.

## Result key

- **Pass:** the expected result happened as written.
- **Pass*:** passed after a fix. Note the defect ID (for example D01).
- **Fail:** the expected result did not happen. Log a defect.
- **Blocked:** the case could not run (for example, the backend is not deployed). Say why.

## Test cases

| ID | Test (operation) | Steps | Expected result | Req. | Live | Result | Tester / date |
|---|---|---|---|---|---|---|---|
| TC01 | Book search: title (Read) | Log in as Student A. Open Books. Type "Introduction to Human Computer Interaction". Submit. | Matching book(s) listed. | FR01 | No | Pass (Section 8) | Not recorded |
| TC02 | Search by author, ISBN and subject chip (Read) | Search author "Dix". Clear. Search an ISBN. Clear. Tap a subject chip. Search a nonsense term. | Each search returns matches. The nonsense term shows the empty state. | FR02 | No | Pass (Section 8) | Not recorded |
| TC03 | Availability status (Read) | Open a book with copies above zero, then one with zero. | Shows Available and Unavailable correctly. | FR03 | No | Pass (Section 8) | Not recorded |
| TC04 | Open book details (Read) | Open any book. | Description, shelf location and due date are shown. | FR04 | No | Pass (Section 8) | Not recorded |
| TC05 | Reserve an available book (Create) | Open an available book. Tap Reserve. Confirm. Note the copy count before and after. | Reservation saved. Copy count drops by 1. | FR05 | Yes | Pass (Section 8) | Not recorded |
| TC06 | Reserve an unavailable book | Open a book with zero copies. Try to reserve. | Reserve is blocked. A waiting list option is offered. | FR05, FR13 | Yes | Pass (Section 8) | Not recorded |
| TC07 | Confirmation after reserving (Read) | Complete TC05. Stay on the success screen. | Success screen shows the book, details and pickup deadline. | FR07 | No | Pass (Section 8) | Not recorded |
| TC08 | Seat map is live (Read) | Student A opens Seats. Student B books a seat on another phone. Watch Student A's screen without refreshing. | The seat changes to taken on Student A's screen. | FR08 | Yes | Pass (Section 8) | Not recorded |
| TC09 | Seat details (Read) | Open Seats. Tap any seat. | Power, quiet and window information is shown. | FR09 | No | Pass (Section 8) | Not recorded |
| TC10 | Floor, area and feature filters (Update) | Open the filter sheet. Pick a floor, an area and a feature. Apply. | Map shows only matching seats. A recommended seat is displayed. | FR10 | No | Pass (Section 8) | Not recorded |
| TC11 | Two users book the same seat and time | Student A books a seat and time. Student B tries the same seat and time on another phone. | Student B's booking is rejected with a message. | FR11, NFR03 | Yes | Pass (Section 8) | Not recorded |
| TC12 | Reserve a seat (Create) | Choose a free seat and time. Confirm. | Reservation saved. Confirmation screen shown. | FR11, FR12 | Yes | Pass (Section 8) | Not recorded |
| TC13 | Join the seat waiting list (Create) | Find a full seat. Join the waiting list. | Entry saved. Queue position shown. | FR13 | Yes | Pass (Section 8) | Not recorded |
| TC14 | Seat freed while a user is waiting | Student A is on the waiting list for a seat. Student B cancels that seat (or staff releases it). | Student A is notified. | FR14 | Yes | Pass* (D01; retested per Section 8) | Not recorded |
| TC15 | Seat status after cancel or expiry | Cancel your own seat booking. Check the seat on the map. | Seat shows Available again. | NFR03 | Yes | Pass (Section 8) | Not recorded |
| TC16 | Leave the waiting list (Delete) | Open the waiting list entry. Leave it. | Entry removed. Remaining positions update. | FR13 | Yes | Pass (Section 8) | Not recorded |
| TC17 | My Reservations (Read) | Open Bookings. Check the Books, Seats and Waiting tabs. | Active book and seat reservations are listed in the right tabs. | FR06 | No | Pass (Section 8) | Not recorded |
| TC18 | Cancel a reservation (Update or Delete) | Open a reservation. Tap Cancel. Read the dialog. Confirm. | Dialog states the consequence before confirming. Status becomes cancelled. | FR15 | Yes | Pass (Section 8) | Not recorded |
| TC19 | Reservation expires after grace period | Let a reservation pass its pickup deadline and grace period. Wait for the scheduled run. | Status becomes expired. Resource is released. Known issue D02: the expiry can show late until the scheduled run. | FR15 | Yes | Fail (D02; Section 8) | Not recorded |
| TC20 | Notifications list (Read) | Open Notifications. | Reminder and status notifications are listed. | FR16, FR18 | Yes | Pass (Section 8) | Not recorded |
| TC21 | Mark read or dismiss a notification (Update or Delete) | Tap a notification. Mark all read. | Unread marker clears. Item is removed or marked read. | FR18 | No | Pass (Section 8) | Not recorded |
| TC22 | Open the QR pass for a seat (Read) | Open a seat reservation. Open the QR pass. | QR code shown with its expiry time. | FR19 | Yes | Pass (Section 8) | Not recorded |
| TC23 | Staff scans a valid pass | Staff opens Scan. Scan the QR from TC22. | Result: Valid. Booking status becomes checked in. | FR19 | Yes | Pass (Section 8) | Not recorded |
| TC24 | Staff scans an invalid or expired pass | Staff enters a made-up code, or scans an expired pass. | Result: Invalid or Mismatch. No status change. | FR19 | Yes | Pass (Section 8) | Not recorded |
| TC25 | Register, log in, wrong password (Create and Read) | Register a new account. Log out. Log in with the wrong password. | Account is created. Wrong password is rejected. | NFR04 | Yes | Pass (Section 8) | Not recorded |
| TC26 | Student tries staff screens or another user's data | Log in as Student A. Check there is no staff area. Confirm the rules block reading another user's data (see `rules-tests`). | Staff area is not shown. Other users' data is denied by the rules. | NFR04, NFR05 | Yes | Pass (Section 8) | Not recorded |
| TC27 | Contrast, labels and tap targets | Use the Android Accessibility Scanner on key screens (Seats, Books, Bookings). Check status labels appear with colour. Check buttons are at least 48 dp. | Status is never shown by colour alone. Tap targets are at least 48 dp. | NFR06 | No | Pass (Section 8) | Not recorded |
| TC28 | Load time of seat map and search | With a stopwatch, open Seats and run a book search, three times each, on the stated connection. | Each load finishes within 3 seconds. Record the three times. | NFR02 | Yes | Pass (Section 8) | Not recorded |

## Notes for the examiner

- **Automated coverage:** the Flutter tests (`flutter test`) and the rules suite (`rules-tests`) cover parts of TC01, TC02, TC09, TC17, TC20, TC21, TC26 and the staff screens. They do not replace the device runs above.
- **Live cases:** when the backend is not deployed, the Live cases are recorded as Blocked, not Pass.
- **Known open defect:** D02 (TC19) is recorded as an open limitation in Section 10 of the report.
- **Source of recorded outcomes:** statuses above were copied from Section 8 of the supplied report. Tester names, run dates, detailed actual observations for passing cases and raw timing values for TC28 were not included in the source, so they remain unrecorded and must not be presented as independently verified by this edit.
