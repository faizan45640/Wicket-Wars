/// Canonical Firestore paths for Wicket Wars (see wicket_wars_docs.md).
///
/// After `flutterfire configure`, implement repositories with
/// `FirebaseFirestore.instance.doc(...)` using these segments.
abstract final class FirestorePaths {
  static const String users = 'users';

  /// Profile, coins, ranking, daily reward timestamps, etc.
  static String userDocument(String uid) => '$users/$uid';

  /// One document per player card (max 15 per user in app logic).
  static String userPlayersCollection(String uid) => '${userDocument(uid)}/players';

  static String userPlayerDocument(String uid, String playerId) =>
      '${userPlayersCollection(uid)}/$playerId';

  /// Live / recent 1v1 rooms. [roomId] can equal the 6-char room code.
  static const String matchRooms = 'matchRooms';

  static String matchRoomDocument(String roomId) => '$matchRooms/$roomId';

  /// Completed match records for history & profile.
  static String userMatchHistoryCollection(String uid) =>
      '${userDocument(uid)}/matchHistory';

  static String userMatchHistoryDocument(String uid, String matchId) =>
      '${userMatchHistoryCollection(uid)}/$matchId';

  /// Leaderboard snapshots (e.g. denormalized top N) or per-user leaderboard docs.
  static const String leaderboard = 'leaderboard';

  static String leaderboardEntryDocument(String uid) => '$leaderboard/$uid';

  /// Read-only catalog of premium / licensed templates (seed in Console or admin tools).
  static const String playersCatalog = 'players_catalog';

  static String playersCatalogDocument(String catalogId) => '$playersCatalog/$catalogId';
}
