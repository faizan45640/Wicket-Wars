import '../models/leaderboard_entry.dart';

/// `leaderboard` collection — ordering done with queries in real impl.
abstract class LeaderboardRepository {
  Stream<List<LeaderboardEntry>> watchTop({int limit = 50});
  Future<List<LeaderboardEntry>> getTop({int limit = 50});
}
