import '../models/match_room.dart';
import '../models/pitch_condition.dart';
import '../repositories/match_repository.dart';
import 'in_memory_store.dart';

class PlaceholderMatchRepository implements MatchRepository {
  final InMemoryStore _store = InMemoryStore.instance;

  PlaceholderMatchRepository() {
    _store.ensureInitialized();
  }

  @override
  Future<MatchRoom> createRoom({required String hostUid}) async {
    return _store.newRoom(hostUid: hostUid, pitch: PitchCondition.balanced);
  }

  @override
  Future<MatchRoom?> getRoom(String roomId) async => _store.roomsById[roomId];

  @override
  Future<void> joinRoom({required String roomCode, required String guestUid}) async {
    final room = _store.roomsById[roomCode.toUpperCase()];
    if (room == null) return;
    _store.roomsById[room.roomId] = MatchRoom(
      roomId: room.roomId,
      roomCode: room.roomCode,
      status: MatchRoomStatus.selectingXi,
      pitch: room.pitch,
      hostUid: room.hostUid,
      guestUid: guestUid,
    );
  }

  @override
  Future<void> saveRoom(MatchRoom room) async {
    _store.roomsById[room.roomId] = room;
  }

  @override
  Stream<MatchRoom?> watchRoom(String roomId) async* {
    yield _store.roomsById[roomId];
  }
}
