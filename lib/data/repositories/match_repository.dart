import '../models/match_room.dart';

/// `matchRooms/{roomId}` — real-time listeners in real impl.
abstract class MatchRepository {
  Stream<MatchRoom?> watchRoom(String roomId);
  Future<MatchRoom?> getRoom(String roomId);
  Future<MatchRoom> createRoom({required String hostUid});
  Future<void> joinRoom({required String roomCode, required String guestUid});
  Future<void> lockStrongestXi({required String roomId});
  Future<void> lockPlayingXi({
    required String roomId,
    required List<String> playerIds,
  });
  Future<void> advanceDelivery({required String roomId});
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
