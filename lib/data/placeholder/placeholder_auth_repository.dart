import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  /// Local registrations for desktop/dev fallback when Firebase is unavailable.
  final Map<String, String> _registered = {};
  var _loadedRegisteredUsers = false;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchAuthState() async* {
    yield _user;
    yield* _controller.stream;
  }

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
    await _loadRegisteredUsers();
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
    String? displayName,
  }) async {
    await _loadRegisteredUsers();
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
    await _saveRegisteredUsers();
    _user = AppUser(uid: _localUid(e), email: e);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _loadRegisteredUsers();
    final e = email.trim().toLowerCase();
    if (e.isEmpty) throw Exception('Enter your email.');
    if (e == kDemoEmail.toLowerCase() || _registered.containsKey(e)) return;
    throw Exception('No account found for that email.');
  }

  @override
  Future<void> updateDisplayName(String displayName) async {}

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  static String _localUid(String email) {
    final encoded = base64Url.encode(utf8.encode(email)).replaceAll('=', '');
    return 'local_$encoded';
  }

  Future<File> get _registeredUsersFile async {
    final configuredDir = Platform.environment['WICKET_WARS_LOCAL_AUTH_DIR'];
    final home = Platform.environment['HOME'];
    final dirPath =
        configuredDir?.trim().isNotEmpty == true
            ? configuredDir!.trim()
            : home?.trim().isNotEmpty == true
            ? '${home!.trim()}/.wicket_wars'
            : '${Directory.systemTemp.path}/wicket_wars';
    final dir = Directory(dirPath);
    await dir.create(recursive: true);
    return File('${dir.path}/local_auth_users.json');
  }

  Future<void> _loadRegisteredUsers() async {
    if (_loadedRegisteredUsers) return;
    _loadedRegisteredUsers = true;
    try {
      final file = await _registeredUsersFile;
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      _registered
        ..clear()
        ..addAll(
          decoded.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
        );
    } catch (_) {
      // Local auth persistence is best-effort; the in-memory session still works.
    }
  }

  Future<void> _saveRegisteredUsers() async {
    try {
      final file = await _registeredUsersFile;
      await file.writeAsString(jsonEncode(_registered));
    } catch (_) {
      // Keep signup usable even when the local filesystem is read-only.
    }
  }
}
