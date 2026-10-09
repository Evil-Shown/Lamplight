// Pure-logic tests: countdowns, notification targets, search, sync status
// and reminder planning. No Firebase involved.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/core/state/session_timing.dart';
import 'package:library_app/core/state/sync_status.dart';
import 'package:library_app/data/book_search.dart';
import 'package:library_app/models/models.dart';
import 'package:library_app/services/reminder_planner.dart';

Seat _seat() => const Seat(
      id: 's1',
      label: '2C',
      floor: 2,
      section: 'A',
      status: SeatStatus.available,
      category: SeatCategory.quietZone,
      hasPowerOutlet: true,
      hasMonitor: false,
      nearWindow: false,
      row: 0,
      col: 0,
    );

Book _book(String id, String title, String author,
        {int copies = 1, String subject = 'CS', DateTime? created}) =>
    Book(
      id: id,
      title: title,
      author: author,
      subject: subject,
      isbn: 'isbn-$id',
      availability:
          copies > 0 ? BookAvailability.available : BookAvailability.onLoan,
      shelfLocation: 'A1',
      copiesAvailable: copies,
      createdAt: created,
    );

void main() {
  final now = DateTime(2026, 5, 1, 12);

  group('countdown helpers', () {
    final booking = SeatBooking(
      id: 'b1',
      seat: _seat(),
      date: DateTime(2026, 5, 1),
      startTime: DateTime(2026, 5, 1, 12),
      endTime: DateTime(2026, 5, 1, 15),
      qrCode: 'q',
    );

    test('check-in deadline is start plus grace', () {
      expect(checkInDeadline(booking), DateTime(2026, 5, 1, 12, 15));
    });

    test('graceRemaining counts down and clamps at zero', () {
      expect(graceRemaining(booking, DateTime(2026, 5, 1, 12, 5)),
          const Duration(minutes: 10));
      expect(graceRemaining(booking, DateTime(2026, 5, 1, 13)), Duration.zero);
    });

    test('graceRemaining is null once checked in or cancelled', () {
      expect(
          graceRemaining(
              booking.copyWith(checkedInAt: DateTime(2026, 5, 1, 12, 1)), now),
          isNull);
      expect(
          graceRemaining(
              booking.copyWith(status: ReservationStatus.cancelled), now),
          isNull);
    });

    test('pickupRemaining derives from pickupBy', () {
      final r = BookReservation(
        id: 'r',
        book: _book('1', 'T', 'A'),
        reservedAt: now,
        pickupBy: now.add(const Duration(hours: 5)),
        pickupLocation: 'Desk',
        qrCode: 'q',
      );
      expect(pickupRemaining(r, now), const Duration(hours: 5));
      expect(
          pickupRemaining(r, now.add(const Duration(days: 1))), Duration.zero);
      expect(
          pickupRemaining(r.copyWith(status: ReservationStatus.completed), now),
          isNull);
    });

    test('offerRemaining only for offered entries', () {
      final e = WaitlistEntry(
        id: 'w',
        type: WaitlistType.book,
        title: 't',
        subtitle: 's',
        position: 1,
        joinedAt: now,
        status: WaitlistStatus.offered,
        offerExpiresAt: now.add(const Duration(minutes: 30)),
      );
      expect(offerRemaining(e, now), const Duration(minutes: 30));
      expect(offerRemaining(e.copyWith(status: WaitlistStatus.waiting), now),
          isNull);
    });
  });

  group('NotificationTarget', () {
    test('parses type and targetId', () {
      final t = NotificationTarget.fromMap({'type': 'offer', 'targetId': 'w1'});
      expect(t.type, NotificationType.offer);
      expect(t.id, 'w1');
      expect(t.hasTarget, isTrue);
    });

    test('falls back to legacy id fields', () {
      final t = NotificationTarget.fromMap({'reservationId': 'BR-1'});
      expect(t.type, NotificationType.reservation);
      expect(t.id, 'BR-1');
    });

    test('understands server types and refPath', () {
      final t = NotificationTarget.fromMap({
        'type': 'waitlistOffer',
        'refPath': 'users/u1/waitlist/entry9',
      });
      expect(t.type, NotificationType.offer);
      expect(t.id, 'entry9');
      final loan = NotificationTarget.fromMap(
          {'type': 'dueSoon', 'refPath': 'loans/L1'});
      expect(loan.type, NotificationType.loan);
      expect(loan.id, 'L1');
      final byPath = NotificationTarget.fromMap(
          {'type': 'info', 'refPath': 'users/u/bookings/b7'});
      expect(byPath.type, NotificationType.booking);
    });

    test('unknown type with no id is info with no target', () {
      final t = NotificationTarget.fromMap({'type': 'weird'});
      expect(t.type, NotificationType.info);
      expect(t.hasTarget, isFalse);
    });
  });

  group('book search', () {
    final books = [
      _book('1', 'Clean Code', 'Robert Martin', copies: 0),
      _book('2', 'Algorithms', 'Sedgewick',
          copies: 3, created: DateTime(2026, 1, 1)),
      _book('3', 'Refactoring', 'Martin Fowler',
          copies: 2, subject: 'SE', created: DateTime(2026, 3, 1)),
    ];

    test('substring match on title, author and isbn', () {
      expect(filterAndSortBooks(books, query: 'martin').map((b) => b.id),
          ['1', '3']);
      expect(
          filterAndSortBooks(books, query: 'isbn-2').map((b) => b.id), ['2']);
    });

    test('subject and availableOnly filters', () {
      expect(filterAndSortBooks(books, subject: 'SE').map((b) => b.id), ['3']);
      expect(filterAndSortBooks(books, availableOnly: true).map((b) => b.id),
          ['2', '3']);
    });

    test('sorts by title, author, newest and availability', () {
      List<String> ids(BookSort s) =>
          filterAndSortBooks(books, sort: s).map((b) => b.id).toList();
      expect(ids(BookSort.title), ['2', '1', '3']);
      expect(ids(BookSort.author), ['3', '1', '2']);
      expect(ids(BookSort.newest).first, '3');
      expect(ids(BookSort.availability), ['2', '3', '1']);
    });
  });

  group('sync status', () {
    test('classifies Firebase error codes', () {
      expect(
          classifyFirestoreError(FirebaseException(
                  plugin: 'cloud_firestore', code: 'permission-denied'))
              .status,
          SyncStatus.permissionDenied);
      expect(
          classifyFirestoreError(FirebaseException(
                  plugin: 'cloud_firestore', code: 'unavailable'))
              .status,
          SyncStatus.offline);
      expect(
          classifyFirestoreError(FirebaseException(
                  plugin: 'cloud_firestore', code: 'internal'))
              .status,
          SyncStatus.error);
      expect(classifyFirestoreError(StateError('x')).status, SyncStatus.error);
    });

    SyncStatus derive({
      bool signedIn = true,
      bool hydrated = true,
      SyncError? error,
      bool cache = false,
      DateTime? last,
    }) =>
        deriveSyncStatus(
          signedIn: signedIn,
          hydrated: hydrated,
          error: error,
          allFromCache: cache,
          lastSyncedAt: last,
          now: now,
        );

    test('derives each state', () {
      expect(derive(signedIn: false), SyncStatus.signedOut);
      expect(derive(hydrated: false), SyncStatus.syncing);
      expect(derive(cache: true), SyncStatus.offline);
      expect(derive(last: now.subtract(const Duration(minutes: 1))),
          SyncStatus.live);
      expect(derive(last: now.subtract(const Duration(minutes: 30))),
          SyncStatus.stale);
      expect(derive(error: const SyncError(SyncStatus.permissionDenied, 'no')),
          SyncStatus.permissionDenied);
      expect(derive(error: const SyncError(SyncStatus.error, 'x')),
          SyncStatus.error);
      expect(derive(error: const SyncError(SyncStatus.offline, 'x')),
          SyncStatus.offline);
    });
  });

  group('reminder planner', () {
    final booking = SeatBooking(
      id: 'b1',
      seat: _seat(),
      date: DateTime(2026, 5, 1),
      startTime: now.add(const Duration(hours: 2)),
      endTime: now.add(const Duration(hours: 5)),
      qrCode: 'q',
    );
    final reservation = BookReservation(
      id: 'r1',
      book: _book('1', 'Clean Code', 'RM'),
      reservedAt: now,
      pickupBy: now.add(const Duration(hours: 10)),
      pickupLocation: 'Desk',
      qrCode: 'q',
    );
    final loan = Loan(
      id: 'l1',
      userId: 'u',
      bookId: '1',
      title: 'Clean Code',
      author: 'RM',
      checkedOutAt: now.subtract(const Duration(days: 10)),
      dueAt: now.add(const Duration(days: 3)),
    );

    List<PlannedReminder> plan(NotificationPreferences p) => planReminders(
          now: now,
          prefs: p,
          bookings: [booking],
          reservations: [reservation],
          loans: [loan],
        );

    test('plans seat, pickup and both loan reminders at the right times', () {
      final byKey = {
        for (final r in plan(const NotificationPreferences())) r.key: r.when
      };
      expect(byKey['seat:b1'], booking.startTime.subtract(kSeatReminderLead));
      expect(byKey['pickup:r1'],
          reservation.pickupBy.subtract(kPickupReminderLead));
      expect(byKey['loan2:l1'], loan.dueAt.subtract(kLoanReminderLead));
      expect(byKey['loan0:l1'], loan.dueAt);
    });

    test('respects preferences and drops past times', () {
      expect(plan(const NotificationPreferences(remindersEnabled: false)),
          isEmpty);
      final noSeat =
          plan(const NotificationPreferences(reminderBeforeStart: false));
      expect(noSeat.any((r) => r.key.startsWith('seat:')), isFalse);
      // Seat starts in 20 minutes: its 30-minute lead is already past.
      final soon = planReminders(
        now: now,
        prefs: const NotificationPreferences(),
        bookings: [
          SeatBooking(
            id: 'b2',
            seat: _seat(),
            date: now,
            startTime: now.add(const Duration(minutes: 20)),
            endTime: now.add(const Duration(hours: 3)),
            qrCode: 'q',
          ),
        ],
        reservations: const [],
        loans: const [],
      );
      expect(soon, isEmpty);
    });
  });
}
