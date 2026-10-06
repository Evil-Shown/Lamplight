# Damitha (Yatawata) — Seat booking workload

**Owner:** Yatawata Y.A.D.W.D.B.S — **Damitha**  
**Reg. No:** IT23628854  
**Module:** IT3060 HCI · Milestone 02 §3.1 + Milestone 03 implementation  
**Scope:** Reading-room **seat booking** (map, filters, details, success, waiting list) — **frontend and backend**.

This file is Damitha’s working spec. Do **not** paste it unchanged into the 35-page PDF (AI similarity must stay below 50%). Rewrite in your own words for the report; use this for coding, viva, CRUD evidence, and deviation notes.

Related: M02 extract §3.1, FR08–FR14, `docs/UI_DESIGN.md`, `docs/FRONTEND_DESIGN.md`, `docs/BACKEND_DESIGN.md`, `docs/DATA_MODEL.md`, `docs/REPORT_AND_VIVA.md`.

---

## 1. Milestone 02 §3.1 — design alternatives (completed)

Before Figma, several seat-finding layouts were compared against Q9 (how users prefer to find a seat: auto-recommend 33, floor/section filter 30, list 28).

| Variant | Strength | Weakness | Decision |
|---------|----------|----------|----------|
| **A. Plain list of seats** | Very simple to build | No sense of where seats are | **Rejected** |
| **B. Interactive floor map** | Shows layout and occupancy | Crowded without help | **Kept as base** |
| **C. Map with floor and area filters** | Location plus preference in one view | Needs a clear legend | **Selected** |
| **D. Auto-recommended seat card** | Removes searching (Q9) | Must explain why a seat was chosen | **Merged into C** |

**Final design (C + D):** users see a **floor map** with **filters** and, **above the grid**, a **recommendation card** (example: Seat **2C** — quiet area, power outlet, near window). A **legend** distinguishes available / limited / occupied / selected. Colour is never the only signal (NFR06).

**Figure 1.** Selected seat-booking sketch — Figma Page 1 (embed the sketch in the report appendix).

**Why not A:** Q9 ranked a raw list last; users would still walk floors.  
**Why B alone is not enough:** occupancy without floor/area filters and a recommendation still forces hunting.  
**Why the merge:** Q9 put automatic recommendation and floor filters ahead of a list. The list remains a **secondary / accessibility** mode in M03, not the primary view.

Downstream screens that belong to this same flow (Damitha):

| Figma | App file | Intent |
|-------|----------|--------|
| P-06 Seat Map | `lib/features/seats/seat_map_screen.dart` | Live occupancy, filters, recommendation, 4×4 map |
| P-06A Seat Filters | `lib/features/seats/seat_filter_sheet.dart` | Floor, zone, power, monitor, desk |
| P-07 Seat Details | `lib/features/seats/seat_detail_screen.dart` | Amenities, slot, reserve or waitlist |
| P-08 Seat Reserved | `lib/features/seats/booking_confirmation_screen.dart` | Confirmation + path to QR |
| P-09 Waiting List | `lib/features/waitlist/waitlist_screen.dart` | Occupied seat → join with preferences |
| P-09A Waitlist Joined | `lib/features/waitlist/waitlist_joined_screen.dart` | Queue position + estimate |

Home “Reserve a Seat” and Bookings → Seats/Waiting **consume** Damitha’s data; Wathudura/Pathiranage own those shells.

---

## 2. Requirements Damitha must satisfy

| ID | Requirement | Damitha’s screens |
|----|-------------|-------------------|
| FR08 | Display available reading-room seats | Seat Map |
| FR09 | Seat information (power, quiet, window) | Seat Details |
| FR10 | Identify seats by preference | Filter sheet + recommendation |
| FR11 | Reserve an available seat | Details → Reserve |
| FR12 | Confirmation after seat reservation | Seat Success |
| FR13 | Join a waiting list | Waiting List |
| FR14 | Notify when a seat frees up | Waitlist Joined + notification event (backend) |
| NFR01 / NFR03 / NFR06 | Clear UI, accurate occupancy, text+colour status | All of the above |

Usability tasks from M02 (run on the **APK**): **T1** find quiet+power seat (2C, 90s), **T2** reserve a slot, **T3** join waitlist and explain position.

