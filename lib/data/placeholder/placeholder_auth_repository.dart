import 'dart:async';

import '../../auth/demo_credentials.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import 'in_memory_store.dart';

/// Local email/password auth for tests or running without Firebase.
class PlaceholderAuthRepository implements AuthRepository {
  PlaceholderAuthRepository() {
    InMemoryStore.instance.ensureInitialized();
    _controller.add(null);
  }

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  /// Session registrations (lost when app restarts).
  final Map<String, String> _registered = {};

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchAuthState() => _controller.stream;

  @override
  Future<AppUser> signInPlaceholder() async {
    _user = AppUser(uid: InMemoryStore.demoUid, email: 'demo@wicketwars.local');
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || password.isEmpty) {
      throw Exception('Enter email and password.');
    }
    final registered = _registered[e];
    if (registered != null && registered == password) {
      _user = AppUser(uid: _localUid(e), email: e);
      _controller.add(_user);
      return _user!;
    }
    if (e == kDemoEmail.toLowerCase() && password == kDemoPassword) {
      _user = AppUser(uid: InMemoryStore.demoUid, email: e);
      _controller.add(_user);
      return _user!;
    }
    throw Exception('Invalid email or password.');
  }

  @override
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) throw Exception('Enter an email.');
    if (password.isEmpty) throw Exception('Enter a password.');
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    if (e == kDemoEmail.toLowerCase()) {
      throw Exception('That email is reserved. Pick a different one.');
    }
    if (_registered.containsKey(e)) {
      throw Exception('An account with this email already exists.');
    }
    _registered[e] = password;
    _user = AppUser(uid: _localUid(e), email: e);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  static String _localUid(String email) => 'local_${email.hashCode}';
}
