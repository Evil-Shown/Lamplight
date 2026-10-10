# Lamplight Staff & Admin Web Dashboard

The Staff & Admin Web Dashboard is a zero-build client web application (`admin-web/`) hosted on **Firebase Hosting**. It allows librarians and library administrators to monitor operations, manage catalog entries and seats, verify QR passes, and administer staff permissions.

---

## 1. Live Deployment & Access

| Parameter | Value |
| :--- | :--- |
| **Production URL** | **[https://sliit-quick-book.web.app](https://sliit-quick-book.web.app)** |
| **Alternative Domain** | [https://sliit-quick-book.firebaseapp.com](https://sliit-quick-book.firebaseapp.com) |
| **Firebase Project** | `sliit-quick-book` |
| **Hosting Source** | `admin-web/` (configured in `firebase.json`) |

---

## 2. Authentication & Role Gate

Access to the dashboard is strictly gated on the server side via custom Firebase Auth claims (`role`):
* **Admin** (`role: "admin"`): Full access to all dashboard pages, including the staff management allow-list.
* **Staff** (`role: "staff"`): Access to Overview, Bookings, Reservations, Books, Seats, Waiting List, and Verify Pass.
* **Student** (`role: "student"`): **Access Denied**. Signed out immediately with an unauthorized notice.

### Default Test Logins

| Role | Email | Password | Access Scope |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@lamplight.test` | `Lamplight#2026` | All tabs + Staff management |
| **Staff** | `staff@lamplight.test` | `Lamplight#2026` | Operations tabs |

---

## 3. Dashboard Features & Pages

| Page / Route | Role | Description |
| :--- | :--- | :--- |
| **Overview** (`#/overview`) | Staff / Admin | Live stat cards (active sessions, open holds, waitlist count), floor seat occupancy chart, today's activity stream. |
| **Reservations** (`#/reservations`) | Staff / Admin | Live reservations table with status filters (ready, active, completed, cancelled) and cancellation action. |
| **Seat Bookings** (`#/bookings`) | Staff / Admin | Active and historical seat bookings with real-time "End session" action. |
| **Waiting List** (`#/waitlist`) | Staff / Admin | Read-only live queue monitoring for book holds and seat waitlists. |
| **Book Catalogue** (`#/books`) | Staff / Admin | Add new titles, update details, adjust total copies. Deletions prevented to safeguard reservation integrity. |
| **Seat Map** (`#/seats`) | Staff / Admin | 4×4 seat grid by floor showing live availability and "Release seat" emergency controls. |
| **Verify Pass** (`#/verify`) | Staff / Admin | QR ticket verification tool with "Check pass" (inspect only) and "Verify & Use" (consumes pass). |
| **Staff Management** (`#/staff`) | **Admin Only** | Add/remove staff email addresses to `config/staffAllowlist`. |

---

## 4. Architecture & Security

* **Zero-Build Stack**: Native ES Modules, vanilla CSS, and the modular Firebase JS SDK v10.14.1 loaded from `https://www.gstatic.com/firebasejs/10.14.1/`.
* **Security Headers**: Production-grade Content Security Policy (CSP), `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, and strict referrer policy defined in `firebase.json`.
* **Direct Firestore Integration**: Live snapshot listeners (`onSnapshot`) keep data synchronized without polling.
* **Sensitive Actions**: Actions modifying permissions or ending sessions invoke verified Cloud Functions (`endSeatSession`, `setStaffAllowlist`, `listStaff`, `verifyQrPass`).

---

## 5. Local Development & Deployment

### Run Locally (against live Firebase or Emulators):
```powershell
# Serve static files locally:
cd admin-web
npx serve . -l 5000

# Open in browser:
# Against Live Firebase: http://localhost:5000
# Against Local Emulators: http://localhost:5000/?emulator=1
```

### Deploy to Firebase Hosting:
```bash
firebase deploy --only hosting --project sliit-quick-book
```

