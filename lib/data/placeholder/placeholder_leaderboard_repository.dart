import '../models/leaderboard_entry.dart';
import '../repositories/leaderboard_repository.dart';
import 'in_memory_store.dart';

class PlaceholderLeaderboardRepository implements LeaderboardRepository {
  final InMemoryStore _store = InMemoryStore.instance;

  PlaceholderLeaderboardRepository() {
    _store.ensureInitialized();
  }

  @override
  Future<List<LeaderboardEntry>> getTop({int limit = 50}) async {
    final list = List<LeaderboardEntry>.from(_store.demoLeaderboard);
    list.sort((a, b) => b.rankingPoints.compareTo(a.rankingPoints));
    if (list.length > limit) return list.sublist(0, limit);
    return list;
  }

  @override
  Stream<List<LeaderboardEntry>> watchTop({int limit = 50}) async* {
    yield await getTop(limit: limit);
  }
}
