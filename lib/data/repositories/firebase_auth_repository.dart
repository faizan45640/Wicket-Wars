import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/app_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  AppUser _mapUser(fb.User u) => AppUser(uid: u.uid, email: u.email);

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : _mapUser(u);
  }

  @override
  Stream<AppUser?> watchAuthState() {
    return _auth.authStateChanges().map((u) => u == null ? null : _mapUser(u));
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
    return _mapUser(u);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
