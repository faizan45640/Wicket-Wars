/// Economy tier for a squad card (`users/{uid}/players` or `players_catalog`).
///
/// Only [free] custom cards can use timed training and coin upgrades in the app.
enum PlayerTier {
  free,
  premium;

  String get firestoreValue => name;

  /// [isRealPlayer] selects a sensible default when the field is missing on old docs.
  static PlayerTier fromFirestore(dynamic raw, {required bool isRealPlayer}) {
    if (raw == null) {
      return isRealPlayer ? PlayerTier.premium : PlayerTier.free;
    }
    final s = raw.toString().toLowerCase();
    if (s == 'premium') return PlayerTier.premium;
    return PlayerTier.free;
  }
}
