import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this project.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'missing-email':
        return 'Enter your email address.';
      case 'requires-recent-login':
        return 'Please log in again before changing this account.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
  if (error is Exception) {
    final s = error.toString();
    if (s.startsWith('Exception: ')) {
      return s.substring(11);
    }
    return s;
  }
  return 'Something went wrong.';
}
