import 'package:flutter/material.dart';

import '../../data/mock/mock_data.dart';
import '../../models/models.dart';

/// Single source of truth for everything the prototype shows across
/// screens. The old app read `MockData` statics directly, which meant a
/// reservation made on one screen never appeared on the next; keeping the
/// collections here makes the flows chain the way the mockups imply.
class AppState extends ChangeNotifier {
  AppState();

  UserProfile? _profile;
  final List<BookReservation> _reservations = MockData.buildReservations();
  final List<SeatBooking> _bookings = MockData.buildBookings();
  final List<WaitlistEntry> _waitlist = MockData.buildWaitlist();
  final List<AppNotification> _notifications = MockData.buildNotifications();
  final List<QueueEntry> _queue = MockData.buildQueue();
  final Map<String, SeatStatus> _seatStatus = {};

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

  List<Book> get books => MockData.books;
  List<Seat> get seats => [
        for (final seat in MockData.seats)
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

  void signIn({required String identifier, required UserRole role}) {
    _profile = role == UserRole.staff ? MockData.staff : MockData.student;
    notifyListeners();
  }

  void signOut() {
    _profile = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ reservations

  BookReservation reserveBook(Book book) {
    final now = DateTime.now();
    final reservation = BookReservation(
      id: 'BR-2026-${(100 + _reservations.length)}',
      book: book,
      reservedAt: now,
      pickupBy: now.add(const Duration(days: 7)),
      pickupLocation: 'Main Library',
      qrCode: 'LIB-BR-2026-${(100 + _reservations.length)}',
      status: ReservationStatus.ready,
    );
    _reservations.insert(0, reservation);
    _notifications.insert(
      0,
      AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Book Reservation Confirmed',
        body: '${book.title} has been reserved successfully.',
        timestamp: now,
        tone: BannerToneKind.success,
        icon: Icons.check_circle_outline_rounded,
      ),
    );
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
    _notifications.insert(
      0,
      AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Reservation Cancelled',
        body: 'Your reservation for ${reservation.book.title} has been '
            'cancelled successfully.',
        timestamp: DateTime.now(),
        tone: BannerToneKind.danger,
        icon: Icons.cancel_outlined,
      ),
    );
    notifyListeners();
  }

  SeatBooking reserveSeat(
    Seat seat, {
    DateTime? start,
    DateTime? end,
  }) {
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
    _seatStatus[seat.id] = SeatStatus.occupied;
    _bookings.insert(0, booking);
    _notifications.insert(
      0,
      AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Seat Reservation Confirmed',
        body: 'Seat ${seat.label} is reserved for today.',
        timestamp: now,
        tone: BannerToneKind.success,
        icon: Icons.event_seat_rounded,
      ),
    );
    notifyListeners();
    return booking;
  }

  void cancelSeatBooking(String id) {
    final index = _bookings.indexWhere((booking) => booking.id == id);
    if (index == -1) return;
    final booking = _bookings.removeAt(index);
    _seatStatus[booking.seat.id] = SeatStatus.available;
    _notifications.insert(
      0,
      AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Seat booking cancelled',
        body: 'Seat ${booking.seat.label} has been released.',
        timestamp: DateTime.now(),
        tone: BannerToneKind.danger,
        icon: Icons.event_seat_outlined,
      ),
    );
    notifyListeners();
  }

  void checkIn() {
    if (_bookings.isEmpty) return;
    _bookings[0] = _bookings[0].copyWith(
      status: ReservationStatus.active,
      checkedInAt: DateTime.now(),
    );
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
    notifyListeners();
    return entry;
  }

  void leaveWaitlist(String id) {
    _waitlist.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  // ------------------------------------------------------------------ staff

  void approveQueueEntry(String id) {
    final index = _queue.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _queue[index] = QueueEntry(
      id: _queue[index].id,
      studentName: _queue[index].studentName,
      studentId: _queue[index].studentId,
      location: _queue[index].location,
      requestedAt: _queue[index].requestedAt,
      status: QueueStatus.active,
    );
    notifyListeners();
  }

  void dismissQueueEntry(String id) {
    _queue.removeWhere((e) => e.id == id);
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
