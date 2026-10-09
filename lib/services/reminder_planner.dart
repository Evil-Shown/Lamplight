import '../models/models.dart';

/// One on-device reminder to schedule. [key] is stable per event so a
/// reschedule replaces the earlier one.
class PlannedReminder {
  const PlannedReminder({
    required this.key,
    required this.when,
    required this.title,
    required this.body,
  });

  final String key;
  final DateTime when;
  final String title;
  final String body;
}

const Duration kSeatReminderLead = Duration(minutes: 30);
const Duration kPickupReminderLead = Duration(hours: 2);
const Duration kLoanReminderLead = Duration(days: 2);

/// Pure planner for the local-notification fallback. Server reminders are
/// authoritative; these cover the device being offline. Only future times
/// are returned, and nothing at all when reminders are switched off.
List<PlannedReminder> planReminders({
  required DateTime now,
  required NotificationPreferences prefs,
  required Iterable<SeatBooking> bookings,
  required Iterable<BookReservation> reservations,
  required Iterable<Loan> loans,
}) {
  if (!prefs.remindersEnabled) return const [];
  final out = <PlannedReminder>[];

  void add(String key, DateTime when, String title, String body) {
    if (when.isAfter(now)) {
      out.add(PlannedReminder(key: key, when: when, title: title, body: body));
    }
  }

  if (prefs.reminderBeforeStart) {
    for (final b in bookings) {
      if (b.checkedInAt != null ||
          b.status == ReservationStatus.cancelled ||
          b.status == ReservationStatus.completed) {
        continue;
      }
      add(
        'seat:${b.id}',
        b.startTime.subtract(kSeatReminderLead),
        'Seat session starts soon',
        'Seat ${b.seat.label} is booked from your start time. '
            'Check in within 15 minutes.',
      );
    }
  }

  if (prefs.reminderBeforeExpiry) {
    for (final r in reservations) {
      if (r.status == ReservationStatus.cancelled ||
          r.status == ReservationStatus.completed) {
        continue;
      }
      add(
        'pickup:${r.id}',
        r.pickupBy.subtract(kPickupReminderLead),
        'Pick up your book',
        '${r.book.title} is held for you for about two more hours.',
      );
    }
  }

  if (prefs.loanReminders) {
    for (final l in loans) {
      if (l.isReturned) continue;
      add(
        'loan2:${l.id}',
        l.dueAt.subtract(kLoanReminderLead),
        'Book due in 2 days',
        '${l.title} is due back soon.',
      );
      add(
        'loan0:${l.id}',
        l.dueAt,
        'Book due today',
        '${l.title} is due now. Return or renew to avoid a fine.',
      );
    }
  }
  return out;
}
