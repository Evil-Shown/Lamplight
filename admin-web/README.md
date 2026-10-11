# Lamplight staff dashboard (admin-web)

A static, zero-build web app for library staff and administrators. Plain HTML, CSS and ES modules; the
Firebase JS SDK (v10.14.1, modular) is loaded from `https://www.gstatic.com/firebasejs/10.14.1/`. No
`npm install` is needed to run it.

## Who can sign in

Access comes from the server, not from this app. After sign-in the page calls the `claimRole` Cloud Function,
which sets the `role` custom claim (`admin` / `staff` / `student`) from the allow-lists in
`config/adminAllowlist` and `config/staffAllowlist` and requires a **verified email**. Only `staff` and `admin`
can use the dashboard; the Staff page is admin-only. Admins manage the staff list on the Staff page.
Firestore rules enforce the same roles, so hiding a page in the UI is not the security boundary.

Sample accounts come from `npm run seed:users` in `functions/` (see the root README):

| Role | Email |
| --- | --- |
| student | student@lamplight.test |
| staff | staff@lamplight.test |
| admin | admin@lamplight.test |

The development default password is `Lamplight#2026` (override with `SEED_*_PASSWORD`). Students cannot use
the dashboard.

## Run locally (emulators)

```powershell
# terminal 1: from the repo root
firebase emulators:start --only auth,firestore,functions

# terminal 2: seed sample users against the emulators
cd functions
$env:FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9099"; $env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"
$env:GCLOUD_PROJECT="sliit-quick-book"; npm run seed:users

# terminal 3: serve the static files
npx serve admin-web -l 5000        # or: python -m http.server 5000 --directory admin-web
```

Open `http://localhost:5000/?emulator=1`. The `?emulator=1` flag (localhost only) connects Auth (9099),
Firestore (8080) and Functions (5001) to the emulators; an "Emulator" badge shows in the header. Without the
flag the page talks to the real project. Google sign-in popups need the Auth emulator's popup flow.

## Deploy

1. `firebase deploy --only firestore:indexes` (only if `firestore.indexes.json` changed; the dashboard queries need no new indexes).
2. `firebase deploy --only functions` if the server side is out of date (`claimRole`, `endSeatSession`, `listStaff`, `setStaffAllowlist`, `verifyQrPass`).
3. `firebase deploy --only hosting`.
4. In Firebase console > Authentication > Settings > Authorized domains, make sure the hosting domain
   (`sliit-quick-book.web.app`, `sliit-quick-book.firebaseapp.com`, or your custom domain) is listed, or Google sign-in fails with "domain isn't authorised".
5. Enable the Google and Email/Password providers if they are not already.

Hosting config (headers, CSP, `public: admin-web`) lives in the root `firebase.json`.

## Pages

Overview, Reservations (can cancel open reservations), Seat bookings (end active sessions), Waiting list
(read-only), Books (add / edit / adjust copies), Seats (release), Verify pass, Staff (admin only).

## Layout

`index.html`, `css/styles.css`, `js/` (`firebase-config.js`, `firebase.js`, `auth.js`, `router.js`, `store.js`,
`ui.js`, `main.js`, `pages/*.js`). Listeners are ref-counted in `store.js` and closed on every route change and on sign-out.
Never put untrusted data into `innerHTML`; use the `el()` helper in `ui.js`.
