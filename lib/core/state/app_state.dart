import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase/firestore_service.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import '../../services/notification_service.dart';

/// Single source of truth for everything the prototype shows across
/// screens. Backed by Firebase Auth + Cloud Firestore: the catalog, seat
/// map and every user collection stream in real time, and writes below are
/// persisted through [FirestoreService].
class AppState extends ChangeNotifier {
  AppState();

  final FirestoreService _service = FirestoreService.instance;
  final List<StreamSubscription> _subscriptions = [];

  UserProfile? _profile;
  List<Book> _books = MockData.books;
  List<Seat> _seats = MockData.seats;
  final List<BookReservation> _reservations = MockData.buildReservations();
  final List<SeatBooking> _bookings = MockData.buildBookings();
  final List<WaitlistEntry> _waitlist = MockData.buildWaitlist();
  final List<AppNotification> _notifications = MockData.buildNotifications();
  List<QueueEntry> _queue = MockData.buildQueue();
  final Map<String, SeatStatus> _seatStatus = {};
  final Set<String> _seenNotificationIds = {};

  bool _syncing = false;
  final Set<String> _pendingLocalWrites = {};

  NotificationPreferences _preferences = const NotificationPreferences();
  ThemeMode _themeMode = ThemeMode.light;

  UserProfile? get profile => _profile;
  bool get isSignedIn => _profile != null;
  bool get isStaff => _profile?.role == UserRole.staff;

  List<BookReservation> get reservations =>
      List.unmodifiable(_reservations);
  List<SeatBooking> get bookings => List.unmodifiable(_bookings);
  List<WaitlistEntry> get waitlist => List.unmodifiable(_waitlist);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<QueueEntry> get queue => List.unmodifiable(_queue);
  NotificationPreferences get preferences => _preferences;
  ThemeMode get themeMode => _themeMode;

  List<Book> get books => _books;
  List<Seat> get seats => [
        for (final seat in _seats)
          seat.copyWith(status: _seatStatus[seat.id] ?? seat.status),
      ];
  UserProfile get activeProfile => _profile ?? MockData.student;

  /// Books waiting for collection, newest deadline first.
  List<BookReservation> get activeReservations => _reservations
      .where((r) => r.status != ReservationStatus.cancelled)
      .toList()
    ..sort((a, b) => a.pickupBy.compareTo(b.pickupBy));

  List<BookReservation> get reservationHistory => _reservations
      .where((r) => r.status == ReservationStatus.cancelled)
      .toList();

  SeatBooking? get todayBooking {
    if (_bookings.isEmpty) return null;
    return _bookings.first;
  }

  int get unreadNotifications => _notifications.length;

  // ------------------------------------------------------------------- auth

  Future<void> signIn({required String identifier, required UserRole role}) async {
    _profile = await _service.signIn(identifier, role);
    _queue = MockData.buildQueue();
    _startListeners();
    notifyListeners();
    unawaited(NotificationService.instance.init());
  }

  /// Restores the Firebase session on cold start.
  Future<void> restoreSession() async {
    if (_profile != null || !_service.isReady) return;
    final profile = await _service.loadProfile();
    if (profile == null) return;
    _profile = profile;
    _startListeners();
    notifyListeners();
    unawaited(NotificationService.instance.init());
  }

  Future<void> signOut() async {
    await _service.signOut();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _reservations.clear();
    _bookings.clear();
    _waitlist.clear();
    _notifications.clear();
    _seatStatus.clear();
    _seenNotificationIds.clear();
    _profile = null;
    notifyListeners();
  }

  // -------------------------------------------------------------- listeners

  void _startListeners() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();

    void push() {
      if (_syncing) return;
      notifyListeners();
    }

    _subscriptions.add(_service.booksStream().listen((books) {
      _books = books.isEmpty ? MockData.books : books;
      push();
    }));

    _subscriptions.add(_service.seatsStream().listen((seats) {
      _seats = seats.isEmpty ? MockData.seats : seats;
      push();
    }));

    _subscriptions.add(_service.userReservationsSnapshot().listen((snap) {
      _syncing = true;
      _reservations
        ..clear()
        ..addAll([
          for (final doc in snap.docs)
            _service.reservationFromMapPublic(
                doc.data(), doc.id, _books),
        ]);
      _syncing = false;
      notifyListeners();
    }));

