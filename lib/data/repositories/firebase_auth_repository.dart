import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/app_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  AppUser _mapUser(fb.User u) =>
      AppUser(uid: u.uid, email: u.email, displayName: u.displayName);

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : _mapUser(u);
  }

  @override
  Stream<AppUser?> watchAuthState() async* {
    final current = _auth.currentUser;
    yield current == null ? null : _mapUser(current);
    yield* _auth.idTokenChanges().map((u) => u == null ? null : _mapUser(u));
  }

  @override
  Future<AppUser> signInPlaceholder() async {
    throw UnsupportedError(
      'Anonymous sign-in is not enabled. Use email/password sign-in.',
    );
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final u = cred.user;
    if (u == null) {
      throw fb.FirebaseAuthException(
        code: 'null-user',
        message: 'Sign-in succeeded but user is null.',
      );
    }
    return _mapUser(u);
  }

  @override
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final u = cred.user;
    if (u == null) {
      throw fb.FirebaseAuthException(
        code: 'null-user',
        message: 'Account created but user is null.',
      );
    }
    final trimmedName = displayName?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      await u.updateDisplayName(trimmedName);
      await u.reload();
    }
    return _mapUser(u);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName.trim());
    await user.reload();
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
