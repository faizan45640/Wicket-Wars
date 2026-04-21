import '../models/match_room.dart';

/// `matchRooms/{roomId}` — real-time listeners in real impl.
abstract class MatchRepository {
  Stream<MatchRoom?> watchRoom(String roomId);
  Future<MatchRoom?> getRoom(String roomId);
  Future<MatchRoom> createRoom({required String hostUid});
  Future<void> joinRoom({required String roomCode, required String guestUid});
  Future<void> saveRoom(MatchRoom room);
}