**CRUD (minimum two working ops — Damitha should ship all four):**

| Op | User action | Frontend | Backend |
|----|-------------|----------|---------|
| **C** Create | Reserve seat / join waitlist | Details, Waitlist | `createSeatReservation`, `joinWaitlist` |
| **R** Read | Map, filters, details, my booking | Map, Filters, Details, Success | Firestore streams + queries |
| **U** Update | Change filters; leave/claim waitlist; optional slot edit | Filter sheet, Waitlist | `leaveWaitlist` / `claimWaitlistOffer`; booking cancel is shared with reservations tab |
| **D** Delete | Cancel seat booking / leave queue | Success or Bookings (coordinate with Pathiranage) | `cancelSeatReservation`, `leaveWaitlist` |

Seat **cancel** currently calls the wrong API (`leaveWaitlist` on a booking id). Damitha must fix the **domain** cancel on `SeatBooking` even if the Bookings UI belongs to another member.

---

## 3. Frontend — how it should look and behave

Campus-blue design (`AppColors`, Inter, 16px margins, 48dp targets). Structure matches Figma; motion (stagger, press scale) stays light.

### 3.1 Seat Map (P-06)

**Layout (top → bottom):**

1. Title **Seat Map** (centred). Back only when pushed from Home; on the Seats tab, hide a dead back button or make it a no-op that does not confuse testers.
2. **Floor picker** — Floor 1 / 2 / 3. **Must actually filter** seats by `seat.floor` (today the picker does not affect `SeatFilters.matches`).
3. Quick chips: Quiet Area, Power Outlet (and selected state for both at once).
4. Line: “N of M seats available” + **Filters** button.
5. **Recommendation card** (C+D): seat label, 1-line **reason** (“Quiet · Power · Window”), status pill, tap → details. If no match: “No seat matches these filters” + Reset.
6. **Map card:** 4×4 circular badges with labels (1A…4D). States:
   - Available — green fill + “Available” (semantics)
   - Limited — amber
   - Occupied — red
   - Selected — primary ring
   - Reserved by me — primary + check (when logged-in booking exists)
7. **Legend** under the grid (icon + text, not colour only).
8. Optional **Map | List** segmented control (Q9 list was 3rd; needed for TalkBack / small screens). List rows: label, zone, amenities, status.

**Data freshness:** show “Updated just now” / “Offline” when using Firestore cache.

### 3.2 Filter sheet (P-06A)

Bottom sheet: floor radios, study area checkboxes (quiet / collaborative / pod), facility toggles (power, monitor, standing desk if modelled). **Reset** and **Apply**. `matches()` must honour **floor** and **standingDesk** (standing desk is stored but ignored today).

### 3.3 Seat Details (P-07)

Hero: floor, **Seat {label}**, availability pill. Feature chips: quiet/group, power, window, monitor. **Date + time slot picker** (T2: e.g. 24 Aug 10:00–12:00). Amenities list. Primary:

- Available → **Reserve seat** (disabled until a valid future slot is chosen).
- Occupied / unavailable → **Join waiting list** → `WaitlistScreen` with **this seat’s** id (today waitlist copy is hard-coded to 2C).

“Edit” on the time row must not be a no-op.

### 3.4 Seat Success (P-08)

Green confirmation hero. Rows: booking id, seat, floor, zone, date, time. Actions: **Show QR** (Wathudura’s ticket screen, Damitha passes `SeatBooking`), **Done** → pop to shell / Bookings.

### 3.5 Waiting List (P-09) and Joined (P-09A)

P-09: warning callout for **the selected seat**, preference chips from current filters, queue preview if already waiting, **Join**.  
P-09A: “Joined waiting list”, preference, floor, **queue position #n**, estimated wait labelled as an **estimate**, Done.

Wire `WaitlistScreen` from occupied-seat details (it is mostly unused except tests today).

### 3.6 Frontend architecture (Damitha’s feature)

```text
lib/features/seats/
  presentation/   seat_map, filter_sheet, detail, confirmation
  application/    seat_map_controller, booking_controller, recommendation
  domain/         Seat, SeatFilters, SeatBooking, SeatRepository
lib/features/waitlist/
  presentation/   waitlist_screen, waitlist_joined_screen
  application/    waitlist_controller
  domain/         WaitlistEntry, WaitlistRepository
```

