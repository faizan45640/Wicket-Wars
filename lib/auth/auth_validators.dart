final class AuthValidators {
  AuthValidators._();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? displayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter a display name';
    if (name.length < 3) return 'Use at least 3 characters';
    if (name.length > 20) return 'Keep it under 20 characters';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Use at least 6 characters';
    }
    return null;
  }
}
