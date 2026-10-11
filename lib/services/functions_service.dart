import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// A callable-function failure with a user-friendly [message].
class CallableFailure implements Exception {
  const CallableFailure(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Thin wrapper over the Cloud Functions callables the server exposes.
/// Names and payloads follow docs/BACKEND_CONTRACT.md.
class FunctionsService {
  FunctionsService._();
  static final FunctionsService instance = FunctionsService._();

  bool get isReady => Firebase.apps.isNotEmpty;

  FirebaseFunctions get _fn => FirebaseFunctions.instance;

  Future<Map<String, dynamic>> call(String name,
      [Map<String, dynamic>? data]) async {
    if (!isReady) {
      throw const CallableFailure('unavailable', 'Backend is not available.');
    }
    try {
      final res = await _fn.httpsCallable(name).call<dynamic>(data ?? {});
      final d = res.data;
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      throw CallableFailure(e.code, _friendly(e));
    }
  }

  String _friendly(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unavailable':
      case 'deadline-exceeded':
        return 'The server is unreachable. Check your connection.';
      case 'permission-denied':
        return 'You are not allowed to do that.';
      case 'unauthenticated':
        return 'Please sign in again.';
      case 'not-found':
        return 'That item no longer exists.';
      case 'failed-precondition':
      case 'resource-exhausted':
      case 'aborted':
        return e.message ?? 'That action is no longer possible.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  /// Returns the role granted to the caller: 'staff' or 'student'.
  Future<String?> claimRole() async =>
      (await call('claimRole'))['role'] as String?;

  Future<void> respondToWaitlistOffer(String entryId, bool accept) =>
      call('respondToWaitlistOffer', {'entryId': entryId, 'accept': accept});

  Future<Map<String, dynamic>> renewLoan(String loanId) =>
      call('renewLoan', {'loanId': loanId});

  Future<Map<String, dynamic>> checkoutBook(Map<String, dynamic> payload) =>
      call('checkoutBook', payload);

  Future<Map<String, dynamic>> checkinBook(Map<String, dynamic> payload) =>
      call('checkinBook', payload);

  Future<Map<String, dynamic>> verifyQrPass(String code) =>
      call('verifyQrPass', {'code': code});

  /// Ends a seat session. Without [uid] it is the caller's own booking;
  /// with another user's uid it is staff/admin only. Returns "ended" or
  /// "alreadyEnded".
  Future<String> endSeatSession(String bookingId, {String? uid}) async {
    final res = await call('endSeatSession', {
      'bookingId': bookingId,
      if (uid != null) 'uid': uid,
    });
    return (res['result'] as String?) ?? 'ended';
  }

  /// Admin only: replaces the staff allowlist with [emails].
  Future<Map<String, dynamic>> setStaffAllowlist(List<String> emails) =>
      call('setStaffAllowlist', {'emails': emails});

  /// Admin only: the allowlist with sign-up status per email.
  Future<List<Map<String, dynamic>>> listStaff() async {
    final res = await call('listStaff');
    final raw = res['staff'];
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  Future<void> deleteAccountData() => call('deleteAccountData');

  Future<Map<String, dynamic>> exportAccountData() =>
      call('exportAccountData');
}
