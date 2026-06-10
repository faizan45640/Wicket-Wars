import '../models/match_room.dart';
import '../models/pitch_condition.dart';

/// `matchRooms/{roomId}` — real-time listeners in real impl.
abstract class MatchRepository {
  Stream<MatchRoom?> watchRoom(String roomId);
  Future<MatchRoom?> getRoom(String roomId);
  Future<MatchRoom> createRoom({
    required String hostUid,
    int overs = 20,
    PitchCondition pitch = PitchCondition.balanced,
  });
  Future<void> joinRoom({required String roomCode, required String guestUid});
  Future<void> lockStrongestXi({required String roomId});
  Future<void> lockPlayingXi({
    required String roomId,
    required List<String> playerIds,
  });
  Future<void> advanceDelivery({
    required String roomId,
    String? shot,
    String? bowl,
  });

  /// Two-sided handshake: lock this player's pick for the pending delivery.
  /// The ball resolves once both sides pick or [force] is set after the window.
  Future<void> submitChoice({
    required String roomId,
    String? shot,
    String? bowl,
    bool force = false,
  });
  Future<void> forceComplete({required String roomId});
  Future<void> claimResult({required String roomId});
  Future<void> saveRoom(MatchRoom room);

  /// Read–modify–write in one atomic step (Firestore transaction; sequential in placeholder).
  /// Return `null` from [update] to abort without writing.
  Future<MatchRoom?> transactRoom(
    String roomId,
    MatchRoom? Function(MatchRoom current) update,
  );
}
