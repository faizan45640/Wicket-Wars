import '../models/match_summary.dart';

/// `users/{uid}/matchHistory/*`
abstract class MatchHistoryRepository {
  Stream<List<MatchSummary>> watchRecent(String uid, {int limit = 20});
  Future<void> append(String uid, MatchSummary summary);
}
