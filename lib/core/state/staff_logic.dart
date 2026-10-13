import 'package:intl/intl.dart';

import '../../models/models.dart';
import 'session_timing.dart';

/// The most a single extension may add to a seat booking.
const Duration kMaxExtension = Duration(hours: 2);

/// Staff-facing state of a reservation, derived from stored timestamps and a
/// supplied `now`; never persisted.
enum StaffResState { pending, active, expired, completed, cancelled }

/// Derives the state of [r] at [now].
///
/// Seat bookings are `pending` until staff check the student in, `active`
/// afterwards, and `expired` once the booked window has ended. Book
/// reservations are `pending` (awaiting pickup) until the pickup deadline.
StaffResState staffReservationState(AdminReservation r, DateTime now) {
  switch (r.status) {
    case ReservationStatus.completed:
      return StaffResState.completed;
    case ReservationStatus.cancelled:
      return StaffResState.cancelled;
    case ReservationStatus.ready:
    case ReservationStatus.active:
    case ReservationStatus.expiringSoon:
      break;
  }
  final end = r.isSeat ? (r.endAt ?? r.dueAt) : r.dueAt;
  if (end != null && now.isAfter(end)) return StaffResState.expired;
  if (r.isSeat && r.checkedInAt != null) return StaffResState.active;
  return StaffResState.pending;
}

/// Filter bucket / badge word for a reservation: 'Pending', 'Active',
/// 'Expired', 'Completed' or 'Cancelled'.
String staffReservationStatusLabel(AdminReservation r, [DateTime? now]) =>
    switch (staffReservationState(r, now ?? DateTime.now())) {
      StaffResState.pending => 'Pending',
      StaffResState.active => 'Active',
      StaffResState.expired => 'Expired',
      StaffResState.completed => 'Completed',
      StaffResState.cancelled => 'Cancelled',
    };

String _two(int n) => n.toString().padLeft(2, '0');

String _hm(DateTime d) => DateFormat('HH:mm').format(d);

/// "1h 18m" / "42m"; never negative.
String _span(Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  final h = total.inHours;
  final m = total.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  return '${total.inMinutes}m';
}

/// "+30m" / "+1h 05m" for how long past a deadline.
String _over(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h > 0 ? '+${h}h ${_two(m)}m' : '+${d.inMinutes}m';
}

/// The one-line time note for a reservation: "1h 18m left", "Starts 14:15",
/// "04:31 grace", "No-show", "+30m overdue".
String staffTimeNote(AdminReservation r, DateTime now,
    {Duration grace = kCheckInGrace}) {
  switch (staffReservationState(r, now)) {
    case StaffResState.completed:
      return 'Completed';
    case StaffResState.cancelled:
      return 'Cancelled';
    case StaffResState.expired:
      final end = (r.isSeat ? r.endAt : null) ?? r.dueAt;
      return end == null ? 'Expired' : '${_over(now.difference(end))} overdue';
    case StaffResState.active:
      final end = r.endAt ?? r.dueAt;
      return end == null ? 'Active' : '${_span(end.difference(now))} left';
    case StaffResState.pending:
      if (!r.isSeat) {
        final due = r.dueAt;
        return due == null ? 'Awaiting pickup' : '${_span(due.difference(now))} left';
      }
      final start = r.startAt ?? r.reservedAt;
      if (now.isBefore(start)) return 'Starts ${_hm(start)}';
      final left = start.add(grace).difference(now);
      if (left.isNegative || left == Duration.zero) return 'No-show';
      return '${_two(left.inMinutes)}:${_two(left.inSeconds.remainder(60))} grace';
  }
}

/// The note shown opposite the time note: "Since 13:08", "Reserved 14:15",
/// "Ended 14:00".
String staffContextNote(AdminReservation r, DateTime now) {
  String stamp(DateTime d) {
    final sameDay =
        d.year == now.year && d.month == now.month && d.day == now.day;
    return sameDay ? _hm(d) : DateFormat('MMM d, HH:mm').format(d);
  }

  switch (staffReservationState(r, now)) {
    case StaffResState.active:
      return 'Since ${stamp(r.checkedInAt ?? r.startAt ?? r.reservedAt)}';
    case StaffResState.expired:
    case StaffResState.completed:
      final end = (r.isSeat ? r.endAt : null) ?? r.dueAt;
      return end == null ? '' : 'Ended ${stamp(end)}';
    case StaffResState.pending:
    case StaffResState.cancelled:
      return 'Reserved ${stamp(r.reservedAt)}';
  }
}

/// The first other seat booking that would overlap [r] if its end moved to
/// [newEnd], or null when the seat stays free. Only live bookings of the same
/// seat that start before [newEnd] and run past [r]'s current end count.
AdminReservation? seatExtensionConflict(
  AdminReservation r,
  DateTime newEnd,
  Iterable<AdminReservation> all,
) {
  final end = r.endAt ?? r.dueAt;
  if (!r.isSeat || r.resourceId.isEmpty || end == null) return null;
  AdminReservation? first;
  for (final o in all) {
    if (!o.isSeat || o.resourceId != r.resourceId) continue;
    if (o.path == r.path && o.id == r.id) continue;
    if (o.status == ReservationStatus.cancelled ||
        o.status == ReservationStatus.completed) {
      continue;
    }
    final start = o.startAt;
    final oEnd = o.endAt ?? o.dueAt;
    if (start == null || oEnd == null) continue;
    if (!oEnd.isAfter(end) || !start.isBefore(newEnd)) continue;
    if (first == null || start.isBefore(first.startAt!)) first = o;
  }
  return first;
}

/// Quotes a CSV field when it holds a comma, quote or line break.
String csvField(String v) => v.contains(RegExp(r'[",\n\r]'))
    ? '"${v.replaceAll('"', '""')}"'
    : v;

/// CSV of [rows] for the staff export: student, studentId, type, item,
/// detail, reserved, start, end, state. Header first, `\n` between rows.
String buildReservationsCsv(Iterable<AdminReservation> rows, DateTime now) {
  String stamp(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd HH:mm').format(d);
  final lines = <String>[
    'student,studentId,type,item,detail,reserved,start,end,state',
    for (final r in rows)
      [
        r.studentName,
        r.studentId,
        r.isSeat ? 'Seat' : 'Book',
        r.itemTitle,
        r.itemSubtitle,
        stamp(r.reservedAt),
        stamp(r.startAt),
        stamp(r.isSeat ? (r.endAt ?? r.dueAt) : r.dueAt),
        staffReservationStatusLabel(r, now),
      ].map(csvField).join(','),
  ];
  return lines.join('\n');
}

/// A staff action that was refused or failed; [message] is safe to show.
class StaffActionException implements Exception {
  const StaffActionException(this.message);

  final String message;

  @override
  String toString() => message;
}
