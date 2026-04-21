import '../models/app_user.dart';

/// Firebase Auth — placeholder returns a fixed local user until configured.
abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();
  AppUser? get currentUser;
  Future<AppUser> signInPlaceholder();
  Future<void> signOut();
}