Controllers call repositories, never `FirebaseFirestore.instance` from widgets. Keep `FakeSeatRepository` from `MockData` for widget tests.

**Recommendation algorithm (client, after filtered list):** among `available` seats matching filters, score: quiet +3, power +3, window +2, monitor +1, prefer current floor. Show the **winning seat and the reasons**. Server may later return the same ranking.

### 3.7 Prototype gaps Damitha must close

| Gap | File / behaviour today | Fix |
|-----|------------------------|-----|
| Floor picker does not filter | `SeatFilters.matches` ignores `floor` | Compare `seat.floor` to selected floor |
| Standing desk ignored | `matches` skips `standingDesk` | Filter or drop the toggle |
| Recommendation has no “why” | first available-with-power | Reason chips on the card |
| Fixed 14:00–17:00 slot | `AppState.reserveSeat` | Real slot UI + API |
| Waitlist screen hard-coded 2C | `waitlist_screen.dart` | Pass `Seat` + filters |
| Waitlist screen not in main flow | Details jumps to joined only | Navigate to P-09 then P-09A |
| Map back button on tab | `maybePop()` on root tab | Hide leading on tab |
| No list mode | Grid only | Map/List toggle |
| Seat cancel broken | reservations uses `leaveWaitlist` | `cancelSeatReservation` |
| Occupancy not live | static `MockData.seats` | Firestore status / slot occupancy |

---

## 4. Backend — Firebase for Damitha’s domain

Authoritative rules: no client invents “this seat is free.” Writes for reserve / cancel / waitlist go through **callable functions** (or equivalent transactions). Reads may be direct Firestore with Rules.

### 4.1 Collections (Damitha-owned data)

**`/libraries/{libraryId}/floors/{floorId}`**  
name, order, map version.

**`/libraries/{libraryId}/seats/{seatId}`**  
`label` (e.g. `2C`), `floor`, `section`, `row`, `col`, `category` (`quietZone` \| `collaborative` \| `individualPod`), `hasPowerOutlet`, `hasMonitor`, `nearWindow`, `standingDesk`, `operationalStatus` (`open` \| `blocked`).

**`/seatSlots/{slotId}`** (id = `{seatId}_{utcStart}`)  
`seatId`, `libraryId`, `startsAt`, `endsAt`, `status` (`free` \| `held` \| `booked`), `reservationId`, `ownerUid`. **Unique slot = no double booking.**

**`/reservations/{reservationId}`** (`type: "seat"`)  
owner, seat snapshot (label, floor, amenities), start/end, check-in deadline, status, QR eligibility, idempotency key.

**`/waitlistEntries/{entryId}`** (`resourceType: "seat"`)  
owner, `seatId` or preference query, status, join time, position projection, `offerId`.

**`/waitlistOffers/{offerId}`**  
offered uid, expiry, claimed reservation.

**`/notifications/{id}`**  
created by functions on reserve / waitlist join / seat freed (FR14).

Seed for demos/T1: **16 seats**, Floor 2 Quiet Wing, **2C** available with quiet + power + window.

### 4.2 Callable APIs Damitha implements / owns

| Function | Auth | Behaviour |
|----------|------|-----------|
| `createSeatReservation({ seatId, startsAt, endsAt, idempotencyKey })` | Student | Check hours, user limits, slot free; transaction writes slot + reservation; notify |
| `cancelSeatReservation({ reservationId, reason, idempotencyKey })` | Owner or staff | Release slot; promote waitlist |
| `joinWaitlist({ seatId?, preferences, idempotencyKey })` | Student | One active seat wait per user/resource; return position |
| `leaveWaitlist({ entryId })` | Owner | Remove; recompute positions |
| `claimWaitlistOffer({ offerId, idempotencyKey })` | Offered user | Creates reservation if still free |

Staff `verifyQrToken` / check-in is **Wathudura**; Damitha only ensures the booking record and slot times are correct so QR can be issued.

**FR14:** when `cancelSeatReservation` or expiry frees a matching seat, a background function creates an offer + FCM/in-app notification. Damitha owns the **waitlist data and notify trigger**, not the FCM plugin wiring.

### 4.3 Transaction sketch (create)

