# Backend contract (Firestore + Cloud Functions)

Callables live in the default region (us-central1). Timestamps: Firestore `Timestamp` in docs, ISO-8601 strings in callable responses. Auth claim: `role` = `staff` | `student` (token claim, set by `claimRole`; call `getIdToken(true)` after).

## Roles
- `claimRole()` -> `{role}`. Call after every sign-in, then refresh the token. Staff = email in `config/staffAllowlist.emails` AND email verified (emulator: verification not required).
- `users/{uid}.role` is a server-maintained mirror (only written if the profile exists). Clients must NOT write `role`, `strikes`, `finesTotal`. Write profile with `set(..., merge: true)` / `update` only with: `name, studentId, email, reservationsVisibleToStaffOnly, notificationPrefs, createdAt, updatedAt`.
- `notificationPrefs` map: `pushEnabled, emailEnabled, smsEnabled, reminderBeforeStart, reminderBeforeExpiry, waitlistUpdates` (bools, default true).

## Status set
`ready, active, expiringSoon, completed, cancelled, expired, noShow` (add `expired`, `noShow` to ReservationStatus).

## Collections
- `config/library` (signed-in read only): `currency, finePerDay, fineCap, loanDays, renewDays, maxRenewals, seatGraceMinutes, seatEarlyCheckInMinutes, pickupWindowDays, waitlistOfferMinutes, seatReminderMinutes, pickupReminderHours, dueSoonDays, dueDayHours`. `config/staffAllowlist` is never client-readable.
- `books/{id}` (staff write): `title, author, subject, isbn, shelfLocation, copiesAvailable, availability, description, coverColor, dueDate, titleLower, authorLower, createdAt`. `copiesAvailable` is changed only by functions.
- `seats/{id}` (clients: update only): `status` (available|limited|occupied), `heldBy` (uid|null), `bookingId` (string|null), server-only `heldFor` (uid|null), `heldUntil`. Student take: `{status:'occupied', heldBy: uid, bookingId}` from available/limited while `heldFor` is null or self. Release: `{status:'available', heldBy:null, bookingId:null}` by the holder. Treat `heldFor != null && != me` as unavailable.
- `users/{uid}/reservations/{id}` (book). Client create keys ONLY: `bookId, bookTitle, reservedAt, pickupBy, pickupLocation, qrCode, status('ready'|'active'), userId(=uid)`; id matches `[A-Za-z0-9_-]{1,64}`. Server adds: `qrNonce, qrPass, copyHeld, copyReleased, createdAt, qrUsedAt, verifiedBy, expiredAt, cancelReason('noCopies'), loanId, fromWaitlistOffer, remindersSent{}`. Owner update: `status` -> `cancelled` only (from open status). Show `qrPass` as the QR payload once it exists (a second after create); `qrCode` is the short manual code. Never deleted by clients.
- `users/{uid}/bookings/{id}` (seat). Client create keys ONLY: `seatId, date, startTime, endTime, qrCode, status('ready'|'active'), checkedInAt(null), userId`. Server adds `qrNonce, qrPass, createdAt, qrUsedAt, verifiedBy, noShowAt, remindersSent{}`. Owner update: `status` -> `cancelled`, or `completed` if `checkedInAt` set. Clients cannot set `checkedInAt` (use staff scan -> `verifyQrPass`). Owner delete allowed only while open and not checked in.
- `users/{uid}/waitlist/{id}`. Client create keys ONLY: `type('book'|'seat'), title, subtitle, position, joinedAt, estimatedWaitMinutes, seatPreference, resourceId (bookId or seatId, required), userId, status:'waiting', date, startTime, endTime`. Server adds `queuedAt, offeredAt, offerExpiresAt, closedAt, resultDocId`. `status` values: `waiting, offered, accepted, declined, expired`. Hide non-waiting/offered entries in the UI. Owner update: `seatPreference` only; owner may delete (leave). Answer offers via `respondToWaitlistOffer`. Seat waitlists are per specific seat id.
- `users/{uid}/notifications/{id}` (server/staff create). Fields: `type, title, body, tone(info|success|warning|danger), iconCodePoint, refPath, read(bool), timestamp`. Owner may only update `read` (bool) or delete. Clients can no longer create notifications. `type` values: `seatReminder, pickupReminder, dueSoon, dueToday, waitlistOffer, waitlistExpired, reservationExpired, reservationCancelled, seatNoShow, fineAccrued, loanRenewed, info`.
- `users/{uid}/devices/{token}`: `token, platform, updatedAt, appVersion?, locale?` (owner write).
- `users/{uid}/strikes/{bookingId}`: read-only (owner/staff).
- `loans/{loanId}` (top level; student queries MUST filter `where('userId','==',uid)`): `userId, bookId, bookTitle, checkedOutAt, dueDate, returnedAt, status(active|overdue|returned), renewals, renewalRequested, fineAccrued, fineCurrency, lastFineAt, reservationId, remindersSent{}, createdBy`. Student may write only `renewalRequested` (bool). Staff read/write.
- `queue/{id}`: staff only. Staff admin lists may use collection-group queries on `reservations`, `bookings`, `waitlist` (staff-only read; students use their own subcollection).

## Callables (all error as `HttpsError`; codes: unauthenticated, permission-denied, invalid-argument, not-found, failed-precondition)
- `claimRole()` -> `{role}`
- `verifyQrPass({code, consume?=true})` (staff) -> `{result: valid|alreadyUsed|tooEarly|expired|cancelled|notFound|malformed, consumed, kind:'seat'|'book', docPath, status, seatId, bookId, bookTitle, startTime, endTime, pickupBy, ownerUid, ownerName, ownerStudentId}` (the detail fields are absent for notFound/malformed). `code` = `qrPass` string, or the short `qrCode` for manual entry. Consuming: seat -> `checkedInAt`, status `active`; book -> status `completed`. Pass `consume:false` for a book when the next step is `checkoutBook`.
- `respondToWaitlistOffer({entryId, accept})` -> `{status:'accepted'|'declined', kind:'book'|'seat', docId?}`; on accept `docId` is the new reservation/booking id (`wl-<entryId>`). Idempotent.
- `renewLoan({loanId})` -> `{loanId, dueDate, renewals}`. Fails if overdue, renewals >= max, or someone is waiting.
- `checkoutBook({userId, bookId, reservationId?, loanDays?})` (staff) -> `{loanId, dueDate}`.
- `checkinBook({loanId})` (staff) -> `{loanId, fineAccrued, fineCurrency}`.
- `exportAccountData()` -> `{exportedAt, uid, profile, reservations, bookings, waitlist, notifications, loans, strikes}`.
- `deleteAccountData()` -> `{deleted:true}`; fails while books are on loan. Sign out afterwards.

## Server behaviour the UI can rely on
- Reservation create allocates a copy (cancelled with `cancelReason:'noCopies'` if none). Cancel/expiry returns the copy or offers it to the next waitlisted student (offer valid `waitlistOfferMinutes`).
- Seat not checked in `seatGraceMinutes` after `startTime` -> `noShow`, seat freed, strike recorded.
- Reminders (FCM + in-app): seat start -30 min, pickup -2 h, loan due in 2 days and on the due day; respect `notificationPrefs`.
- Fines accrue daily: `finePerDay` per full overdue day, capped at `fineCap` per loan; `users/{uid}.finesTotal` is the running total.
- Client Firestore indexes: books search needs `titleLower`/`authorLower` (lower-case copies written by seed/staff tooling).