    _subscriptions.add(_service.userBookingsSnapshot().listen((snap) {
      _syncing = true;
      _bookings
        ..clear()
        ..addAll([
          for (final doc in snap.docs)
            _service.bookingFromMapPublic(
                doc.data(), doc.id, _seats),
        ]);
      _syncing = false;
      notifyListeners();
    }));

    _subscriptions.add(_service.userNotificationsSnapshot().listen((snap) {
      _syncing = true;
      final fresh = <String>[];
      for (final doc in snap.docs) {
        if (_seenNotificationIds.add(doc.id)) {
          fresh.add(doc.id);
          final n = _service.notificationFromMapPublic(doc.data(), doc.id);
          final idx =
              _notifications.indexWhere((existing) => existing.id == doc.id);
          if (idx == -1) {
            _notifications.insert(0, n);
          } else {
            _notifications[idx] = n;
          }
          // Real device notification for anything this device did not
          // just write itself (e.g. a waitlist offer).
          if (!_pendingLocalWrites.remove(doc.id)) {
            unawaited(NotificationService.instance
                .showLocal(title: n.title, body: n.body));
          }
        }
      }
      _syncing = false;
      if (fresh.isNotEmpty) notifyListeners();
    }));

    _subscriptions.add(_service.userWaitlistSnapshot().listen((snap) {
      _syncing = true;
      _waitlist
        ..clear()
        ..addAll([
          for (final doc in snap.docs)
            _service.waitlistFromMapPublic(
                doc.data(), doc.id),
        ]);
      _syncing = false;
      notifyListeners();
    }));