1. Verify App Check + Auth.  
2. Reject past slots / closed hours.  
3. Read `seats/{id}` (must be `open`).  
4. Read/create `seatSlots/{seatId}_{start}`. If not `free`, fail `reservation-conflict`.  
5. Count user’s overlapping seat reservations; enforce policy (e.g. 1 active seat).  
6. Write reservation `confirmed`, slot `booked`, server timestamps.  
7. Enqueue confirmation notification (FR12/FR17).

Idempotency: same key returns the existing reservation.

### 4.4 Security rules (seats)

- Signed-in users **read** seats, floors, public occupancy projections.  
- Users **read** only their seat reservations and waitlist entries.  
- **No** client write to `seatSlots`, reservation status, or waitlist position.  
- Staff may **read** occupancy for operations (NFR04 still via claims).

### 4.5 Indexes / queries

- Seats by `libraryId` + `floor` + `operationalStatus`.  
- Slots by `seatId` + `startsAt`.  
- Reservations by `ownerUid` + `type` + `status` + `startsAt`.  
- Waitlist by `resourceType` + `seatId` + `status` + `joinedAt`.

---

## 5. End-to-end flows (Damitha)

**Happy path (T1–T2)**  
Seats tab → Floor 2 → Quiet + Power → recommendation **2C** (reason visible) → Details → pick date/time → Reserve → Success → booking appears in Bookings → Seats.

**Waitlist (T3)**  
Select occupied seat → Join waiting list → see **#position** → when that seat’s booking is cancelled/expired → notification “seat available” → claim or expire.

**Conflict**  
Two clients reserve the same slot → second gets `reservation-conflict` → map refreshes occupied.

---

## 6. Fidelity vs Figma (report table — fill as you go)

| Item | Figma | Implementation | OK / deviation |
|------|-------|----------------|----------------|
| Map + filters + recommend 2C | C+D | Required | Must match |
| Legend | Required | Required | Must match |
| Filter sheet | P-06A | Required | Must match |
| Success screen | P-08 | Required | Must match |
| Waitlist position | P-09A | Required | Must match |
| List as primary | Rejected in 3.1 | Optional Map/List | Justify: Q9 + a11y |
| Google-backed occupancy | Prototype fake | Firestore | Justify: M03 working app |
| Time slot picker | T2 specific time | Required | Was missing in prototype code |

---

## 7. Tests Damitha owns

**Functional (trace to FR):**

| ID | Case | Expect |
|----|------|--------|
| ST-01 | Open map | Grid + counts + legend (FR08) |
| ST-02 | Floor 2 only | Other floors hidden |
| ST-03 | Quiet + power | 2C recommended with reason (FR10, T1) |
| ST-04 | Open 2C details | Power, quiet, window shown (FR09) |
| ST-05 | Reserve valid slot | Success + reservation doc + slot booked (FR11–12) |
| ST-06 | Double book same slot | Second fails |
| ST-07 | Occupied → join waitlist | Position shown (FR13) |
| ST-08 | Cancel booking | Slot free; waitlisted user notified (FR14–15) |
| ST-09 | Invalid / past slot | Reserve disabled + error |

Widget tests: map, filter sheet, details (available vs occupied), confirmation, waitlist joined. Emulator: conflict + waitlist promote.

---

## 8. Implementation order (Damitha)

1. Fix `SeatFilters.matches` (floor, standing desk) and recommendation **reason**.  
2. Wire `WaitlistScreen` with real `Seat`; hide bogus tab back button.  
3. Date/time slots in UI (even if first backend is fake repo).  
4. `SeatRepository` + `WaitlistRepository` (fake → Firestore).  
5. Callables: create / cancel / join / leave; then offer/notify.  
6. List toggle, semantics, 48dp, legend.  
7. Functional + emulator tests; screenshots for the report.  
8. APK path T1–T3 for usability.

---

## 9. Viva (Damitha)

Be able to:

1. Open Seat Map, apply Quiet + Power, point at **2C** and say **why** it was recommended (Q9, variants C+D).  
2. Reserve a **chosen** time slot and show Firestore (or emulator) reservation + slot document.  
3. Show occupied path → waitlist **position**.  
4. Name **FR08–FR14** and two CRUD ops you implemented.  
5. Name one Figma deviation (e.g. list mode or live data) and why.

Do not read this file aloud. Explain from the running app.
