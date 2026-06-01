import '../models/cricket_player.dart';
import '../models/starter_pack_opening.dart';

/// `users/{uid}/players/*` subcollection.
abstract class SquadRepository {
  Stream<List<CricketPlayer>> watchSquad(String uid);
  Future<List<CricketPlayer>> getSquad(String uid);
  Future<CricketPlayer> generatePlayer({required String uid, String? prompt});
  Future<StarterPackOpening> openStarterPack({required String uid});
  Future<void> upsertPlayer(String uid, CricketPlayer player);
  Future<void> deletePlayer(String uid, String playerId);
}
