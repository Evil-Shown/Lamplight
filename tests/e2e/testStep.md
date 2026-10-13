# Test steps: staff dashboard (browser)

Written for: anyone running the staff dashboard tests on Windows, including the viva demo.

## 1. One-time setup

Needs Node.js and Microsoft Edge (already installed on Windows). The tests use Edge, so no browser download is needed.

```powershell
cd "d:\Coding\Ongoing\Lamplight - Library App\tests\e2e"
npm install
```

## 2. Set the sign-in details (this session only)

Use the staff account's password. Do not save it in any file.

```powershell
$env:STAFF_EMAIL="staff@lamplight.test"
$env:STAFF_PASSWORD="<staff password>"
```

Optional, for the student-refused test:

```powershell
$env:STUDENT_EMAIL="student@lamplight.test"
$env:STUDENT_PASSWORD="<student password>"
```

## 3. Run the tests

```powershell
npm test            # runs everything headless and prints results
npm run test:headed # same tests in a visible Edge window (use this for the demo)
```

Expected: all tests pass except the student-refused test, which fails until the "no access" message is fixed (see the notes in section 5).

## 4. Show the report

```powershell
npm run report
```

Opens the HTML report with each step, its result, and screenshots of every operations page.

## 5. What each test checks

| Test | What it checks |
|---|---|
| Login page shows the staff sign-in form | Sign-in fields and button are visible |
| Wrong password shows an error | Error message appears and the user stays on login |
| Staff signs in and sees the navigation | Main navigation appears after sign-in |
| Opens each operations page | Overview, Reservations, Seat bookings, Waiting list, Verify pass, Books and Seats load with no error text |
| Staff does not see the Staff page | The admin-only Staff page is hidden from staff |
| Student is refused | A student sees the "no staff access" message |

Known issues to mention if asked:
- **Student-refused test fails.** When the role function isn't deployed, the dashboard shows "Couldn't verify your access" instead of "doesn't have library staff access".
- **Seats page can be slow.** One run took about 40 seconds. TC28 requires under 3 seconds.

## 6. Troubleshooting

- **Tests skip:** the staff variables aren't set in the same PowerShell window. Set them again and run in that window.
- **Sign-in fails for staff:** the staff account may have been changed or the password is wrong. Check the Firebase console under Authentication → Users.
- **Edge not found:** install Microsoft Edge, or change `channel` in `playwright.config.js` to `chrome` if Chrome is installed.
