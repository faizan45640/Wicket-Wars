import 'package:flutter/foundation.dart';

import 'demo_credentials.dart';

/// Session gate for [app_router] redirect. Demo account + in-memory signups for this run.
class AuthController extends ChangeNotifier {
  bool _signedIn = false;
  String? _sessionEmail;

  /// Emails / passwords created via [register] in the current app session.
  final Map<String, String> _registered = {};

  bool get isSignedIn => _signedIn;
  String? get sessionEmail => _sessionEmail;

  bool signInWithPassword(String email, String password) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || password.isEmpty) return false;

    final registered = _registered[e];
    if (registered != null && registered == password) {
      _setSession(e);
      return true;
    }
    if (e == kDemoEmail.toLowerCase() && password == kDemoPassword) {
      _setSession(e);
      return true;
    }
    return false;
  }

  /// New account for this session only (not persisted to disk).
  /// Returns an error message, or `null` on success.
  String? register(String email, String password) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return 'Enter an email.';
    if (password.isEmpty) return 'Enter a password.';
    if (password.length < 4) return 'Password must be at least 4 characters.';
    if (e == kDemoEmail.toLowerCase()) {
      return 'That email is reserved. Use the demo or another address.';
    }
    if (_registered.containsKey(e)) {
      return 'An account with this email already exists.';
    }
    _registered[e] = password;
    notifyListeners();
    return null;
  }

  void _setSession(String email) {
    _signedIn = true;
    _sessionEmail = email;
    notifyListeners();
  }

  void signOut() {
    _signedIn = false;
    _sessionEmail = null;
    notifyListeners();
  }
}

/// Single instance for [GoRouter.refreshListenable].
final AuthController authController = AuthController();
