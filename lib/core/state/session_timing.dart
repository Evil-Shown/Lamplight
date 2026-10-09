import '../../models/models.dart';

/// How long after the booking start a student may still check in.
const Duration kCheckInGrace = Duration(minutes: 15);

/// Pure countdown helpers. Everything derives from stored timestamps and a
/// supplied `now`, so nothing derived is ever persisted.

/// The moment the seat is released if the student has not checked in.
DateTime checkInDeadline(SeatBooking b, {Duration grace = kCheckInGrace}) =>
    b.startTime.add(grace);

/// Time left to check in, clamped at zero. Null once checked in or when the
/// booking is no longer live (completed / cancelled).
Duration? graceRemaining(SeatBooking b, DateTime now,
    {Duration grace = kCheckInGrace}) {
  if (b.checkedInAt != null) return null;
  if (b.status == ReservationStatus.cancelled ||
      b.status == ReservationStatus.completed) {
    return null;
  }
  final left = checkInDeadline(b, grace: grace).difference(now);
  return left.isNegative ? Duration.zero : left;
}

/// Time left to collect a reserved book, clamped at zero. Null when the
/// reservation was collected or cancelled.
Duration? pickupRemaining(BookReservation r, DateTime now) {
  if (r.status == ReservationStatus.completed ||
      r.status == ReservationStatus.cancelled) {
    return null;
  }
  final left = r.pickupBy.difference(now);
  return left.isNegative ? Duration.zero : left;
}

/// Time left to answer a waitlist offer, clamped at zero. Null when there is
/// no pending offer.
Duration? offerRemaining(WaitlistEntry e, DateTime now) {
  final until = e.offerExpiresAt;
  if (!e.isOffered || until == null) return null;
  final left = until.difference(now);
  return left.isNegative ? Duration.zero : left;
}
