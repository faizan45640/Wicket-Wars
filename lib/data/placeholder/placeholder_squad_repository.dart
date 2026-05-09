import '../models/cricket_player.dart';
import '../repositories/squad_repository.dart';
import 'in_memory_store.dart';

class PlaceholderSquadRepository implements SquadRepository {
  final InMemoryStore _store = InMemoryStore.instance;

  PlaceholderSquadRepository() {
    _store.ensureInitialized();
  }

  @override
  Future<List<CricketPlayer>> getSquad(String uid) async {
    if (uid.isEmpty) return [];
    return _store.demoPlayersById.values.toList();
  }

  @override
  Future<void> upsertPlayer(String uid, CricketPlayer player) async {
    if (uid.isEmpty) return;
    if (uid != InMemoryStore.demoUid) return;
    _store.demoPlayersById[player.id] = player;
  }

  @override
  Future<void> deletePlayer(String uid, String playerId) async {
    if (uid != InMemoryStore.demoUid) return;
    _store.demoPlayersById.remove(playerId);
  }

  @override
  Stream<List<CricketPlayer>> watchSquad(String uid) async* {
    yield await getSquad(uid);
  }
}
