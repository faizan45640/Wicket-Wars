/// Minimal auth user — swap for `firebase_auth.User` when wired.
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  final String uid;
  final String? email;

  /// Firebase Auth display name (set at sign-up); used to repair the
  /// Firestore profile/leaderboard name if it ever gets reset.
  final String? displayName;
}
