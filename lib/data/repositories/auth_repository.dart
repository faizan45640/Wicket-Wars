import '../models/app_user.dart';

/// Authentication — Firebase-backed via [FirebaseAuthRepository] in production.
abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();
  AppUser? get currentUser;

  /// Legacy hook for local/demo tooling; Firebase build may throw [UnsupportedError].
  Future<AppUser> signInPlaceholder();

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
