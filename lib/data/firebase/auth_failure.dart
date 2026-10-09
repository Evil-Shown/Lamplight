import 'package:firebase_auth/firebase_auth.dart';

/// A sign-in / sign-up failure with a stable [code] and a message that is
/// safe to show to the user. `toString()` returns the message, so screens
/// that print the caught error keep working.
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  /// e.g. `wrong-password`, `network`, `not-enabled`, `cancelled`,
  /// `not-configured`, `too-many-requests`, `unknown`.
  final String code;
  final String message;

  bool get isCancelled => code == 'cancelled';

  /// Maps a [FirebaseAuthException] to a typed failure.
  factory AuthFailure.fromAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return const AuthFailure(
            'wrong-password', 'Incorrect email or password.');
      case 'invalid-email':
        return const AuthFailure(
            'invalid-email', 'That email address is not valid.');
      case 'user-disabled':
        return const AuthFailure(
            'user-disabled', 'This account has been disabled.');
      case 'email-already-in-use':
        return const AuthFailure('email-in-use',
            'An account with this email already exists. Try signing in.');
      case 'weak-password':
        return const AuthFailure(
            'weak-password', 'Choose a stronger password (6+ characters).');
      case 'network-request-failed':
        return const AuthFailure('network',
            'No connection. Check your internet and try again.');
      case 'operation-not-allowed':
        return const AuthFailure('not-enabled',
            'This sign-in method is not enabled for the library yet.');
      case 'too-many-requests':
        return const AuthFailure('too-many-requests',
            'Too many attempts. Wait a moment and try again.');
      default:
        return AuthFailure(
            'unknown', e.message ?? 'Sign-in failed. Please try again.');
    }
  }

  @override
  String toString() => message;
}