    if (_profile?.role == UserRole.staff) {
      _subscriptions.add(_service.queueSnapshot().listen((snap) {
        _syncing = true;
        _queue = [
          for (final doc in snap.docs)
            () {
              final data = doc.data();
              return QueueEntry(
                id: doc.id,
                studentName: data['studentName'] as String? ?? '',
                studentId: data['studentId'] as String? ?? '',
                location: data['location'] as String? ?? '',
                requestedAt:
                    (data['requestedAt'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                status: QueueStatus.values.firstWhere(
                  (v) => v.name == data['status'],
                  orElse: () => QueueStatus.pending,
                ),
              );
            }(),
        ];
        _syncing = false;
        notifyListeners();
      }));
    }
  }

  // ------------------------------------------------------------ reservations

  BookReservation reserveBook(Book book) {
    final now = DateTime.now();
    final index = 100 + _reservations.length;
    final reservation = BookReservation(
      id: 'BR-2026-$index',
      book: book,
      reservedAt: now,
      pickupBy: now.add(const Duration(days: 7)),
      pickupLocation: 'Main Library',
      qrCode: 'LIB-BR-2026-$index',
      status: ReservationStatus.ready,
    );
    _reservations.insert(0, reservation);
    _notify(BannerToneKind.success, 'Book Reservation Confirmed',
        '${book.title} has been reserved successfully.',
        icon: Icons.check_circle_outline_rounded);
    _service.addReservation(reservation);
    notifyListeners();
    return reservation;
  }

  void cancelReservation(String id) {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final reservation = _reservations[index];
    _reservations[index] = reservation.copyWith(
      status: ReservationStatus.cancelled,
    );
    _notify(BannerToneKind.danger, 'Reservation Cancelled',
        'Your reservation for ${reservation.book.title} has been '
            'cancelled successfully.',
        icon: Icons.cancel_outlined);
    _service.updateReservationStatus(id, ReservationStatus.cancelled);
    notifyListeners();
    // The copy is free again — offer it to the next person waiting.
    unawaited(_service.promoteNextOnWaitlist(
      resourceTitle: reservation.book.title,
      resourceSubtitle: reservation.book.shelfLocation,
    ));
  }

  /// Returns null when the seat was just taken by someone else.
  SeatBooking? reserveSeat(
    Seat seat, {
    DateTime? start,
    DateTime? end,
  }) {
    final current = _seats
        .where((s) => s.id == seat.id)
        .firstOrNull;
    if (current != null &&
        _seatStatus[current.id] == SeatStatus.occupied) {
      return null;
    }
    final now = DateTime.now();
    final startTime = start ?? DateTime(now.year, now.month, now.day, 14);
    final endTime = end ?? DateTime(now.year, now.month, now.day, 17);
    final booking = SeatBooking(
      id: 'LIB-2026-${4851 + _bookings.length}',
      seat: seat,
      date: DateTime(startTime.year, startTime.month, startTime.day),
      startTime: startTime,
      endTime: endTime,
      qrCode: 'LIB-2026-${4851 + _bookings.length}',
      status: ReservationStatus.active,
    );
    _bookings.insert(0, booking);
    _seatStatus[seat.id] = SeatStatus.occupied;
    _notify(BannerToneKind.success, 'Seat Reservation Confirmed',
        'Seat ${seat.label} is reserved for today.',
        icon: Icons.event_seat_rounded);
    // Atomic on the server: a losing racer gets reverted by the snapshot.
    unawaited(_service.addBooking(booking, SeatStatus.occupied));
    notifyListeners();
    return booking;
  }

  void cancelSeatBooking(String id) {
    final index = _bookings.indexWhere((booking) => booking.id == id);
    if (index == -1) return;
    final booking = _bookings.removeAt(index);
    _seatStatus[booking.seat.id] = SeatStatus.available;
    _notify(BannerToneKind.danger, 'Seat booking cancelled',
        'Seat ${booking.seat.label} has been released.',
        icon: Icons.event_seat_outlined);
    unawaited(_service.deleteBooking(booking));
    notifyListeners();
    // The seat is free — offer it to the next person waiting.
    unawaited(_service.promoteNextOnWaitlist(
      resourceTitle: 'Seat ${booking.seat.label}',
      resourceSubtitle: 'Floor ${booking.seat.floor} – '
          '${booking.seat.section}',
    ));
  }

  void checkIn() {
    if (_bookings.isEmpty) return;
    _bookings[0] = _bookings[0].copyWith(
      status: ReservationStatus.active,
      checkedInAt: DateTime.now(),
    );
    _service.checkInBooking(_bookings[0].id);
    notifyListeners();
  }

  // --------------------------------------------------------------- waitlist

  WaitlistEntry joinWaitlist({
    required String title,
    required String subtitle,
    String? seatPreference,
  }) {
    final entry = WaitlistEntry(
      id: 'w${DateTime.now().millisecondsSinceEpoch}',
      type: WaitlistType.seat,
      title: title,
      subtitle: subtitle,
      position: _waitlist.length + 1,
      joinedAt: DateTime.now(),
      estimatedWaitMinutes: 45,
      seatPreference: seatPreference,
    );
    _waitlist.add(entry);
    _service.addWaitlistEntry(entry);
    notifyListeners();
    return entry;
  }

  void leaveWaitlist(String id) {
    _waitlist.removeWhere((entry) => entry.id == id);
    _service.removeWaitlistEntry(id);
    notifyListeners();
  }

  // ------------------------------------------------------------------ staff

  void approveQueueEntry(String id) {
    final index = _queue.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final e = _queue[index];
    _queue[index] = QueueEntry(
      id: e.id,
      studentName: e.studentName,
      studentId: e.studentId,
      location: e.location,
      requestedAt: e.requestedAt,
      status: QueueStatus.active,
    );
    _service.updateQueueStatus(id, QueueStatus.active);
    notifyListeners();
  }

  void dismissQueueEntry(String id) {
    _queue.removeWhere((e) => e.id == id);
    _service.deleteQueueEntry(id);
    notifyListeners();
  }

  // ----------------------------------------------------------- preferences

  void updatePreferences(NotificationPreferences prefs) {
    _preferences = prefs;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void _notify(BannerToneKind tone, String title, String body,
      {IconData? icon}) {
    final n = AppNotification(
      id: 'n${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      tone: tone,
      icon: icon,
    );
    _notifications.insert(0, n);
    // Written on this device — the in-app feed already shows it, so mark
    // it seen and suppress the duplicate device notification.
    _seenNotificationIds.add(n.id);
    _pendingLocalWrites.add(n.id);
    _service.addNotification(n);
  }
}

/// Exposes [AppState] to the widget tree without pulling in a DI package.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in the widget tree');
    return scope!.notifier!;
  }

  /// Reads the state without subscribing — for callbacks.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in the widget tree');
    return scope!.notifier!;
  }
}
