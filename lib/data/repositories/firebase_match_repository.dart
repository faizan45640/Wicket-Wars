import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../firestore/firestore_codec.dart';
import '../firestore/firestore_refs.dart';
import '../models/match_room.dart';
import '../models/pitch_condition.dart';
import 'match_repository.dart';

class FirebaseMatchRepository implements MatchRepository {
  FirebaseMatchRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance,
      _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<MatchRoom?> watchRoom(String roomId) {
    if (roomId.isEmpty) return Stream.value(null);
    return _db.matchRoomDocument(roomId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return MatchRoom.fromMap(decodeFirestoreMap(data));
    });
  }

  @override
  Future<MatchRoom?> getRoom(String roomId) async {
    if (roomId.isEmpty) return null;
    final snap = await _db.matchRoomDocument(roomId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return MatchRoom.fromMap(decodeFirestoreMap(data));
  }

  @override
  Future<MatchRoom> createRoom({
    required String hostUid,
    int overs = 20,
    PitchCondition pitch = PitchCondition.balanced,
  }) async {
    final result = await _functions.httpsCallable('createMatchRoom').call({
      'overs': overs,
      'pitch': pitch.name,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final roomId = data['roomId'] as String;
    return MatchRoom(
      roomId: roomId,
      roomCode: data['roomCode'] as String? ?? roomId,
      status: MatchRoomStatus.waitingGuest,
      pitch: _pitchFromName(data['pitch'] as String?, pitch),
      oversPerInnings: (data['oversPerInnings'] as num?)?.round() ?? overs,
      hostUid: hostUid,
    );
  }

  PitchCondition _pitchFromName(String? name, PitchCondition fallback) {
    for (final v in PitchCondition.values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  @override
  Future<void> joinRoom({
    required String roomCode,
    required String guestUid,
  }) async {
    await _functions.httpsCallable('joinMatchRoom').call({
      'roomCode': roomCode,
    });
  }

  @override
  Future<void> lockStrongestXi({required String roomId}) async {
    await _functions.httpsCallable('lockStrongestXi').call({'roomId': roomId});
  }

  @override
  Future<void> lockPlayingXi({
    required String roomId,
    required List<String> playerIds,
  }) async {
    await _functions.httpsCallable('lockStrongestXi').call({
      'roomId': roomId,
      'playerIds': playerIds,
    });
  }

  @override
  Future<void> advanceDelivery({
    required String roomId,
    String? shot,
    String? bowl,
  }) async {
    await _functions.httpsCallable('advanceDelivery').call({
      'roomId': roomId,
      if (shot != null) 'shot': shot,
      if (bowl != null) 'bowl': bowl,
    });
  }

  @override
  Future<void> submitChoice({
    required String roomId,
    String? shot,
    String? bowl,
    bool force = false,
  }) async {
    await _functions.httpsCallable('submitMatchChoice').call({
      'roomId': roomId,
      if (shot != null) 'shot': shot,
      if (bowl != null) 'bowl': bowl,
      if (force) 'force': true,
    });
  }

  @override
  Future<void> forceComplete({required String roomId}) async {
    await _functions.httpsCallable('forceCompleteMatch').call({
      'roomId': roomId,
    });
  }

  @override
  Future<void> claimResult({required String roomId}) async {
    await _functions.httpsCallable('claimMatchResult').call({'roomId': roomId});
  }

  @override
  Future<void> saveRoom(MatchRoom room) async {
    throw UnsupportedError(
      'Match rooms are backend-authoritative in Firebase mode.',
    );
  }

  @override
  Future<MatchRoom?> transactRoom(
    String roomId,
    MatchRoom? Function(MatchRoom current) update,
  ) async {
    throw UnsupportedError(
      'Match rooms are backend-authoritative in Firebase mode.',
    );
  }
}
