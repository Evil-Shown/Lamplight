import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/models.dart';
import '../mock/mock_data.dart';

/// Thin Firestore + Firebase Auth repository. Every screen keeps talking to
/// [AppState]; this class is where the real network happens.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  /// True when the app is connected to a Firebase project.
  bool get isReady => _firebaseReady;

  static const _demoPassword = 'quickbook123';

  String? get uid => _auth.currentUser?.uid;

  // ------------------------------------------------------------------ auth

  /// Signs in via Google OAuth.
  Future<UserProfile> signInWithGoogle(UserRole role) async {
    final fallback = _seedProfile('Google User', role);
    if (!_firebaseReady) return fallback;

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google Sign In was cancelled.';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return fallback;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return _profileFromMap(doc.data()!, user.uid);
      }

      final profile = UserProfile(
        name: user.displayName ?? googleUser.displayName ?? 'Library Member',
        studentId: user.email?.split('@').first ?? user.uid.substring(0, 8),
        email: user.email ?? googleUser.email,
        role: role,
      );
      await _db.collection('users').doc(user.uid).set(_profileToMap(profile));
      return profile;
    } catch (e) {
      if (e is String) rethrow;
      // Fallback for demo or offline mode if credentials fail
      return fallback;
    }
  }

  /// Registers a new user with Email and Password.
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? studentId,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = fullName.trim().isEmpty ? 'Library Member' : fullName.trim();
    final cleanStudentId = (studentId != null && studentId.trim().isNotEmpty)
        ? studentId.trim()
        : cleanEmail.split('@').first;

    final fallback = UserProfile(
      name: cleanName,
      studentId: cleanStudentId,
      email: cleanEmail,
      role: role,
    );
    if (!_firebaseReady) return fallback;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) return fallback;

      try {
        await user.updateDisplayName(cleanName);
      } catch (_) {}

      final profile = UserProfile(
        name: cleanName,
        studentId: cleanStudentId,
        email: cleanEmail,
        role: role,
      );

      await _db.collection('users').doc(user.uid).set(_profileToMap(profile));
      return profile;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Registration failed. Please try again.';
    } catch (_) {
      return fallback;
    }
  }

  /// Signs in an existing user with Email and Password.
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cleanEmail = email.trim();
    final fallback = _seedProfile(cleanEmail, role);
    if (!_firebaseReady) return fallback;

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) return fallback;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return _profileFromMap(doc.data()!, user.uid);
      }

      final profile = UserProfile(
        name: user.displayName ?? 'Library Member',
        studentId: cleanEmail.split('@').first,
        email: cleanEmail,
        role: role,
      );
      await _db.collection('users').doc(user.uid).set(_profileToMap(profile));
      return profile;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Invalid email or password.';
    } catch (_) {
      return fallback;
    }
  }

  /// Signs in with the campus identifier. If the account does not exist yet
  /// it is provisioned on the fly; if Firebase Auth is unreachable we fall
  /// back to anonymous auth so the demo still works offline.
  Future<UserProfile> signIn(String identifier, UserRole role) async {
    final fallback = _seedProfile(identifier, role);
    if (!_firebaseReady) return fallback;
    final email = identifier.contains('@')
        ? identifier.trim()
        : '${identifier.trim().toLowerCase()}@sliit.lk';
    UserCredential? credential;
    try {
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: _demoPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          credential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: _demoPassword,
          );
        } else if (e.code != 'invalid-email') {
          rethrow;
        }
      }
    } catch (_) {
      try {
        credential = await _auth.signInAnonymously();
      } catch (_) {
        return fallback;
      }
    }
    final user = credential?.user;
    if (user == null) return fallback;
    final fbUid = user.uid;

    try {
      final doc = await _db.collection('users').doc(fbUid).get();
      if (doc.exists) {
        return _profileFromMap(doc.data()!, fbUid);
      }
      final profile = _seedProfile(identifier, role);
      await _db.collection('users').doc(fbUid).set(_profileToMap(profile));
      return profile;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> signOut() {
    if (!_firebaseReady) return Future.value();
    return _auth.signOut();
  }

  UserProfile _seedProfile(String identifier, UserRole role) =>
      role == UserRole.staff ? MockData.staff : MockData.student;

  Future<UserProfile?> loadProfile() async {
    final id = uid;
    if (id == null) return null;
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return _profileFromMap(doc.data()!, id);
  }

  // ------------------------------------------------------------------ seed

  /// Pushes the mock catalogue/seat map into Firestore the first time the
  /// app runs against an empty project.
  Future<void> seedIfEmpty() async {
    try {
      final books = await _db.collection('books').limit(1).get();
      if (books.docs.isEmpty) {
        for (final book in MockData.books) {
          await _db
              .collection('books')
              .doc(book.id)
              .set(_bookToMap(book, id: book.id));
        }
      }
      final seats = await _db.collection('seats').limit(1).get();
      if (seats.docs.isEmpty) {
        for (final seat in MockData.seats) {
          await _db
              .collection('seats')
              .doc(seat.id)
              .set(_seatToMap(seat, id: seat.id));
        }
      }
    } catch (_) {
      // Unauthenticated seed attempt or missing permissions on cold start.
    }
  }

  // ---------------------------------------------------------------- streams

  bool get _canStream => _firebaseReady && uid != null;

  Stream<List<Book>> booksStream() => _canStream
      ? _db
          .collection('books')
          .snapshots()
          .map((s) => s.docs.map(_bookFromDoc).toList())
      : const Stream.empty();

  Stream<List<Seat>> seatsStream() => _canStream
      ? _db
          .collection('seats')
          .snapshots()
          .map((s) => s.docs.map(_seatFromDoc).toList())
      : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> userReservationsSnapshot() =>
      _canStream ? _reservationsRef().snapshots() : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> userBookingsSnapshot() =>
      _canStream ? _bookingsRef().snapshots() : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> userNotificationsSnapshot() =>
      _canStream ? _notificationsRef().snapshots() : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> userWaitlistSnapshot() =>
      _canStream ? _waitlistRef().snapshots() : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> queueSnapshot() => _canStream
      ? _db.collection('queue').snapshots()
      : const Stream.empty();

  CollectionReference<Map<String, dynamic>> _reservationsRef() =>
      _db.collection('users').doc(uid).collection('reservations');

  CollectionReference<Map<String, dynamic>> _bookingsRef() =>
      _db.collection('users').doc(uid).collection('bookings');

  CollectionReference<Map<String, dynamic>> _notificationsRef() =>
      _db.collection('users').doc(uid).collection('notifications');

  CollectionReference<Map<String, dynamic>> _waitlistRef() =>
      _db.collection('users').doc(uid).collection('waitlist');

  // ----------------------------------------------------- reservation writes

  Future<void> addReservation(BookReservation r) async {
    if (!_canStream) return;
    await _reservationsRef().doc(r.id).set(_reservationToMap(r));
  }

  Future<void> updateReservationStatus(String id, ReservationStatus s) async {
    if (!_canStream) return;
    await _reservationsRef().doc(id).update({'status': s.name});
  }

  /// Atomically reserves a seat: the seat document is only flipped to
  /// `occupied` while still `available`, so two students tapping at the
  /// same time cannot both win the same seat. Returns false if the seat
  /// was taken first.
  Future<bool> addBooking(SeatBooking b, SeatStatus seatStatus) async {
    if (!_canStream) return true;
    try {
      await _db.runTransaction((tx) async {
        final seatRef = _db.collection('seats').doc(b.seat.id);
        final seatSnap = await tx.get(seatRef);
        final status = seatSnap.data()?['status'] as String?;
        if (seatSnap.exists && status != SeatStatus.available.name) {
          throw StateError('seat-taken');
        }
        tx.set(_bookingsRef().doc(b.id), _bookingToMap(b));
        tx.update(seatRef, {'status': seatStatus.name});
      });
      return true;
    } on StateError {
      return false;
    } catch (_) {
      // Offline/unreachable — keep the optimistic local state.
      return true;
    }
  }

  Future<void> deleteBooking(SeatBooking b) async {
    if (!_canStream) return;
    final batch = _db.batch();
    batch.delete(_bookingsRef().doc(b.id));
    batch
        .update(_db.collection('seats').doc(b.seat.id), {'status': 'available'});
    await batch.commit();
  }

  Future<void> checkInBooking(String id) async {
    if (!_canStream) return;
    await _bookingsRef()
        .doc(id)
        .update({'checkedInAt': Timestamp.fromDate(DateTime.now())});
  }

  // ------------------------------------------------------- waitlist writes

  Future<void> addWaitlistEntry(WaitlistEntry e) async {
    if (!_canStream) return;
    await _waitlistRef().doc(e.id).set(_waitlistToMap(e));
  }

  Future<void> removeWaitlistEntry(String id) async {
    if (!_canStream) return;
    await _waitlistRef().doc(id).delete();
  }

  /// When a resource frees up, offer it to the first person still waiting
  /// across all users: flips their entry to `offered` and writes a
  /// notification document into their feed (their device shows it).
  Future<void> promoteNextOnWaitlist({
    required String resourceTitle,
    required String resourceSubtitle,
  }) async {
    if (!_firebaseReady) return;
    try {
      final waiting = await _db
          .collectionGroup('waitlist')
          .where('title', isEqualTo: resourceTitle)
          .get();
      final candidates = waiting.docs
          .where((d) => (d.data()['status'] as String? ?? 'waiting') == 'waiting')
          .toList()
        ..sort((a, b) => ((a.data()['joinedAt'] as Timestamp?)
                    ?.toDate() ??
                DateTime.now())
            .compareTo((b.data()['joinedAt'] as Timestamp?)?.toDate() ??
                DateTime.now()));
      if (candidates.isEmpty) return;
      final doc = candidates.first;
      final ownerUid = doc.reference.parent.parent!.id;
      final batch = _db.batch();
      batch.update(doc.reference, {'status': 'offered'});
      batch.set(
        _db.collection('users').doc(ownerUid).collection('notifications').doc(),
        {
          'title': 'Waitlist spot open',
          'body': '$resourceTitle is available — '
              'claim it before the offer expires.',
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'tone': 'warning',
          'iconCodePoint': 0xe911,
        },
      );
      await batch.commit();
    } catch (_) {}
  }

  // ------------------------------------------------------------ queue writes

  Future<void> updateQueueStatus(String id, QueueStatus s) async {
    if (!_firebaseReady) return;
    await _db.collection('queue').doc(id).update({'status': s.name});
  }

  Future<void> deleteQueueEntry(String id) async {
    if (!_firebaseReady) return;
    await _db.collection('queue').doc(id).delete();
  }

  Future<void> addNotification(AppNotification n) async {
    if (!_canStream) return;
    await _notificationsRef().doc(n.id).set(_notificationToMap(n));
  }

  // --------------------------------------------------------- qr verification

  /// Staff verification: resolves a scanned or manually typed code against
  /// every booking and book reservation in the project using a
  /// collection-group query. Returns owner + state info, or null when the
  /// code matches nothing.
  Future<Map<String, dynamic>?> verifyCode(String code) async {
    if (!_firebaseReady) return null;
    final trimmed = code.trim();
    try {
      final bookings = await _db
          .collectionGroup('bookings')
          .where('qrCode', isEqualTo: trimmed)
          .limit(1)
          .get();
      if (bookings.docs.isNotEmpty) {
        final doc = bookings.docs.first;
        final data = doc.data();
        return {
          'kind': 'seat',
          'status': data['status'] as String?,
          'checkedInAt': (data['checkedInAt'] as Timestamp?)?.toDate(),
          'startTime': (data['startTime'] as Timestamp?)?.toDate(),
          'endTime': (data['endTime'] as Timestamp?)?.toDate(),
          'seatId': data['seatId'] as String?,
          'docPath': doc.reference.path,
          ...await _ownerOf(doc.reference),
        };
      }
      final reservations = await _db
          .collectionGroup('reservations')
          .where('qrCode', isEqualTo: trimmed)
          .limit(1)
          .get();
      if (reservations.docs.isNotEmpty) {
        final doc = reservations.docs.first;
        final data = doc.data();
        return {
          'kind': 'book',
          'status': data['status'] as String?,
          'pickupBy': (data['pickupBy'] as Timestamp?)?.toDate(),
          'bookId': data['bookId'] as String?,
          'docPath': doc.reference.path,
          ...await _ownerOf(doc.reference),
        };
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Marks a verified booking as checked-in (seat) or collected (book).
  Future<void> consumeVerifiedCode(String docPath, String kind) async {
    if (!_firebaseReady) return;
    final updates = kind == 'seat'
        ? <String, dynamic>{
            'checkedInAt': Timestamp.fromDate(DateTime.now()),
            'status': ReservationStatus.active.name,
          }
        : <String, dynamic>{
            'status': ReservationStatus.completed.name,
          };
    try {
      await _db.doc(docPath).update(updates);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _ownerOf(DocumentReference ref) async {
    try {
      final userDoc =
          await _db.collection('users').doc(ref.parent.parent!.id).get();
      return {
        'ownerName': userDoc.data()?['name'] as String? ?? 'Student',
        'ownerId': userDoc.data()?['studentId'] as String? ?? '—',
      };
    } catch (_) {
      return {'ownerName': 'Student', 'ownerId': '—'};
    }
  }

  // ---------------------------------------------------------- device tokens

  Future<void> saveDeviceToken(String token, String platform) async {
    if (!_canStream) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token)
        .set({
      'token': token,
      'platform': platform,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  // --------------------------------------------------- public join helpers

  BookReservation reservationFromMapPublic(
          Map<String, dynamic> m, String id, List<Book> books) =>
      _reservationFromMap(m, id, _joinBook(m['bookId'] as String?, books));

  SeatBooking bookingFromMapPublic(
          Map<String, dynamic> m, String id, List<Seat> seats) =>
      _bookingFromMap(m, id, _joinSeat(m['seatId'] as String?, seats));

  AppNotification notificationFromMapPublic(Map<String, dynamic> m, String id) =>
      _notificationFromMap(m, id);

  WaitlistEntry waitlistFromMapPublic(Map<String, dynamic> m, String id) =>
      _waitlistFromMap(m, id);

  Book _joinBook(String? bookId, List<Book> books) => books.firstWhere(
        (b) => b.id == bookId,
        orElse: () => books.isEmpty ? MockData.books.first : books.first,
      );

  Seat _joinSeat(String? seatId, List<Seat> seats) => seats.firstWhere(
        (s) => s.id == seatId,
        orElse: () => seats.isEmpty ? MockData.seats.first : seats.first,
      );

  static const Map<int, IconData> _iconRegistry = {
    0xe86c: Icons.check_circle_outline_rounded,
    0xe5e0: Icons.cancel_outlined,
    0xe911: Icons.event_seat_rounded,
    0xf04e7: Icons.event_seat_outlined,
  };

  IconData? _iconFromCodePoint(int? codePoint) {
    if (codePoint == null) return null;
    return _iconRegistry[codePoint] ?? Icons.notifications_none_rounded;
  }

  // ------------------------------------------------------------ converters

  Book _bookFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      _bookFromMap(doc.data(), doc.id);

  Book _bookFromMap(Map<String, dynamic> m, String id) => Book(
        id: id,
        title: m['title'] as String? ?? '',
        author: m['author'] as String? ?? '',
        subject: m['subject'] as String? ?? '',
        isbn: m['isbn'] as String? ?? '',
        availability:
            _enum(BookAvailability.values, m['availability'], BookAvailability.available),
        shelfLocation: m['shelfLocation'] as String? ?? '',
        copiesAvailable: (m['copiesAvailable'] as num?)?.toInt() ?? 0,
        description: m['description'] as String? ?? '',
        dueDate: (m['dueDate'] as Timestamp?)?.toDate(),
        coverColor: (m['coverColor'] as num?)?.toInt(),
      );

  Map<String, dynamic> _bookToMap(Book b, {required String id}) => {
        'title': b.title,
        'author': b.author,
        'subject': b.subject,
        'isbn': b.isbn,
        'availability': b.availability.name,
        'shelfLocation': b.shelfLocation,
        'copiesAvailable': b.copiesAvailable,
        'description': b.description,
        'dueDate': b.dueDate == null ? null : Timestamp.fromDate(b.dueDate!),
        'coverColor': b.coverColor,
      };

  Seat _seatFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      _seatFromMap(doc.data(), doc.id);

  Seat _seatFromMap(Map<String, dynamic> m, String id) => Seat(
        id: id,
        label: m['label'] as String? ?? '',
        floor: (m['floor'] as num?)?.toInt() ?? 1,
        section: m['section'] as String? ?? '',
        status: _enum(SeatStatus.values, m['status'], SeatStatus.available),
        category:
            _enum(SeatCategory.values, m['category'], SeatCategory.quietZone),
        hasPowerOutlet: m['hasPowerOutlet'] as bool? ?? false,
        hasMonitor: m['hasMonitor'] as bool? ?? false,
        nearWindow: m['nearWindow'] as bool? ?? false,
        standingDesk: m['standingDesk'] as bool? ?? false,
        row: (m['row'] as num?)?.toInt() ?? 0,
        col: (m['col'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> _seatToMap(Seat s, {required String id}) => {
        'label': s.label,
        'floor': s.floor,
        'section': s.section,
        'status': s.status.name,
        'category': s.category.name,
        'hasPowerOutlet': s.hasPowerOutlet,
        'hasMonitor': s.hasMonitor,
        'nearWindow': s.nearWindow,
        'standingDesk': s.standingDesk,
        'row': s.row,
        'col': s.col,
      };

  Map<String, dynamic> _reservationToMap(BookReservation r) => {
        'bookId': r.book.id,
        'reservedAt': Timestamp.fromDate(r.reservedAt),
        'pickupBy': Timestamp.fromDate(r.pickupBy),
        'pickupLocation': r.pickupLocation,
        'qrCode': r.qrCode,
        'status': r.status.name,
      };

  BookReservation _reservationFromMap(Map<String, dynamic> m, String id,
          Book book) =>
      BookReservation(
        id: id,
        book: book,
        reservedAt: (m['reservedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        pickupBy: (m['pickupBy'] as Timestamp?)?.toDate() ??
            DateTime.now().add(const Duration(days: 7)),
        pickupLocation: m['pickupLocation'] as String? ?? 'Main Library',
        qrCode: m['qrCode'] as String? ?? id,
        status:
            _enum(ReservationStatus.values, m['status'], ReservationStatus.ready),
      );

  Map<String, dynamic> _bookingToMap(SeatBooking b) => {
        'seatId': b.seat.id,
        'date': Timestamp.fromDate(b.date),
        'startTime': Timestamp.fromDate(b.startTime),
        'endTime': Timestamp.fromDate(b.endTime),
        'qrCode': b.qrCode,
        'status': b.status.name,
        'checkedInAt':
            b.checkedInAt == null ? null : Timestamp.fromDate(b.checkedInAt!),
      };

  SeatBooking _bookingFromMap(Map<String, dynamic> m, String id, Seat seat) =>
      SeatBooking(
        id: id,
        seat: seat,
        date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        startTime: (m['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endTime: (m['endTime'] as Timestamp?)?.toDate() ??
            DateTime.now().add(const Duration(hours: 3)),
        qrCode: m['qrCode'] as String? ?? id,
        status:
            _enum(ReservationStatus.values, m['status'], ReservationStatus.active),
        checkedInAt: (m['checkedInAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> _waitlistToMap(WaitlistEntry e) => {
        'type': e.type.name,
        'title': e.title,
        'subtitle': e.subtitle,
        'position': e.position,
        'joinedAt': Timestamp.fromDate(e.joinedAt),
        'estimatedWaitMinutes': e.estimatedWaitMinutes,
        'seatPreference': e.seatPreference,
      };

  WaitlistEntry _waitlistFromMap(Map<String, dynamic> m, String id) =>
      WaitlistEntry(
        id: id,
        type: _enum(WaitlistType.values, m['type'], WaitlistType.seat),
        title: m['title'] as String? ?? '',
        subtitle: m['subtitle'] as String? ?? '',
        position: (m['position'] as num?)?.toInt() ?? 1,
        joinedAt: (m['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        estimatedWaitMinutes: (m['estimatedWaitMinutes'] as num?)?.toInt(),
        seatPreference: m['seatPreference'] as String?,
      );

  Map<String, dynamic> _notificationToMap(AppNotification n) => {
        'title': n.title,
        'body': n.body,
        'timestamp': Timestamp.fromDate(n.timestamp),
        'tone': n.tone.name,
        'iconCodePoint': n.icon?.codePoint,
      };

  AppNotification _notificationFromMap(Map<String, dynamic> m, String id) =>
      AppNotification(
        id: id,
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        tone: _enum(BannerToneKind.values, m['tone'], BannerToneKind.info),
        icon: _iconFromCodePoint(m['iconCodePoint'] as int?),
      );

  Map<String, dynamic> _profileToMap(UserProfile p) => {
        'name': p.name,
        'studentId': p.studentId,
        'email': p.email,
        'role': p.role.name,
        'reservationsVisibleToStaffOnly': p.reservationsVisibleToStaffOnly,
      };

  UserProfile _profileFromMap(Map<String, dynamic> m, String id) =>
      UserProfile(
        name: m['name'] as String? ?? 'Library Member',
        studentId: m['studentId'] as String? ?? id,
        email: m['email'] as String? ?? '',
        role: _enum(UserRole.values, m['role'], UserRole.student),
        reservationsVisibleToStaffOnly:
            m['reservationsVisibleToStaffOnly'] as bool? ?? true,
      );

  T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.firstWhere(
        (v) => v.name == name,
        orElse: () => fallback,
      );
}
