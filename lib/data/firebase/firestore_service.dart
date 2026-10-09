import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/state/data_mode.dart';
import '../../models/models.dart';
import '../../services/functions_service.dart';
import '../../services/preferences_store.dart';
import '../book_search.dart';
import '../mock/mock_data.dart';
import 'auth_failure.dart';

/// Opaque search cursor: the last document of each underlying query.
class _BookCursor {
  const _BookCursor({this.byTitle, this.byAuthor, this.single});
  final DocumentSnapshot<Map<String, dynamic>>? byTitle;
  final DocumentSnapshot<Map<String, dynamic>>? byAuthor;
  final DocumentSnapshot<Map<String, dynamic>>? single;
}

/// Thin Firestore + Firebase Auth repository. Every screen keeps talking to
/// [AppState]; this class is where the real network happens.
///
/// Production code never invents data: when Firebase is unavailable, sign-in
/// throws an [AuthFailure]. Sample profiles exist only under `flutter test`
/// or the explicit `DEMO_MODE` build flag (see [mockDataAllowed]).
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  /// True when the app is connected to a Firebase project.
  bool get isReady => _firebaseReady;

  static const _demoPassword = 'quickbook123';

  String? get uid => _firebaseReady ? _auth.currentUser?.uid : null;

  /// Set when the role could not be verified at the last sign-in.
  String? roleNotice;

  UserProfile? _me;
  final Set<String> _consumedPaths = {};

  // ------------------------------------------------------------------ auth

  UserProfile _demoProfile(UserRole role) =>
      role == UserRole.staff ? MockData.staff : MockData.student;

  AuthFailure get _notConfigured => const AuthFailure('not-configured',
      'The library service is not available right now. Try again later.');

  /// Signs in via Google OAuth, using the Google account's name and photo.
  Future<UserProfile> signInWithGoogle(UserRole role) async {
    if (!_firebaseReady) {
      if (mockDataAllowed) return _demoProfile(role);
      throw _notConfigured;
    }
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw const AuthFailure('cancelled', 'Google sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final user = (await _auth.signInWithCredential(credential)).user;
      if (user == null) {
        throw const AuthFailure('unknown', 'Google sign-in failed.');
      }
      final profile = await _loadOrCreateProfile(
        user,
        name: user.displayName ?? googleUser.displayName,
        photoUrl: user.photoURL ?? googleUser.photoUrl,
      );
      return await _finishSignIn(user, profile);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromAuth(e);
    } catch (_) {
      throw const AuthFailure(
          'network', 'Google sign-in failed. Check your connection.');
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
    final cleanName =
        fullName.trim().isEmpty ? 'Library Member' : fullName.trim();
    final cleanStudentId = (studentId != null && studentId.trim().isNotEmpty)
        ? studentId.trim()
        : cleanEmail.split('@').first;

    if (!_firebaseReady) {
      if (mockDataAllowed) {
        return UserProfile(
          name: cleanName,
          studentId: cleanStudentId,
          email: cleanEmail,
          role: role,
        );
      }
      throw _notConfigured;
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('unknown', 'Registration failed.');
      }
      try {
        await user.updateDisplayName(cleanName);
      } catch (_) {}
      final profile = await _loadOrCreateProfile(
        user,
        name: cleanName,
        studentId: cleanStudentId,
      );
      return await _finishSignIn(user, profile);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromAuth(e);
    } catch (_) {
      throw const AuthFailure(
          'network', 'Registration failed. Check your connection.');
    }
  }

  /// Signs in an existing user with Email and Password.
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cleanEmail = email.trim();
    if (!_firebaseReady) {
      if (mockDataAllowed) return _demoProfile(role);
      throw _notConfigured;
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('unknown', 'Sign-in failed.');
      }
      final profile = await _loadOrCreateProfile(user);
      return await _finishSignIn(user, profile);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromAuth(e);
    } catch (_) {
      throw const AuthFailure(
          'network', 'Sign-in failed. Check your connection.');
    }
  }

  /// Legacy campus-id sign-in that auto-provisions an account with a shared
  /// password. Only available in demo/test builds; real builds must use
  /// [signInWithEmail] or [signInWithGoogle].
  Future<UserProfile> signIn(String identifier, UserRole role) async {
    if (!mockDataAllowed) {
      throw const AuthFailure('not-supported',
          'Sign in with your email and password or Google account.');
    }
    if (!_firebaseReady) return _demoProfile(role);
    final email = identifier.contains('@')
        ? identifier.trim()
        : '${identifier.trim().toLowerCase()}@sliit.lk';
    try {
      UserCredential credential;
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
        } else {
          rethrow;
        }
      }
      final user = credential.user;
      if (user == null) return _demoProfile(role);
      final profile = await _loadOrCreateProfile(user);
      return await _finishSignIn(user, profile);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromAuth(e);
    }
  }

  Future<void> signOut() async {
    _me = null;
    if (!_firebaseReady) return;
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Loads the profile doc, creating it for first-time users. Never reads
  /// the role from the document: privileges come from the token claim.
  Future<UserProfile> _loadOrCreateProfile(
    User user, {
    String? name,
    String? studentId,
    String? photoUrl,
  }) async {
    final fallback = UserProfile(
      name: (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (user.displayName ?? 'Library Member'),
      studentId: studentId ??
          user.email?.split('@').first ??
          user.uid.substring(0, 8),
      email: user.email ?? '',
      role: UserRole.student,
      photoUrl: photoUrl ?? user.photoURL,
      uid: user.uid,
    );
    try {
      final ref = _db.collection('users').doc(user.uid);
      final doc = await ref.get();
      if (doc.exists) {
        final p = _profileFromMap(doc.data()!, user.uid);
        return p.copyWith(
          photoUrl: fallback.photoUrl,
          phone: await PreferencesStore.loadPhone(user.uid),
        );
      }
      await ref.set(_profileToMap(fallback));
    } catch (_) {
      // Offline or rules not ready: continue with the auth identity.
    }
    return fallback;
  }

  /// Calls `claimRole`, force-refreshes the ID token and reads the `role`
  /// claim. Falls back to student (never staff) if the server is unreachable.
  Future<UserRole> _resolveRole(User user, {bool cachedFirst = false}) async {
    roleNotice = null;
    try {
      if (cachedFirst) {
        final cached = (await user.getIdTokenResult()).claims?['role'];
        if (cached == 'staff' || cached == 'student') {
          return cached == 'staff' ? UserRole.staff : UserRole.student;
        }
      }
      await FunctionsService.instance.claimRole();
      final token = await user.getIdTokenResult(true);
      return token.claims?['role'] == 'staff'
          ? UserRole.staff
          : UserRole.student;
    } catch (_) {
      roleNotice = 'Could not verify your library role, so you are signed '
          'in as a student. Check your connection and sign in again.';
      return UserRole.student;
    }
  }

  Future<UserProfile> _finishSignIn(User user, UserProfile profile,
      {bool cachedFirst = false}) async {
    final role = await _resolveRole(user, cachedFirst: cachedFirst);
    _me = profile.copyWith(role: role, uid: user.uid);
    return _me!;
  }

  /// Restores the profile for an existing Firebase session.
  Future<UserProfile?> loadProfile() async {
    if (!_firebaseReady) return null;
    final user = _auth.currentUser;
    if (user == null) return null;
    final profile = await _loadOrCreateProfile(user);
    return _finishSignIn(user, profile, cachedFirst: true);
  }

  // ---------------------------------------------------------------- account

  /// Updates editable profile fields on the user document (and the auth
  /// display name). Returns the merged profile.
  Future<UserProfile> updateProfile(
    UserProfile current, {
    String? name,
    String? phone,
    String? studentId,
    bool? reservationsVisibleToStaffOnly,
  }) async {
    final next = current.copyWith(
      name: name,
      phone: phone,
      studentId: studentId,
      reservationsVisibleToStaffOnly: reservationsVisibleToStaffOnly,
    );
    // The profile rules have no `phone` field, so it stays on this device.
    if (phone != null && uid != null) {
      await PreferencesStore.savePhone(uid!, phone);
    }
    if (_canStream) {
      await _db.collection('users').doc(uid).set({
        'name': next.name,
        'studentId': next.studentId,
        'reservationsVisibleToStaffOnly': next.reservationsVisibleToStaffOnly,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (name != null) {
        try {
          await _auth.currentUser?.updateDisplayName(name);
        } catch (_) {}
      }
    }
    _me = next;
    return next;
  }

  /// Saves reminder/notification choices on the profile (`notificationPrefs`)
  /// where the server reads them for push decisions.
  Future<void> saveNotificationPrefs(NotificationPreferences p) async {
    if (!_canStream) return;
    await _db.collection('users').doc(uid).set({
      'notificationPrefs': _prefsToMap(p),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Display names for staff views, read from the owners' profiles.
  Future<Map<String, ({String name, String studentId})>> fetchUserCards(
      Iterable<String> uids) async {
    final out = <String, ({String name, String studentId})>{};
    if (!_canStream) return out;
    await Future.wait(uids.map((id) async {
      try {
        final d = await _db.collection('users').doc(id).get();
        final m = d.data();
        if (m != null) {
          out[id] = (
            name: m['name'] as String? ?? 'Student',
            studentId: m['studentId'] as String? ?? id,
          );
        }
      } catch (_) {}
    }));
    return out;
  }

  /// Asks the server to erase this user's data, then removes the auth user.
  Future<void> deleteAccount() async {
    if (_firebaseReady && _auth.currentUser != null) {
      await FunctionsService.instance.deleteAccountData();
      try {
        await _auth.currentUser?.delete();
      } catch (_) {
        // Needs a recent login; the data is already gone, sign out instead.
      }
    }
    await signOut();
  }

  /// Server-side export of everything held about this user, as JSON text.
  Future<Map<String, dynamic>> exportAccountData() =>
      FunctionsService.instance.exportAccountData();

  // ------------------------------------------------------------------ seed

  /// Demo/test only: pushes the sample catalogue and seat map into an empty
  /// project. A no-op in production builds.
  Future<void> seedIfEmpty() async {
    if (!_firebaseReady || uid == null) return;
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
      // Missing permissions: demo seeding is best-effort.
    }
  }

  // ---------------------------------------------------------------- streams

  bool get _canStream => _firebaseReady && uid != null;

  // All streams include metadata changes so AppState can tell cached data
  // (`metadata.isFromCache`) from server data and detect offline.

  Stream<List<Book>> booksStream() => booksSnapshot()
      .map((s) => s.docs.map(_bookFromDoc).toList());

  Stream<List<Seat>> seatsStream() => seatsSnapshot()
      .map((s) => s.docs.map(_seatFromDoc).toList());

  Stream<QuerySnapshot<Map<String, dynamic>>> booksSnapshot() => _canStream
      ? _db.collection('books').snapshots(includeMetadataChanges: true)
      : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> seatsSnapshot() => _canStream
      ? _db.collection('seats').snapshots(includeMetadataChanges: true)
      : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> userReservationsSnapshot() =>
      _canStream
          ? _reservationsRef().snapshots(includeMetadataChanges: true)
          : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> userBookingsSnapshot() =>
      _canStream
          ? _bookingsRef().snapshots(includeMetadataChanges: true)
          : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> userNotificationsSnapshot() =>
      _canStream
          ? _notificationsRef().snapshots(includeMetadataChanges: true)
          : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> userWaitlistSnapshot() =>
      _canStream
          ? _waitlistRef().snapshots(includeMetadataChanges: true)
          : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> userLoansSnapshot() =>
      _canStream
          ? _loansQuery().snapshots(includeMetadataChanges: true)
          : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> queueSnapshot() => _canStream
      ? _db.collection('queue').snapshots(includeMetadataChanges: true)
      : const Stream.empty();

  // Staff-wide streams (collection groups). Plain collection-group reads
  // with no filter/order need no composite index; they only work when the
  // rules allow staff to read the group.

  Stream<QuerySnapshot<Map<String, dynamic>>> allReservationsSnapshot() =>
      _canStream
          ? _db
              .collectionGroup('reservations')
              .snapshots(includeMetadataChanges: true)
          : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> allBookingsSnapshot() =>
      _canStream
          ? _db
              .collectionGroup('bookings')
              .snapshots(includeMetadataChanges: true)
          : const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>> allWaitlistSnapshot() =>
      _canStream
          ? _db
              .collectionGroup('waitlist')
              .snapshots(includeMetadataChanges: true)
          : const Stream.empty();

  /// One-shot fetches straight from the server (pull-to-refresh). Keys match
  /// the ones AppState uses for its listeners.
  Future<Map<String, QuerySnapshot<Map<String, dynamic>>>> fetchFromServer(
      {required bool staff}) async {
    if (!_canStream) return {};
    const server = GetOptions(source: Source.server);
    final queries = <String, Query<Map<String, dynamic>>>{
      'books': _db.collection('books'),
      'seats': _db.collection('seats'),
      'reservations': _reservationsRef(),
      'bookings': _bookingsRef(),
      'notifications': _notificationsRef(),
      'waitlist': _waitlistRef(),
      'loans': _loansQuery(),
      if (staff) ...{
        'queue': _db.collection('queue'),
        'allReservations': _db.collectionGroup('reservations'),
        'allBookings': _db.collectionGroup('bookings'),
        'allWaitlist': _db.collectionGroup('waitlist'),
      },
    };
    final out = <String, QuerySnapshot<Map<String, dynamic>>>{};
    final keys = queries.keys.toList();
    final results = await Future.wait(
      keys.map((k) => queries[k]!.get(server)),
    );
    for (var i = 0; i < keys.length; i++) {
      out[keys[i]] = results[i];
    }
    return out;
  }

  CollectionReference<Map<String, dynamic>> _reservationsRef() =>
      _db.collection('users').doc(uid).collection('reservations');

  CollectionReference<Map<String, dynamic>> _bookingsRef() =>
      _db.collection('users').doc(uid).collection('bookings');

  CollectionReference<Map<String, dynamic>> _notificationsRef() =>
      _db.collection('users').doc(uid).collection('notifications');

  CollectionReference<Map<String, dynamic>> _waitlistRef() =>
      _db.collection('users').doc(uid).collection('waitlist');

  Query<Map<String, dynamic>> _loansQuery() =>
      _db.collection('loans').where('userId', isEqualTo: uid);

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
        final open = status == SeatStatus.available.name ||
            status == SeatStatus.limited.name;
        if (seatSnap.exists && !open) {
          throw StateError('seat-taken');
        }
        tx.set(_bookingsRef().doc(b.id), _bookingToMap(b));
        // The rules require the holder and booking id with the flip.
        tx.update(seatRef, {
          'status': seatStatus.name,
          'heldBy': uid,
          'bookingId': b.id,
        });
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
    batch.update(_db.collection('seats').doc(b.seat.id), {
      'status': 'available',
      'heldBy': null,
      'bookingId': null,
    });
    await batch.commit();
  }

  /// Not allowed for students (rules): check-in happens when staff scan the
  /// pass via `verifyQrPass`. Kept for demo builds.
  Future<void> checkInBooking(String id) async {
    if (!_canStream || !mockDataAllowed) return;
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

  /// Accepts or declines a pending offer through the server callable.
  Future<void> respondToWaitlistOffer(String entryId, bool accept) =>
      FunctionsService.instance.respondToWaitlistOffer(entryId, accept);

  /// Client-side promotion of the next waiting person. The server now owns
  /// this; kept for demo builds only.
  @Deprecated('Waitlist promotion is server-side')
  Future<void> promoteNextOnWaitlist({
    required String resourceTitle,
    required String resourceSubtitle,
  }) async {
    if (!_firebaseReady || !mockDataAllowed) return;
    try {
      final waiting = await _db
          .collectionGroup('waitlist')
          .where('title', isEqualTo: resourceTitle)
          .get();
      final candidates = waiting.docs
          .where(
              (d) => (d.data()['status'] as String? ?? 'waiting') == 'waiting')
          .toList()
        ..sort((a, b) => (_dt(a.data()['joinedAt']) ?? DateTime.now())
            .compareTo(_dt(b.data()['joinedAt']) ?? DateTime.now()));
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
          'type': 'offer',
          'targetId': doc.id,
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

  // ----------------------------------------------------- notification writes

  /// Notifications are written by the server (clients cannot create them);
  /// this only works for staff accounts and demo data.
  Future<void> addNotification(AppNotification n) async {
    if (!_canStream) return;
    await _notificationsRef().doc(n.id).set(_notificationToMap(n));
  }

  /// Owners may only flip the boolean `read` field.
  Future<void> markNotificationRead(String id) async {
    if (!_canStream) return;
    await _notificationsRef().doc(id).update({'read': true});
  }

  Future<void> markNotificationsRead(Iterable<String> ids) async {
    if (!_canStream) return;
    final batch = _db.batch();
    var n = 0;
    for (final id in ids) {
      batch.update(_notificationsRef().doc(id), {'read': true});
      n++;
    }
    if (n > 0) await batch.commit();
  }

  // ------------------------------------------------------------ loan writes

  Future<void> renewLoan(String loanId) =>
      FunctionsService.instance.renewLoan(loanId);

  Future<void> checkoutBook(Map<String, dynamic> payload) =>
      FunctionsService.instance.checkoutBook(payload);

  Future<void> checkinBook(Map<String, dynamic> payload) =>
      FunctionsService.instance.checkinBook(payload);

  // ------------------------------------------------------------ staff writes

  /// Sets the copy counts of a book and keeps `availability` consistent.
  Future<void> setCopies(String bookId,
      {required int available, int? total}) async {
    if (!_canStream) return;
    await _db.collection('books').doc(bookId).update({
      'copiesAvailable': available,
      if (total != null) 'copiesTotal': total,
      'availability': (available > 0
              ? BookAvailability.available
              : BookAvailability.onLoan)
          .name,
    });
  }

  /// Creates a catalogue entry; returns its new id.
  Future<String> addBook(Book b) async {
    if (!_canStream) return b.id;
    final ref = b.id.isEmpty
        ? _db.collection('books').doc()
        : _db.collection('books').doc(b.id);
    await ref.set({
      ..._bookToMap(b, id: ref.id),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> editBook(Book b) async {
    if (!_canStream) return;
    await _db.collection('books').doc(b.id).set(
          _bookToMap(b, id: b.id),
          SetOptions(merge: true),
        );
  }

  Future<void> setSeatStatus(String seatId, SeatStatus status) async {
    if (!_canStream) return;
    await _db.collection('seats').doc(seatId).update({'status': status.name});
  }

  // ----------------------------------------------------------------- search

  /// Server-friendly catalogue search with cursor pagination. Prefix match on
  /// `titleLower` / `authorLower`; if that finds nothing on the first page,
  /// falls back to a substring filter over the first 100 titles.
  ///
  /// Indexes (composite): `subject ASC, titleLower ASC`,
  /// `subject ASC, authorLower ASC`, `availability ASC, titleLower ASC`,
  /// `availability ASC, authorLower ASC`, and with a subject filter also
  /// `subject ASC, availability ASC, titleLower ASC` (+ authorLower, createdAt
  /// DESC, copiesAvailable DESC variants for the matching sort).
  Future<BookPage> searchBooks({
    String query = '',
    String? subject,
    bool availableOnly = false,
    BookSort sort = BookSort.title,
    Object? startAfter,
    int pageSize = 20,
  }) async {
    if (!_canStream) return BookPage.empty;
    final prev = startAfter is _BookCursor ? startAfter : null;

    Query<Map<String, dynamic>> base = _db.collection('books');
    if (subject != null && subject.isNotEmpty) {
      base = base.where('subject', isEqualTo: subject);
    }
    if (availableOnly) {
      base = base.where('availability',
          isEqualTo: BookAvailability.available.name);
    }

    final key = searchKey(query);
    if (key.isEmpty) {
      Query<Map<String, dynamic>> q;
      switch (sort) {
        case BookSort.title:
          q = base.orderBy('titleLower');
        case BookSort.author:
          q = base.orderBy('authorLower');
        case BookSort.newest:
          q = base.orderBy('createdAt', descending: true);
        case BookSort.availability:
          q = base.orderBy('copiesAvailable', descending: true);
      }
      if (prev?.single != null) q = q.startAfterDocument(prev!.single!);
      final snap = await q.limit(pageSize).get();
      return BookPage(
        books: snap.docs.map(_bookFromDoc).toList(),
        cursor: snap.docs.isEmpty ? null : _BookCursor(single: snap.docs.last),
        hasMore: snap.docs.length >= pageSize,
      );
    }

    Query<Map<String, dynamic>> prefix(String field) => base
        .where(field, isGreaterThanOrEqualTo: key)
        .where(field, isLessThan: '$key')
        .orderBy(field);

    var byTitle = prefix('titleLower');
    var byAuthor = prefix('authorLower');
    final doneTitle = startAfter != null && prev?.byTitle == null;
    final doneAuthor = startAfter != null && prev?.byAuthor == null;
    if (prev?.byTitle != null) {
      byTitle = byTitle.startAfterDocument(prev!.byTitle!);
    }
    if (prev?.byAuthor != null) {
      byAuthor = byAuthor.startAfterDocument(prev!.byAuthor!);
    }
    final results = await Future.wait([
      doneTitle ? Future.value(null) : byTitle.limit(pageSize).get(),
      doneAuthor ? Future.value(null) : byAuthor.limit(pageSize).get(),
    ]);
    final titleDocs = results[0]?.docs ?? const [];
    final authorDocs = results[1]?.docs ?? const [];
    final merged = <String, Book>{
      for (final d in [...titleDocs, ...authorDocs]) d.id: _bookFromDoc(d),
    };

    if (merged.isEmpty && startAfter == null) {
      // No prefix hit: scan the first 100 titles for a substring match.
      final snap = await base.orderBy('titleLower').limit(100).get();
      return BookPage(
        books: filterAndSortBooks(
          snap.docs.map(_bookFromDoc),
          query: query,
          sort: sort,
        ),
      );
    }
    return BookPage(
      books: filterAndSortBooks(merged.values, sort: sort),
      cursor: _BookCursor(
        byTitle: titleDocs.length >= pageSize ? titleDocs.last : null,
        byAuthor: authorDocs.length >= pageSize ? authorDocs.last : null,
      ),
      hasMore:
          titleDocs.length >= pageSize || authorDocs.length >= pageSize,
    );
  }

  // --------------------------------------------------------- qr verification

  /// Staff verification: resolves a scanned or typed code through the
  /// `verifyQrPass` callable. If the function is not deployed yet, falls back
  /// to a collection-group lookup (needs a collection-group index on
  /// `qrCode` for `bookings` and `reservations`). Returns owner + state info,
  /// or null when the code matches nothing.
  Future<Map<String, dynamic>?> verifyCode(String code) async {
    if (!_firebaseReady) return null;
    final trimmed = code.trim();
    try {
      final res = await FunctionsService.instance.verifyQrPass(trimmed);
      final result = res['result'] as String?;
      if (res.isEmpty || result == 'notFound' || result == 'malformed') {
        return null;
      }
      final path = res['docPath'] as String?;
      if (path != null && res['consumed'] == true) _consumedPaths.add(path);
      // Normalise to the shape the verification screen reads.
      return {
        ...res,
        'ownerId': res['ownerStudentId'] ?? res['ownerId'] ?? '—',
        for (final k in ['startTime', 'endTime', 'pickupBy', 'checkedInAt'])
          k: _dt(res[k]),
      };
    } on CallableFailure catch (e) {
      // Only a missing function falls through to the query path; anything
      // else (offline, denied) reports "no match" rather than guessing.
      if (e.code != 'not-found' && e.code != 'unimplemented') return null;
    } catch (_) {
      return null;
    }
    return _verifyViaQuery(trimmed);
  }

  Future<Map<String, dynamic>?> _verifyViaQuery(String trimmed) async {
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
          'checkedInAt': _dt(data['checkedInAt']),
          'startTime': _dt(data['startTime']),
          'endTime': _dt(data['endTime']),
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
          'pickupBy': _dt(data['pickupBy']),
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
    // `verifyQrPass` already consumed it server-side.
    if (!_firebaseReady || _consumedPaths.contains(docPath)) return;
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
      _reservationFromMap(m, id, _joinBook(m, books));

  SeatBooking bookingFromMapPublic(
          Map<String, dynamic> m, String id, List<Seat> seats) =>
      _bookingFromMap(m, id, _joinSeat(m['seatId'] as String?, seats));

  AppNotification notificationFromMapPublic(Map<String, dynamic> m, String id) =>
      _notificationFromMap(m, id);

  WaitlistEntry waitlistFromMapPublic(Map<String, dynamic> m, String id) =>
      _waitlistFromMap(m, id);

  Loan loanFromMapPublic(Map<String, dynamic> m, String id) =>
      _loanFromMap(m, id);

  Book bookFromDocPublic(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      _bookFromDoc(d);

  Seat seatFromDocPublic(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      _seatFromDoc(d);

  /// Staff view of a book reservation or seat booking in a collection group.
  AdminReservation adminReservationFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> d, {
    required bool seat,
    required List<Book> books,
    required List<Seat> seats,
    Map<String, ({String name, String studentId})> owners = const {},
  }) {
    final m = d.data();
    final owner = d.reference.parent.parent?.id ?? '';
    final String title;
    final String subtitle;
    final DateTime? due;
    final DateTime reservedAt;
    if (seat) {
      final s = _joinSeat(m['seatId'] as String?, seats);
      title = 'Seat ${s.label}';
      subtitle = 'Floor ${s.floor} · ${s.zoneLabel}';
      due = _dt(m['endTime']);
      reservedAt = _dt(m['startTime']) ?? DateTime.now();
    } else {
      final b = _joinBook(m, books);
      title = b.title;
      subtitle = '${b.author} · ${b.shelfLocation}';
      due = _dt(m['pickupBy']);
      reservedAt = _dt(m['reservedAt']) ?? DateTime.now();
    }
    return AdminReservation(
      id: d.id,
      ownerUid: owner,
      studentName: owners[owner]?.name ?? 'Student',
      studentId: owners[owner]?.studentId ?? owner,
      isSeat: seat,
      itemTitle: title,
      itemSubtitle: subtitle,
      reservedAt: reservedAt,
      dueAt: due,
      status: _enum(ReservationStatus.values, m['status'],
          seat ? ReservationStatus.active : ReservationStatus.ready),
      path: d.reference.path,
    );
  }

  AdminWaitlistItem adminWaitlistFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> d, {
    Map<String, ({String name, String studentId})> owners = const {},
  }) {
    final m = d.data();
    final owner = d.reference.parent.parent?.id ?? '';
    return AdminWaitlistItem(
      id: d.id,
      ownerUid: owner,
      studentName: owners[owner]?.name ?? 'Student',
      studentId: owners[owner]?.studentId ?? owner,
      entry: _waitlistFromMap(m, d.id),
    );
  }

  /// Joins the book for a reservation: the live catalogue entry when found,
  /// otherwise a stub built from denormalised fields. Never sample data.
  Book _joinBook(Map<String, dynamic> m, List<Book> books) {
    final id = m['bookId'] as String?;
    for (final b in books) {
      if (b.id == id) return b;
    }
    return Book(
      id: id ?? '',
      title: (m['bookTitle'] ?? m['title']) as String? ?? 'Book',
      author: m['author'] as String? ?? '',
      subject: '',
      isbn: '',
      availability: BookAvailability.onLoan,
      shelfLocation: m['pickupLocation'] as String? ?? '',
      copiesAvailable: 0,
      coverColor: (m['coverColor'] as num?)?.toInt(),
    );
  }

  Seat _joinSeat(String? seatId, List<Seat> seats) {
    for (final s in seats) {
      if (s.id == seatId) return s;
    }
    return Seat(
      id: seatId ?? '',
      label: seatId ?? '—',
      floor: 1,
      section: '',
      status: SeatStatus.occupied,
      category: SeatCategory.quietZone,
      hasPowerOutlet: false,
      hasMonitor: false,
      nearWindow: false,
      row: 0,
      col: 0,
    );
  }

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

  /// Accepts a Firestore Timestamp, epoch millis, or ISO string.
  DateTime? _dt(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Timestamp? _ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d);

  Book _bookFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      _bookFromMap(doc.data(), doc.id);

  Book _bookFromMap(Map<String, dynamic> m, String id) => Book(
        id: id,
        title: m['title'] as String? ?? '',
        author: m['author'] as String? ?? '',
        subject: m['subject'] as String? ?? '',
        isbn: m['isbn'] as String? ?? '',
        availability: _enum(
            BookAvailability.values, m['availability'], BookAvailability.available),
        shelfLocation: m['shelfLocation'] as String? ?? '',
        copiesAvailable: (m['copiesAvailable'] as num?)?.toInt() ?? 0,
        description: m['description'] as String? ?? '',
        dueDate: _dt(m['dueDate']),
        coverColor: (m['coverColor'] as num?)?.toInt(),
        totalCopies: (m['copiesTotal'] as num?)?.toInt(),
        createdAt: _dt(m['createdAt']),
      );

  Map<String, dynamic> _bookToMap(Book b, {required String id}) => {
        'title': b.title,
        'author': b.author,
        'titleLower': searchKey(b.title),
        'authorLower': searchKey(b.author),
        'subject': b.subject,
        'isbn': b.isbn,
        'availability': b.availability.name,
        'shelfLocation': b.shelfLocation,
        'copiesAvailable': b.copiesAvailable,
        if (b.totalCopies != null) 'copiesTotal': b.totalCopies,
        'description': b.description,
        'dueDate': _ts(b.dueDate),
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

  // The rules allow only `userId` as an owner marker on these documents.
  Map<String, dynamic> _ownerFields() => {'userId': uid};

  Map<String, dynamic> _reservationToMap(BookReservation r) => {
        'bookId': r.book.id,
        'bookTitle': r.book.title,
        'reservedAt': Timestamp.fromDate(r.reservedAt),
        'pickupBy': Timestamp.fromDate(r.pickupBy),
        'pickupLocation': r.pickupLocation,
        'qrCode': r.qrCode,
        'status': r.status.name,
        ..._ownerFields(),
      };

  BookReservation _reservationFromMap(
          Map<String, dynamic> m, String id, Book book) =>
      BookReservation(
        id: id,
        book: book,
        reservedAt: _dt(m['reservedAt']) ?? DateTime.now(),
        pickupBy: _dt(m['pickupBy']) ??
            DateTime.now().add(const Duration(days: 7)),
        pickupLocation: m['pickupLocation'] as String? ?? 'Main Library',
        qrCode: (m['qrPass'] ?? m['qrCode']) as String? ?? id,
        status: _resStatus(m['status'], ReservationStatus.ready),
      );

  Map<String, dynamic> _bookingToMap(SeatBooking b) => {
        'seatId': b.seat.id,
        'date': Timestamp.fromDate(b.date),
        'startTime': Timestamp.fromDate(b.startTime),
        'endTime': Timestamp.fromDate(b.endTime),
        'qrCode': b.qrCode,
        'status': b.status.name,
        'checkedInAt': _ts(b.checkedInAt),
        ..._ownerFields(),
      };

  SeatBooking _bookingFromMap(Map<String, dynamic> m, String id, Seat seat) =>
      SeatBooking(
        id: id,
        seat: seat,
        date: _dt(m['date']) ?? DateTime.now(),
        startTime: _dt(m['startTime']) ?? DateTime.now(),
        endTime: _dt(m['endTime']) ??
            DateTime.now().add(const Duration(hours: 3)),
        qrCode: (m['qrPass'] ?? m['qrCode']) as String? ?? id,
        status: _resStatus(m['status'], ReservationStatus.active),
        checkedInAt: _dt(m['checkedInAt']),
      );

  Map<String, dynamic> _waitlistToMap(WaitlistEntry e) => {
        'type': e.type.name,
        'title': e.title,
        'subtitle': e.subtitle,
        'position': e.position,
        'joinedAt': Timestamp.fromDate(e.joinedAt),
        'estimatedWaitMinutes': e.estimatedWaitMinutes,
        'seatPreference': e.seatPreference,
        'status': e.status.name,
        // Required by the rules; the server promotes by this id.
        'resourceId': e.resourceId ?? e.title,
        ..._ownerFields(),
      };

  WaitlistEntry _waitlistFromMap(Map<String, dynamic> m, String id) =>
      WaitlistEntry(
        id: id,
        type: _enum(WaitlistType.values, m['type'], WaitlistType.seat),
        title: m['title'] as String? ?? '',
        subtitle: m['subtitle'] as String? ?? '',
        position: (m['position'] as num?)?.toInt() ?? 1,
        joinedAt: _dt(m['joinedAt']) ?? DateTime.now(),
        estimatedWaitMinutes: (m['estimatedWaitMinutes'] as num?)?.toInt(),
        seatPreference: m['seatPreference'] as String?,
        status:
            _enum(WaitlistStatus.values, m['status'], WaitlistStatus.waiting),
        offerExpiresAt: _dt(m['offerExpiresAt']),
        resourceId: (m['resourceId'] ?? m['bookId'] ?? m['seatId']) as String?,
      );

  Map<String, dynamic> _notificationToMap(AppNotification n) => {
        'title': n.title,
        'body': n.body,
        'timestamp': Timestamp.fromDate(n.timestamp),
        'tone': n.tone.name,
        'iconCodePoint': n.icon?.codePoint,
        'type': n.type.name,
        if (n.targetId != null) 'targetId': n.targetId,
        'read': n.isRead,
      };

  AppNotification _notificationFromMap(Map<String, dynamic> m, String id) {
    final target = NotificationTarget.fromMap(m);
    return AppNotification(
      id: id,
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      timestamp: _dt(m['timestamp'] ?? m['createdAt']) ?? DateTime.now(),
      tone: _enum(BannerToneKind.values, m['tone'], BannerToneKind.info),
      icon: _iconFromCodePoint((m['iconCodePoint'] as num?)?.toInt()),
      type: target.type,
      targetId: target.id,
      readAt: m['read'] == true
          ? (_dt(m['readAt']) ?? _dt(m['timestamp']) ?? DateTime.now())
          : _dt(m['readAt']),
      offerExpiresAt: _dt(m['offerExpiresAt']),
    );
  }

  Loan _loanFromMap(Map<String, dynamic> m, String id) => Loan(
        id: id,
        userId: m['userId'] as String? ?? '',
        bookId: m['bookId'] as String? ?? '',
        title: (m['bookTitle'] ?? m['title']) as String? ?? 'Book',
        author: m['author'] as String? ?? '',
        checkedOutAt: _dt(m['checkedOutAt']) ?? DateTime.now(),
        dueAt: _dt(m['dueDate'] ?? m['dueAt']) ?? DateTime.now(),
        returnedAt: _dt(m['returnedAt']),
        renewals: (m['renewals'] as num?)?.toInt() ?? 0,
        fineAccrued: (m['fineAccrued'] as num?) ?? 0,
        status: _enum(LoanStatus.values, m['status'], LoanStatus.active),
        coverColor: (m['coverColor'] as num?)?.toInt(),
        fineCurrency: m['fineCurrency'] as String? ?? 'LKR',
      );

  /// Only the keys the profile rules allow. Role is absent on purpose:
  /// privileges come from the token claim. Phone and photo are not stored.
  Map<String, dynamic> _profileToMap(UserProfile p) => {
        'name': p.name,
        'studentId': p.studentId,
        'email': p.email,
        'reservationsVisibleToStaffOnly': p.reservationsVisibleToStaffOnly,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> _prefsToMap(NotificationPreferences p) => {
        'pushEnabled': p.pushEnabled,
        'emailEnabled': p.emailEnabled,
        'smsEnabled': p.smsEnabled,
        'reminderBeforeStart': p.reminderBeforeStart,
        'reminderBeforeExpiry': p.reminderBeforeExpiry,
        'waitlistUpdates': p.waitlistUpdates,
        'remindersEnabled': p.remindersEnabled,
        'loanReminders': p.loanReminders,
      };

  NotificationPreferences? _prefsFromMap(Object? raw) {
    if (raw is! Map) return null;
    bool b(String k) => raw[k] is bool ? raw[k] as bool : true;
    return NotificationPreferences(
      pushEnabled: b('pushEnabled'),
      emailEnabled: b('emailEnabled'),
      smsEnabled: b('smsEnabled'),
      reminderBeforeStart: b('reminderBeforeStart'),
      reminderBeforeExpiry: b('reminderBeforeExpiry'),
      waitlistUpdates: b('waitlistUpdates'),
      remindersEnabled: b('remindersEnabled'),
      loanReminders: b('loanReminders'),
    );
  }

  UserProfile _profileFromMap(Map<String, dynamic> m, String id) =>
      UserProfile(
        name: m['name'] as String? ?? 'Library Member',
        studentId: m['studentId'] as String? ?? id,
        email: m['email'] as String? ?? '',
        role: UserRole.student,
        uid: id,
        prefs: _prefsFromMap(m['notificationPrefs']),
        reservationsVisibleToStaffOnly:
            m['reservationsVisibleToStaffOnly'] as bool? ?? true,
      );

  /// Server-only end states (`expired`, `noShow`) show as cancelled: the
  /// UI enum has no separate value for them.
  ReservationStatus _resStatus(Object? raw, ReservationStatus fallback) {
    if (raw == 'expired' || raw == 'noShow') return ReservationStatus.cancelled;
    return _enum(ReservationStatus.values, raw, fallback);
  }

  T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.firstWhere(
        (v) => v.name == name,
        orElse: () => fallback,
      );
}
