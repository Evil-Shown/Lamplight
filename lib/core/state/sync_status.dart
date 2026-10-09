import 'package:firebase_core/firebase_core.dart';

/// Where the data on screen comes from.
enum DataSource {
  /// Real Firestore documents.
  live,

  /// Bundled sample data (tests, or the explicit `DEMO_MODE` build flag).
  demo,

  /// Nothing loaded: signed out, or Firebase unavailable.
  none,
}

/// Health of the live data connection.
enum SyncStatus {
  /// Waiting for the first snapshot.
  syncing,

  /// Receiving fresh server data.
  live,

  /// Showing server data that has not refreshed for a while.
  stale,

  /// Showing cached data; the server is unreachable.
  offline,

  /// Nobody is signed in.
  signedOut,

  /// Firestore rejected a read (rules or role).
  permissionDenied,

  /// Any other failure; last good data is kept.
  error,
}

/// A classified stream/query failure.
class SyncError {
  const SyncError(this.status, this.message, [this.code]);

  /// The [SyncStatus] this failure maps to.
  final SyncStatus status;

  /// User-presentable summary.
  final String message;

  /// Raw Firebase error code, if any.
  final String? code;

  @override
  String toString() => message;
}

/// How long server data may go without a refresh before it is [SyncStatus.stale].
const Duration kStaleAfter = Duration(minutes: 5);

/// Maps a Firestore/Functions error onto a [SyncError].
SyncError classifyFirestoreError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return SyncError(
          SyncStatus.permissionDenied,
          'You do not have access to this data.',
          error.code,
        );
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return SyncError(
          SyncStatus.offline,
          'You appear to be offline. Showing saved data.',
          error.code,
        );
      default:
        return SyncError(
          SyncStatus.error,
          error.message ?? 'Something went wrong while syncing.',
          error.code,
        );
    }
  }
  return const SyncError(
      SyncStatus.error, 'Something went wrong while syncing.');
}

/// Derives the status shown to screens from raw facts. Pure, so it can be
/// unit tested without Firebase.
SyncStatus deriveSyncStatus({
  required bool signedIn,
  required bool hydrated,
  required SyncError? error,
  required bool allFromCache,
  required DateTime? lastSyncedAt,
  required DateTime now,
}) {
  if (!signedIn) return SyncStatus.signedOut;
  if (error != null &&
      (error.status == SyncStatus.permissionDenied ||
          error.status == SyncStatus.error)) {
    return error.status;
  }
  if (!hydrated) return SyncStatus.syncing;
  if (error?.status == SyncStatus.offline || allFromCache) {
    return SyncStatus.offline;
  }
  if (lastSyncedAt != null && now.difference(lastSyncedAt) > kStaleAfter) {
    return SyncStatus.stale;
  }
  return SyncStatus.live;
}
