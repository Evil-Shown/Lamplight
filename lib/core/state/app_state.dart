import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';

import '../../data/book_search.dart';
import '../../data/firebase/firestore_service.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import '../../services/functions_service.dart';
import '../../services/notification_service.dart';
import '../../services/preferences_store.dart';
import '../../services/reminder_planner.dart';
import '../feedback/app_feedback.dart';
import 'data_mode.dart';
import 'session_timing.dart' as timing;
import 'sync_status.dart';
import 'test_env.dart';

export '../../data/book_search.dart' show BookPage, BookSort;
export 'sync_status.dart' show DataSource, SyncError, SyncStatus;

/// Why a seat booking did not go through.
enum SeatBookFailure { taken, failed }

/// Outcome of [AppState.reserveSeat]: a booking, or the reason it failed.
class SeatBookResult {
  const SeatBookResult.success(SeatBooking this.booking) : failure = null;
  const SeatBookResult.failure(SeatBookFailure this.failure) : booking = null;
  final SeatBooking? booking;
  final SeatBookFailure? failure;
}

/// Outcome of [AppState.endSeatSession]. [message] is user-ready on failure.
class EndSessionResult {
  const EndSessionResult.success({this.alreadyEnded = false})
      : ok = true,
        message = null;
  const EndSessionResult.failure(String this.message)
      : ok = false,
        alreadyEnded = false;

  final bool ok;
  final bool alreadyEnded;
  final String? message;
}

