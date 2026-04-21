import '../models/match_summary.dart';
import '../repositories/match_history_repository.dart';
import 'in_memory_store.dart';

class PlaceholderMatchHistoryRepository implements MatchHistoryRepository {
  final InMemoryStore _store = InMemoryStore.instance;

  PlaceholderMatchHistoryRepository() {
    _store.ensureInitialized();
  }

  @override
  Future<void> append(String uid, MatchSummary summary) async {
    final list = _store.matchHistoryByUid.putIfAbsent(uid, () => []);
    list.insert(0, summary);
  }

  @override
  Stream<List<MatchSummary>> watchRecent(String uid, {int limit = 20}) async* {
    final list = _store.matchHistoryByUid[uid] ?? const [];
    yield list.take(limit).toList();
  }
}
