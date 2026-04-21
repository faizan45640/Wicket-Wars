/// Minimal auth user — swap for `firebase_auth.User` when wired.
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
  });

  final String uid;
  final String? email;
}