/// Single source of truth for everything the app shows across screens.
/// Backed by Firebase Auth + Cloud Firestore: the catalog, seat map and every
/// user collection stream in real time, and writes below are persisted
/// through [FirestoreService].
///
/// Sample data ([MockData]) only appears under `flutter test` or an explicit
/// `--dart-define=DEMO_MODE=true` build; see [dataSource].
class AppState extends ChangeNotifier {
  AppState();

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _authSub?.cancel();
    super.dispose();
  }

  final FirestoreService _service = FirestoreService.instance;
  final List<StreamSubscription> _subscriptions = [];
  StreamSubscription<User?>? _authSub;

  UserProfile? _profile;
  List<Book> _books = mockDataAllowed ? MockData.books : [];
  List<Seat> _seats = mockDataAllowed ? MockData.seats : [];
  final List<BookReservation> _reservations =
      mockDataAllowed ? MockData.buildReservations() : [];
  final List<SeatBooking> _bookings =
      mockDataAllowed ? MockData.buildBookings() : [];
  final List<WaitlistEntry> _waitlist =
      mockDataAllowed ? MockData.buildWaitlist() : [];
  final List<AppNotification> _notifications =
      mockDataAllowed ? MockData.buildNotifications() : [];
  final List<Loan> _loans = [];
  List<QueueEntry> _queue = mockDataAllowed ? MockData.buildQueue() : [];
  final Map<String, SeatStatus> _seatStatus = {};
  final Set<String> _seenNotificationIds = {};
  bool _notificationsPrimed = false;

  // Raw staff-wide snapshots, kept so the joined lists can be rebuilt when
  // the catalogue or seat map changes.
  QuerySnapshot<Map<String, dynamic>>? _allReservationsSnap;
  QuerySnapshot<Map<String, dynamic>>? _allBookingsSnap;
  QuerySnapshot<Map<String, dynamic>>? _allWaitlistSnap;
  List<AdminReservation> _adminReservations = [];
  List<AdminWaitlistItem> _adminWaitlist = [];

  // Raw user snapshots, so reservations/bookings re-join on catalogue change.
  QuerySnapshot<Map<String, dynamic>>? _reservationsSnap;
  QuerySnapshot<Map<String, dynamic>>? _bookingsSnap;

  final Set<String> _pendingLocalWrites = {};
  bool _demoFallbackActive = false;

  // ------------------------------------------------------------ sync state

  DateTime? _lastSyncedAt;
  final Map<String, SyncError> _errors = {};
  final Map<String, bool> _fromCache = {};
  SyncError? _writeError;

  /// False until the first books/seats snapshot lands, or a stream fails.
  /// Screens show skeletons until then; there is no timer pretending data
  /// arrived.
  bool _hydrated = false;
  bool get isHydrated => _hydrated;

  /// Where the data on screen comes from.
  DataSource get dataSource {
    if (!_service.isReady) {
      return mockDataAllowed ? DataSource.demo : DataSource.none;
    }
    if (_profile == null) return DataSource.none;
    return _demoFallbackActive ? DataSource.demo : DataSource.live;
  }

  /// Health of the live connection; see [SyncStatus].
  SyncStatus get syncStatus {
    if (dataSource == DataSource.demo && _profile != null) {
      return SyncStatus.live;
    }
    return deriveSyncStatus(
      signedIn: _profile != null,
      hydrated: _hydrated,
      error: _worstError,
      allFromCache:
          _fromCache.isNotEmpty && _fromCache.values.every((c) => c),
      lastSyncedAt: _lastSyncedAt,
      now: DateTime.now(),
    );
  }

  /// When fresh server data last arrived (not cache).
  DateTime? get lastSyncedAt => _lastSyncedAt;

  /// The most serious current failure, or the last failed write.
  SyncError? get lastError => _worstError ?? _writeError;

  SyncError? get _worstError {
    SyncError? best;
    int rank(SyncStatus s) => switch (s) {
          SyncStatus.permissionDenied => 3,
          SyncStatus.error => 2,
          _ => 1,
        };
    for (final e in _errors.values) {
      if (best == null || rank(e.status) > rank(best.status)) best = e;
    }
    return best;
  }

  void _recordError(String key, Object error) {
    _errors[key] = classifyFirestoreError(error);
    _hydrated = true;
    notifyListeners();
  }

  void _recordWriteError(Object error, [StackTrace? _]) {
    _writeError = error is CallableFailure
        ? SyncError(SyncStatus.error, error.message, error.code)
        : classifyFirestoreError(error);
    notifyListeners();
  }

  /// Runs a fire-and-forget write without ever crashing the app.
  void _bg(Future<void> f) => unawaited(f.catchError(_recordWriteError));

  // ------------------------------------------------------ local settings

  NotificationPreferences _preferences = const NotificationPreferences();
  ThemeMode _themeMode = ThemeMode.light;
  bool _themeHintSeen = true;
  bool _soundsEnabled = true;
  bool _hapticsEnabled = true;
  String? _roleNotice;

  UserProfile? get profile => _profile;
  bool get isSignedIn => _profile != null;

  /// Privileges come from the server-issued token claim, never from the
  /// role pills on the sign-in screen.
  UserRole get role => _profile?.role ?? UserRole.student;
  bool get isStaff =>
      _profile?.role == UserRole.staff || _profile?.role == UserRole.admin;
  bool get isAdmin => _profile?.role == UserRole.admin;

  /// Set when the role claim could not be verified at sign-in (the user was
  /// signed in as a student). Show it once, then call [clearRoleNotice].
  String? get roleNotice => _roleNotice;
  void clearRoleNotice() {
    if (_roleNotice == null) return;
    _roleNotice = null;
    notifyListeners();
  }

  List<BookReservation> get reservations =>
      List.unmodifiable(_reservations);
  List<SeatBooking> get bookings => List.unmodifiable(_bookings);
  List<WaitlistEntry> get waitlist => List.unmodifiable(_waitlist);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<QueueEntry> get queue => List.unmodifiable(_queue);
  NotificationPreferences get preferences => _preferences;
  ThemeMode get themeMode => _themeMode;
  bool get themeHintSeen => _themeHintSeen;

  List<Book> get books => _books;
  List<Seat> get seats => [
        for (final seat in _seats)
          seat.copyWith(status: _seatStatus[seat.id] ?? seat.status),
      ];

  /// Signed-in profile; a neutral placeholder (never sample data) otherwise.
  UserProfile get activeProfile =>
      _profile ??
      (mockDataAllowed
          ? MockData.student
          : const UserProfile(
              name: 'Guest',
              studentId: '',
              email: '',
              role: UserRole.student,
            ));

  /// Books waiting for collection, newest deadline first.
  List<BookReservation> get activeReservations => _uniqueReservations(
        _reservations
            .where((r) =>
                r.status != ReservationStatus.cancelled &&
                r.status != ReservationStatus.completed)
            .toList()
          ..sort((a, b) => a.pickupBy.compareTo(b.pickupBy)),
        (reservation) => reservation.book.id,
      );

  /// Collected or cancelled holds (the server's `expired` / `noShow` map to
  /// cancelled when read).
  List<BookReservation> get reservationHistory => _reservations
      .where((r) =>
          r.status == ReservationStatus.cancelled ||
          r.status == ReservationStatus.completed)
      .toList();

  SeatBooking? get todayBooking {
    if (_bookings.isEmpty) return null;
    return _bookings.first;
  }

  /// True when the signed-in user holds an active booking for the seat.
  bool isSeatReservedByMe(String seatId) => _bookings.any(
        (b) => b.seat.id == seatId && b.status == ReservationStatus.active,
      );

  /// Populates sample seats if the inventory is empty.
  void seedSampleSeats() {
    if (!mockDataAllowed) return;
    _seats = MockData.seats;
    _demoFallbackActive = true;
    _hydrated = true;
    notifyListeners();
  }

  // --------------------------------------------------------- notifications

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Same as [unreadCount]; kept for existing screens.
  int get unreadNotifications => unreadCount;

  bool isNotificationRead(String id) =>
      _notifications.any((n) => n.id == id && n.isRead);

  /// Where tapping [n] should lead (reservation / booking / offer / loan).
  NotificationTarget notificationTarget(AppNotification n) =>
      NotificationTarget(n.type, n.targetId);

  Future<void> markRead(String id) async {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i == -1 || _notifications[i].isRead) return;
    final before = _notifications[i];
    _notifications[i] = before.copyWith(readAt: DateTime.now());
    notifyListeners();
    try {
      await _service.markNotificationRead(id);
    } catch (e) {
      _notifications[i] = before;
      _recordWriteError(e);
    }
  }

  Future<void> markAllRead() async {
    final unread = [
      for (final n in _notifications)
        if (!n.isRead) n.id,
    ];
    if (unread.isEmpty) return;
    final backup = List<AppNotification>.of(_notifications);
    final now = DateTime.now();
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(readAt: now);
      }
    }
    notifyListeners();
    try {
      await _service.markNotificationsRead(unread);
    } catch (e) {
      _notifications
        ..clear()
        ..addAll(backup);
      _recordWriteError(e);
    }
  }

  void markNotificationRead(String id) => unawaited(markRead(id));
  void markAllNotificationsRead() => unawaited(markAllRead());

  // ------------------------------------------------------------------ auth

  /// Legacy campus-id sign-in; only works in demo/test builds. Real builds
  /// throw an `AuthFailure`.
  Future<void> signIn({required String identifier, required UserRole role}) =>
      _completeSignIn(_service.signIn(identifier, role));

  Future<void> signInWithGoogle({required UserRole role}) =>
      _completeSignIn(_service.signInWithGoogle(role));

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? studentId,
  }) =>
      _completeSignIn(
        _service.signUpWithEmail(
          email: email,
          password: password,
          fullName: fullName,
          role: role,
          studentId: studentId,
        ),
        signUp: true,
      );

  Future<void> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) =>
      _completeSignIn(_service.signInWithEmail(
        email: email,
        password: password,
        role: role,
      ));

  Future<void> _completeSignIn(Future<UserProfile> pending,
      {bool signUp = false}) async {
    final p = await pending; // throws AuthFailure on error
    _profile = p;
    _roleNotice = _service.roleNotice;
    if (signUp && _service.signUpNotice != null) {
      _roleNotice = _roleNotice == null
          ? _service.signUpNotice
          : '${_service.signUpNotice} $_roleNotice';
    }
    _afterProfileSet();
  }

  /// Sends a password-reset email; throws on failure.
  Future<void> sendPasswordReset(String email) =>
      _service.sendPasswordReset(email);

  /// Restores the Firebase session on cold start.
  Future<void> restoreSession() async {
    if (_profile != null || !_service.isReady) return;
    UserProfile? p;
    try {
      p = await _service.loadProfile();
    } catch (_) {
      return;
    }
    if (p == null) return;
    _profile = p;
    _roleNotice = _service.roleNotice;
    _afterProfileSet();
  }

  void _afterProfileSet() {
    final mockOnly = !_service.isReady;
    final saved = _profile?.prefs;
    if (saved != null) _preferences = saved;
    _queue = mockOnly && mockDataAllowed ? MockData.buildQueue() : [];
    if (mockOnly && !isRunningInTest) _hydrated = true;
    _startListeners();
    _watchAuth();
    notifyListeners();
    unawaited(NotificationService.instance.init().then((_) {
      _rescheduleReminders();
    }));
  }

  /// Clears local state if Firebase drops the session behind our back
  /// (token revoked, account deleted elsewhere). Does nothing without Firebase.
  void _watchAuth() {
    if (_authSub != null || !_service.isReady || !_isLive) return;
    _authSub = _service.authStateChanges().listen((user) {
      if (user == null && _profile != null) {
        unawaited(_clearLocal().then((_) => notifyListeners()));
      }
    }, onError: (_) {});
  }

  bool get _isLive => _service.isReady && !isRunningInTest;

  Future<void> signOut() async {
    try {
      await _service.signOut();
    } finally {
      await _clearLocal();
      notifyListeners();
    }
  }

  Future<void> _clearLocal() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _reservations.clear();
    _bookings.clear();
    _waitlist.clear();
    _notifications.clear();
    _loans.clear();
    _queue = [];
    _seatStatus.clear();
    _seenNotificationIds.clear();
    _notificationsPrimed = false;
    _allReservationsSnap = _allBookingsSnap = _allWaitlistSnap = null;
    _reservationsSnap = _bookingsSnap = null;
    _adminReservations = [];
    _adminWaitlist = [];
    _owners.clear();
    _ownersRequested.clear();
    _offerOverrides.clear();
    _errors.clear();
    _fromCache.clear();
    _writeError = null;
    _lastSyncedAt = null;
    _hydrated = false;
    _roleNotice = null;
    _demoFallbackActive = false;
    _preferences = const NotificationPreferences();
    _profile = null;
    unawaited(NotificationService.instance.syncReminders(const []));
  }

  // ------------------------------------------------------- account / profile

  /// Saves editable profile fields and updates [profile].
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? studentId,
    bool? reservationsVisibleToStaffOnly,
  }) async {
    final current = _profile;
    if (current == null) return;
    if (!_service.isReady) {
      _profile = current.copyWith(
        name: name,
        phone: phone,
        studentId: studentId,
        reservationsVisibleToStaffOnly: reservationsVisibleToStaffOnly,
      );
    } else {
      _profile = await _service.updateProfile(
        current,
        name: name,
        phone: phone,
        studentId: studentId,
        reservationsVisibleToStaffOnly: reservationsVisibleToStaffOnly,
      );
    }
    notifyListeners();
  }

  /// Erases server-side data via the callable, then signs out and clears
  /// local state. Throws if the server refuses (nothing is cleared then).
  Future<void> deleteAccount() async {
    if (_service.isReady) {
      await _service.deleteAccount();
    }
    await _clearLocal();
    notifyListeners();
  }

  /// Everything held about the signed-in user as pretty JSON text, ready to
  /// share or copy.
  Future<String> exportAccountData() async {
    final Map<String, dynamic> data;
    if (_service.isReady && _profile != null) {
      data = await _service.exportAccountData();
    } else {
      data = {
        'profile': {
          'name': activeProfile.name,
          'studentId': activeProfile.studentId,
          'email': activeProfile.email,
        },
        'reservations': [
          for (final r in _reservations)
            {
              'id': r.id,
              'book': r.book.title,
              'pickupBy': r.pickupBy.toIso8601String(),
              'status': r.status.name,
            },
        ],
        'seatBookings': [
          for (final b in _bookings)
            {
              'id': b.id,
              'seat': b.seat.label,
              'start': b.startTime.toIso8601String(),
              'end': b.endTime.toIso8601String(),
              'status': b.status.name,
            },
        ],
      };
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // -------------------------------------------------------------- listeners

  void _listen(String key, Stream<QuerySnapshot<Map<String, dynamic>>> s) {
    _subscriptions.add(s.listen(
      (snap) {
        _errors.remove(key);
        _apply(key, snap);
        notifyListeners();
      },
      onError: (Object e) => _recordError(key, e),
    ));
  }

  void _startListeners() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();

    _listen('books', _service.booksSnapshot());
    _listen('seats', _service.seatsSnapshot());
    _listen('reservations', _service.userReservationsSnapshot());
    _listen('bookings', _service.userBookingsSnapshot());
    _listen('notifications', _service.userNotificationsSnapshot());
    _listen('waitlist', _service.userWaitlistSnapshot());
    _listen('loans', _service.userLoansSnapshot());

    if (isStaff) {
      _listen('queue', _service.queueSnapshot());
      _listen('allReservations', _service.allReservationsSnapshot());
      _listen('allBookings', _service.allBookingsSnapshot());
      _listen('allWaitlist', _service.allWaitlistSnapshot());
    }
  }

  /// Applies one snapshot (from a listener or a server refresh).
  void _apply(String key, QuerySnapshot<Map<String, dynamic>> snap) {
    final fromCache = snap.metadata.isFromCache;
    _fromCache[key] = fromCache;
    if (!fromCache) _lastSyncedAt = DateTime.now();

    switch (key) {
      case 'books':
        final live = [for (final d in snap.docs) _service.bookFromDocPublic(d)];
        if (live.isEmpty && mockDataAllowed) {
          _demoFallbackActive = true;
          _books = MockData.books;
        } else {
          _books = live;
        }
        _hydrated = true;
        _rejoin();
      case 'seats':
        final live = [for (final d in snap.docs) _service.seatFromDocPublic(d)];
        if (live.isEmpty && mockDataAllowed) {
          _demoFallbackActive = true;
          _seats = MockData.seats;
        } else {
          _seats = live;
        }
        // Server truth supersedes optimistic local seat flips.
        _seatStatus.clear();
        _hydrated = true;
        _rejoin();
      case 'reservations':
        _reservationsSnap = snap;
        _rejoin();
      case 'bookings':
        _bookingsSnap = snap;
        _rejoin();
      case 'notifications':
        _applyNotifications(snap);
      case 'waitlist':
        _waitlist
          ..clear()
          ..addAll([
            for (final doc in snap.docs)
              _service.waitlistFromMapPublic(doc.data(), doc.id),
          ]);
        _settleOfferOverrides();
      case 'loans':
        _loans
          ..clear()
          ..addAll([
            for (final doc in snap.docs)
              _service.loanFromMapPublic(doc.data(), doc.id),
          ]);
        _rescheduleReminders();
      case 'queue':
        _queue = [
          for (final doc in snap.docs) _queueFromMap(doc.id, doc.data()),
        ];
      case 'allReservations':
        _allReservationsSnap = snap;
        _rebuildAdmin();
      case 'allBookings':
        _allBookingsSnap = snap;
        _rebuildAdmin();
      case 'allWaitlist':
        _allWaitlistSnap = snap;
        _rebuildAdmin();
    }
  }

  QueueEntry _queueFromMap(String id, Map<String, dynamic> data) => QueueEntry(
        id: id,
        studentName: data['studentName'] as String? ?? '',
        studentId: data['studentId'] as String? ?? '',
        location: data['location'] as String? ?? '',
        requestedAt:
            (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: QueueStatus.values.firstWhere(
          (v) => v.name == data['status'],
          orElse: () => QueueStatus.pending,
        ),
      );

  /// Rebuilds the lists that join against the catalogue / seat map.
  void _rejoin() {
    final rs = _reservationsSnap;
    if (rs != null) {
      _reservations
        ..clear()
        ..addAll([
          for (final doc in rs.docs)
            _service.reservationFromMapPublic(doc.data(), doc.id, _books),
        ]);
    }
    final bs = _bookingsSnap;
    if (bs != null) {
      _bookings
        ..clear()
        ..addAll([
          for (final doc in bs.docs)
            _service.bookingFromMapPublic(doc.data(), doc.id, _seats),
        ]);
    }
    _rebuildAdmin();
    _rescheduleReminders();
  }

  // Owner display names for the staff lists, fetched lazily from profiles.
  final Map<String, ({String name, String studentId})> _owners = {};
  final Set<String> _ownersRequested = {};

  void _fetchMissingOwners() {
    final missing = <String>{
      for (final r in _adminReservations) r.ownerUid,
      for (final w in _adminWaitlist) w.ownerUid,
    }..removeWhere((u) => u.isEmpty || !_ownersRequested.add(u));
    if (missing.isEmpty) return;
    unawaited(_service.fetchUserCards(missing).then((cards) {
      if (cards.isEmpty) return;
      _owners.addAll(cards);
      _rebuildAdmin(fetchOwners: false);
      notifyListeners();
    }));
  }

  void _rebuildAdmin({bool fetchOwners = true}) {
    final res = _allReservationsSnap;
    final bks = _allBookingsSnap;
    if (res != null || bks != null) {
      _adminReservations = [
        if (res != null)
          for (final d in res.docs)
            _service.adminReservationFromDoc(d,
                seat: false, books: _books, seats: _seats, owners: _owners),
        if (bks != null)
          for (final d in bks.docs)
            _service.adminReservationFromDoc(d,
                seat: true, books: _books, seats: _seats, owners: _owners),
      ]..sort((a, b) => b.reservedAt.compareTo(a.reservedAt));
    }
    final wl = _allWaitlistSnap;
    if (wl != null) {
      _adminWaitlist = [
        for (final d in wl.docs)
          _service.adminWaitlistFromDoc(d, owners: _owners),
      ]..sort((a, b) => a.entry.joinedAt.compareTo(b.entry.joinedAt));
    }
    if (fetchOwners) _fetchMissingOwners();
  }

  void _applyNotifications(QuerySnapshot<Map<String, dynamic>> snap) {
    final next = [
      for (final doc in snap.docs)
        _service.notificationFromMapPublic(doc.data(), doc.id),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final fresh = <AppNotification>[];
    for (final n in next) {
      if (_seenNotificationIds.add(n.id)) fresh.add(n);
    }
    _notifications
      ..clear()
      ..addAll(next);
    // The first snapshot is history, not news: only later arrivals pop a
    // device notification, and never for ones this device wrote itself.
    if (_notificationsPrimed && !snap.metadata.isFromCache) {
      for (final n in fresh) {
        if (!_pendingLocalWrites.remove(n.id)) {
          unawaited(NotificationService.instance
              .showLocal(title: n.title, body: n.body));
        }
      }
    }
    _notificationsPrimed = true;
  }

  /// Pull-to-refresh: re-reads everything from the server and updates
  /// [lastSyncedAt]. Failures are recorded in [lastError]; last good data
  /// stays on screen.
  Future<void> refresh() async {
    if (!_service.isReady || _profile == null) return;
    try {
      final snaps = await _service.fetchFromServer(staff: isStaff);
      _errors.clear();
      snaps.forEach(_apply);
      _lastSyncedAt = DateTime.now();
      notifyListeners();
    } catch (e) {
      _recordError('refresh', e);
    }
  }

  // ------------------------------------------------------------ reservations

  /// Random base32 suffix (no look-alike characters) for unique ids.
  static String _randomSuffix([int length = 6]) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return String.fromCharCodes([
      for (var i = 0; i < length; i++)
        alphabet.codeUnitAt(rng.nextInt(alphabet.length)),
    ]);
  }

  /// True when the user already holds an open reservation for the book.
  bool hasOpenReservation(String bookId) => _reservations.any((r) =>
      r.book.id == bookId &&
      r.status != ReservationStatus.cancelled &&
      r.status != ReservationStatus.completed);

  /// Reserves a book. Returns null when the user already holds it or the
  /// write failed (the optimistic entry is rolled back then).
  Future<BookReservation?> reserveBook(Book book) async {
    if (hasOpenReservation(book.id)) return null;

    final now = DateTime.now();
    final suffix = _randomSuffix();
    final reservation = BookReservation(
      id: 'BR-2026-$suffix',
      book: book,
      reservedAt: now,
      pickupBy: now.add(const Duration(days: 7)),
      pickupLocation: 'Main Library',
      qrCode: 'LIB-BR-2026-$suffix',
      status: ReservationStatus.ready,
    );
    _reservations.insert(0, reservation);
    notifyListeners();
    try {
      // Offline writes queue and never ack, so a timeout keeps the entry.
      await _service
          .addReservation(reservation)
          .timeout(const Duration(seconds: 10), onTimeout: () {});
    } catch (e) {
      _reservations.removeWhere((r) => r.id == reservation.id);
      _recordWriteError(e);
      return null;
    }
    _notify(BannerToneKind.success, 'Book Reservation Confirmed',
        '${book.title} has been reserved successfully.',
        icon: Icons.check_circle_outline_rounded,
        type: NotificationType.reservation,
        targetId: reservation.id);
    notifyListeners();
    _rescheduleReminders();
    return reservation;
  }

  List<T> _uniqueReservations<T>(
    List<T> items,
    String Function(T item) keyOf,
  ) {
    final seen = <String>{};
    final unique = <T>[];
    for (final item in items) {
      if (seen.add(keyOf(item))) {
        unique.add(item);
      }
    }
    return unique;
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
        icon: Icons.cancel_outlined,
        type: NotificationType.reservation,
        targetId: id);
    _bg(_service.updateReservationStatus(id, ReservationStatus.cancelled));
    notifyListeners();
    _rescheduleReminders();
    // The server promotes the waitlist; demo builds emulate it locally.
    // ignore: deprecated_member_use_from_same_package
    _bg(_service.promoteNextOnWaitlist(
      resourceTitle: reservation.book.title,
      resourceSubtitle: reservation.book.shelfLocation,
    ));
  }

  /// Books a seat. The optimistic entry is rolled back and a failure
  /// returned when the seat was just taken or the write was rejected; only a
  /// genuine offline error keeps it.
  Future<SeatBookResult> reserveSeat(
    Seat seat, {
    DateTime? start,
    DateTime? end,
  }) async {
    final current = _seats.where((s) => s.id == seat.id).firstOrNull;
    if (current != null && _seatStatus[current.id] == SeatStatus.occupied) {
      return const SeatBookResult.failure(SeatBookFailure.taken);
    }
    final now = DateTime.now();
    final startTime = start ?? DateTime(now.year, now.month, now.day, 14);
    final endTime = end ?? DateTime(now.year, now.month, now.day, 17);
    final suffix = _randomSuffix();
    final booking = SeatBooking(
      id: 'LIB-2026-$suffix',
      seat: seat,
      date: DateTime(startTime.year, startTime.month, startTime.day),
      startTime: startTime,
      endTime: endTime,
      qrCode: 'LIB-2026-$suffix',
      status: ReservationStatus.active,
    );
    _bookings.insert(0, booking);
    _seatStatus[seat.id] = SeatStatus.occupied;
    notifyListeners();

    // Atomic on the server: a losing racer gets false, not a ghost booking.
    var ok = false;
    Object? error;
    try {
      ok = await _service
          .addBooking(booking, SeatStatus.occupied)
          .timeout(const Duration(seconds: 15), onTimeout: () => true);
    } catch (e) {
      error = e;
    }
    if (!ok) {
      _bookings.removeWhere((b) => b.id == booking.id);
      if (error != null) {
        _seatStatus.remove(seat.id);
        _recordWriteError(error);
      }
      notifyListeners();
      return SeatBookResult.failure(
          error == null ? SeatBookFailure.taken : SeatBookFailure.failed);
    }
    _notify(BannerToneKind.success, 'Seat Reservation Confirmed',
        'Seat ${seat.label} is reserved for today.',
        icon: Icons.event_seat_rounded,
        type: NotificationType.booking,
        targetId: booking.id);
    notifyListeners();
    _rescheduleReminders();
    return SeatBookResult.success(booking);
  }

  void cancelSeatBooking(String id) {
    final index = _bookings.indexWhere((booking) => booking.id == id);
    if (index == -1) return;
    final booking = _bookings.removeAt(index);
    _seatStatus[booking.seat.id] = SeatStatus.available;
    _notify(BannerToneKind.danger, 'Seat booking cancelled',
        'Seat ${booking.seat.label} has been released.',
        icon: Icons.event_seat_outlined,
        type: NotificationType.booking,
        targetId: id);
    _bg(_service.deleteBooking(booking));
    notifyListeners();
    _rescheduleReminders();
    // ignore: deprecated_member_use_from_same_package
    _bg(_service.promoteNextOnWaitlist(
      resourceTitle: 'Seat ${booking.seat.label}',
      resourceSubtitle: 'Floor ${booking.seat.floor} – '
          '${booking.seat.section}',
    ));
  }

  /// Ends a checked-in seat session through the `endSeatSession` callable.
  /// Pass [ownerUid] when staff end another student's session. On success the
  /// booking is dropped from local state and the seat shows as free.
  Future<EndSessionResult> endSeatSession(SeatBooking booking,
      {String? ownerUid}) async {
    final isOwn = ownerUid == null || ownerUid == _service.uid;
    if (!_service.isReady) {
      // Demo / tests: no server, so emulate locally for the owner only.
      if (!isOwn) {
        return const EndSessionResult.failure(
            "Ending another student's session needs a live connection.");
      }
      cancelSeatBooking(booking.id);
      return const EndSessionResult.success();
    }
    try {
      final result = await FunctionsService.instance
          .endSeatSession(booking.id, uid: isOwn ? null : ownerUid);
      if (isOwn) {
        _bookings.removeWhere((b) => b.id == booking.id);
      }
      _seatStatus[booking.seat.id] = SeatStatus.available;
      notifyListeners();
      if (isOwn) _rescheduleReminders();
      return EndSessionResult.success(alreadyEnded: result == 'alreadyEnded');
    } on CallableFailure catch (e) {
      if (e.code == 'not-found' || e.code == 'unimplemented') {
        return const EndSessionResult.failure(
            'This feature needs the latest server update.');
      }
      return EndSessionResult.failure(e.message);
    } catch (_) {
      return const EndSessionResult.failure(
          'Could not end the session. Check the connection and try again.');
    }
  }

  /// Demo/test shortcut. With a live backend, check-in happens when staff
  /// scan the pass (`verifyQrPass`) and arrives through the bookings stream,
  /// so this does nothing.
  void checkIn() {
    if (_bookings.isEmpty || _service.isReady) return;
    _bookings[0] = _bookings[0].copyWith(
      status: ReservationStatus.active,
      checkedInAt: DateTime.now(),
    );
    _bg(_service.checkInBooking(_bookings[0].id));
    notifyListeners();
    _rescheduleReminders();
  }

  // ------------------------------------------------- countdown helpers
  //
  // Derived from stored timestamps on every call; never cached or persisted.

  /// Latest moment to check in before the seat is released.
  DateTime checkInDeadline(SeatBooking b) => timing.checkInDeadline(b);

  /// Time left to check in; null once checked in or the booking is over.
  Duration? graceRemaining(SeatBooking b, {DateTime? now}) =>
      timing.graceRemaining(b, now ?? DateTime.now());

  /// Time left to collect a reserved book; null when collected/cancelled.
  Duration? pickupRemaining(BookReservation r, {DateTime? now}) =>
      timing.pickupRemaining(r, now ?? DateTime.now());

  /// Time left to answer a waitlist offer; null when none is pending.
  Duration? offerRemaining(WaitlistEntry e, {DateTime? now}) =>
      timing.offerRemaining(e, now ?? DateTime.now());

  // --------------------------------------------------------------- waitlist

  WaitlistEntry joinWaitlist({
    required String title,
    required String subtitle,
    WaitlistType type = WaitlistType.seat,
    String? seatPreference,
    String? resourceId,
  }) {
    // The server promotes by resource id; infer it from the catalogue /
    // seat map when the caller did not pass one.
    resourceId ??= type == WaitlistType.book
        ? _books.where((b) => b.title == title).firstOrNull?.id
        : _seats
            .where((s) => 'Seat ${s.label}' == title || s.label == title)
            .firstOrNull
            ?.id;
    final entry = WaitlistEntry(
      id: 'w${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      subtitle: subtitle,
      position: _waitlist.length + 1,
      joinedAt: DateTime.now(),
      estimatedWaitMinutes: 45,
      seatPreference: seatPreference,
      resourceId: resourceId,
    );
    _waitlist.add(entry);
    _bg(_service.addWaitlistEntry(entry));
    notifyListeners();
    return entry;
  }

  void leaveWaitlist(String id) {
    _waitlist.removeWhere((entry) => entry.id == id);
    _bg(_service.removeWaitlistEntry(id));
    notifyListeners();
  }

  // Optimistic answers to offers, keyed by entry id. Cleared when the
  // server snapshot catches up (or the call fails).
  final Map<String, WaitlistStatus> _offerOverrides = {};
  final Set<String> _offersInFlight = {};

  void _settleOfferOverrides() {
    _offerOverrides.removeWhere((id, _) {
      final e = _waitlist.where((w) => w.id == id).firstOrNull;
      return e == null || e.status != WaitlistStatus.offered;
    });
  }

  WaitlistEntry _withOverride(WaitlistEntry e) {
    final o = _offerOverrides[e.id];
    var out = o == null ? e : e.copyWith(status: o);
    if (out.isOffered && out.offerExpiresAt == null) {
      final n = _notifications
          .where((n) =>
              n.type == NotificationType.offer &&
              n.targetId == e.id &&
              n.offerExpiresAt != null)
          .firstOrNull;
      if (n != null) out = out.copyWith(offerExpiresAt: n.offerExpiresAt);
    }
    return out;
  }

  /// Waitlist entries with a live offer the student can still answer. The
  /// expiry comes from the entry, or from the matching offer notification.
  List<WaitlistEntry> get pendingOffers => [
        for (final e in _waitlist)
          if (_withOverride(e).isOffered) _withOverride(e),
      ];

  /// Unanswered offer notifications (for badges and deep links).
  List<AppNotification> get offerNotifications => [
        for (final n in _notifications)
          if (n.type == NotificationType.offer && !n.isRead) n,
      ];

  /// True while a [respondToOffer] call for [entryId] is awaiting the server.
  bool isOfferResponding(String entryId) => _offersInFlight.contains(entryId);

  /// Accepts or declines an offer. The UI updates immediately; if the
  /// server refuses (offer expired, offline) the change is rolled back and
  /// the failure is rethrown so the screen can show its message.
  Future<void> respondToOffer(String entryId, bool accept) async {
    if (_offersInFlight.contains(entryId)) return;
    _offersInFlight.add(entryId);
    _offerOverrides[entryId] =
        accept ? WaitlistStatus.accepted : WaitlistStatus.declined;
    notifyListeners();
    try {
      if (_service.isReady && _profile != null) {
        await _service.respondToWaitlistOffer(entryId, accept);
      } else {
        // Demo/test: apply locally.
        final i = _waitlist.indexWhere((w) => w.id == entryId);
        if (i != -1) _waitlist.removeAt(i);
        _offerOverrides.remove(entryId);
      }
    } catch (e) {
      _offerOverrides.remove(entryId);
      _recordWriteError(e);
      rethrow;
    } finally {
      _offersInFlight.remove(entryId);
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------ loans

  List<Loan> get loans => List.unmodifiable(_loans);

  List<Loan> get activeLoans => [
        for (final l in _loans)
          if (!l.isReturned) l,
      ]..sort((a, b) => a.dueAt.compareTo(b.dueAt));

  List<Loan> get overdueLoans {
    final now = DateTime.now();
    return [
      for (final l in activeLoans)
        if (l.isOverdueAt(now)) l,
    ];
  }

  /// Fines on loans that are still out, in LKR.
  num get finesTotal =>
      activeLoans.fold<num>(0, (total, l) => total + l.fineAccrued);

  /// Renews a loan via the server; throws a user-friendly failure.
  Future<void> renewLoan(String loanId) async {
    try {
      await _service.renewLoan(loanId);
    } catch (e) {
      _recordWriteError(e);
      rethrow;
    }
  }

  /// Staff: lends [bookId] to the user with uid [userId].
  Future<void> checkout({
    required String userId,
    required String bookId,
    String? reservationId,
    int? loanDays,
  }) async {
    await _service.checkoutBook({
      'userId': userId,
      'bookId': bookId,
      if (reservationId != null) 'reservationId': reservationId,
      if (loanDays != null) 'loanDays': loanDays,
    });
  }

  /// Staff: records a return, by loan id.
  Future<void> checkin({required String loanId}) async {
    await _service.checkinBook({'loanId': loanId});
  }

  // ----------------------------------------------------------------- search

  /// Catalogue search with cursor pagination. Pass the previous page's
  /// `cursor` as [startAfter] to continue.
  Future<BookPage> searchBooks({
    String query = '',
    String? subject,
    bool availableOnly = false,
    BookSort sort = BookSort.title,
    Object? startAfter,
    int pageSize = 20,
  }) async {
    if (_service.isReady && _profile != null) {
      try {
        return await _service.searchBooks(
          query: query,
          subject: subject,
          availableOnly: availableOnly,
          sort: sort,
          startAfter: startAfter,
          pageSize: pageSize,
        );
      } catch (e) {
        // Missing index or offline: filter what is already loaded.
        _writeError = classifyFirestoreError(e);
      }
    }
    final all = filterAndSortBooks(
      _books,
      query: query,
      subject: subject,
      availableOnly: availableOnly,
      sort: sort,
    );
    final from = startAfter is int ? startAfter : 0;
    final to = (from + pageSize).clamp(0, all.length);
    return BookPage(
      books: all.sublist(from.clamp(0, all.length), to),
      cursor: to < all.length ? to : null,
      hasMore: to < all.length,
    );
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
    _bg(_service.updateQueueStatus(id, QueueStatus.active));
    notifyListeners();
  }

  void dismissQueueEntry(String id) {
    _queue.removeWhere((e) => e.id == id);
    _bg(_service.deleteQueueEntry(id));
    notifyListeners();
  }

  /// Staff name / id come from the signed-in profile.
  String get staffName => activeProfile.name;
  String get staffId => activeProfile.studentId;

  /// Every book, with copy counts (see [Book.totalCopies]).
  List<Book> get adminBooks => _books;

  /// Every seat with its live status.
  List<Seat> get adminSeats => seats;

  /// All students' book reservations and seat bookings, newest first.
  /// Needs the collection-group read rule for staff.
  List<AdminReservation> get adminReservations =>
      List.unmodifiable(_adminReservations);

  /// The waitlist across all students, oldest first.
  List<AdminWaitlistItem> get adminWaitlist =>
      List.unmodifiable(_adminWaitlist);

  /// Live dashboard numbers computed from real documents.
  DashboardStats get dashboardStats {
    final now = DateTime.now();
    bool today(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;
    final sessions = _adminReservations.where((r) =>
        r.isSeat &&
        r.status == ReservationStatus.active &&
        r.dueAt != null &&
        r.dueAt!.isAfter(now) &&
        !r.reservedAt.isAfter(now));
    final due = _adminReservations.where((r) =>
        !r.isSeat &&
        r.dueAt != null &&
        today(r.dueAt!) &&
        r.status != ReservationStatus.cancelled &&
        r.status != ReservationStatus.completed);
    final all = seats;
    return DashboardStats(
      activeSessions: sessions.length,
      reservationsDueToday: due.length,
      waitingCount: _adminWaitlist
          .where((w) => w.entry.status == WaitlistStatus.waiting)
          .length,
      seatsOccupied: all.where((s) => s.status == SeatStatus.occupied).length,
      seatsTotal: all.length,
    );
  }

  /// Sets copy counts for a book (and its availability flag).
  Future<void> setCopies(String bookId,
          {required int available, int? total}) =>
      _service.setCopies(bookId, available: available, total: total);

  Future<String> addBook(Book book) => _service.addBook(book);

  Future<void> editBook(Book book) => _service.editBook(book);

  Future<void> setSeatStatus(String seatId, SeatStatus status) =>
      _service.setSeatStatus(seatId, status);

  // ----------------------------------------------------------- preferences

  void updatePreferences(NotificationPreferences prefs) {
    _preferences = prefs;
    _bg(_service.saveNotificationPrefs(prefs));
    notifyListeners();
    _rescheduleReminders();
  }

  /// Applies choices loaded from device storage before the first frame.
  void applyLocalSettings(LocalSettings s) {
    _themeMode = s.themeMode;
    _themeHintSeen = s.themeHintSeen;
    _soundsEnabled = s.sounds;
    _hapticsEnabled = s.haptics;
    AppFeedback.soundsEnabled = s.sounds;
    AppFeedback.hapticsEnabled = s.haptics;
  }

  /// Feedback preferences, persisted on the device and mirrored into
  /// [AppFeedback] so every `Haptics`/`AppFeedback` call respects them.
  bool get soundsEnabled => _soundsEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  void setSoundsEnabled(bool value) {
    if (_soundsEnabled == value) return;
    _soundsEnabled = value;
    AppFeedback.soundsEnabled = value;
    unawaited(PreferencesStore.saveSounds(value));
    notifyListeners();
  }

  void setHapticsEnabled(bool value) {
    if (_hapticsEnabled == value) return;
    _hapticsEnabled = value;
    AppFeedback.hapticsEnabled = value;
    unawaited(PreferencesStore.saveHaptics(value));
    notifyListeners();
  }

  void markThemeHintSeen() {
    if (_themeHintSeen) return;
    _themeHintSeen = true;
    unawaited(PreferencesStore.saveThemeHintSeen(true));
    notifyListeners();
  }

  /// `ThemeMode.light` is the default; `ThemeMode.system` follows the device.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    unawaited(PreferencesStore.saveTheme(mode));
    notifyListeners();
  }

  // ------------------------------------------------------------- reminders

  /// Re-plans the on-device fallback reminders from current data. The
  /// server sends the authoritative ones; these cover being offline.
  void _rescheduleReminders() {
    if (_profile == null) return;
    unawaited(NotificationService.instance.syncReminders(planReminders(
      now: DateTime.now(),
      prefs: _preferences,
      bookings: _bookings,
      reservations: _reservations,
      loans: _loans,
    )));
  }

  void _notify(BannerToneKind tone, String title, String body,
      {IconData? icon,
      NotificationType type = NotificationType.info,
      String? targetId}) {
    // With a live backend the server writes the notification (clients
    // cannot), and it streams in; only demo/test builds fake one locally.
    if (_service.isReady) return;
    final n = AppNotification(
      id: 'n${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      tone: tone,
      icon: icon,
      type: type,
      targetId: targetId,
    );
    _notifications.insert(0, n);
    // Written on this device — the in-app feed already shows it, so mark
    // it seen and suppress the duplicate device notification.
    _seenNotificationIds.add(n.id);
    _pendingLocalWrites.add(n.id);
    _bg(_service.addNotification(n));
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
