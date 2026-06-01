import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wicket_wars/auth/auth_messages.dart';
import 'package:wicket_wars/auth/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('validates email consistently', () {
      expect(AuthValidators.email('player@example.com'), isNull);
      expect(AuthValidators.email(' player@example.com '), isNull);
      expect(AuthValidators.email('player'), 'Enter a valid email');
      expect(AuthValidators.email(''), 'Enter your email');
    });

    test('validates signup fields', () {
      expect(AuthValidators.displayName('Ali'), isNull);
      expect(AuthValidators.displayName('Al'), 'Use at least 3 characters');
      expect(AuthValidators.newPassword('123456'), isNull);
      expect(AuthValidators.newPassword('12345'), 'Use at least 6 characters');
    });
  });

  group('authErrorMessage', () {
    test('maps common Firebase auth errors', () {
      expect(
        authErrorMessage(FirebaseAuthException(code: 'invalid-credential')),
        'Invalid email or password.',
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'too-many-requests')),
        'Too many attempts. Please wait a moment and try again.',
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'network-request-failed')),
        'Network error. Check your connection and try again.',
      );
    });
  });
}
