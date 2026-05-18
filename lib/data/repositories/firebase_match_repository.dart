import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_codec.dart';
import '../firestore/firestore_refs.dart';
import '../models/match_room.dart';
import '../models/pitch_condition.dart';
import 'match_repository.dart';

class FirebaseMatchRepository implements MatchRepository {
  FirebaseMatchRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Random _random = Random();

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join().toUpperCase();
  }

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
  Future<MatchRoom> createRoom({required String hostUid}) async {
    for (var i = 0; i < 12; i++) {
      final code = _generateRoomCode();
      final ref = _db.matchRoomDocument(code);
      final existing = await ref.get();
      if (existing.exists) continue;
      final room = MatchRoom(
        roomId: code,
        roomCode: code,
        status: MatchRoomStatus.waitingGuest,
        pitch: PitchCondition.balanced,
        hostUid: hostUid,
      );
      await ref.set(room.toMap());
      return room;
    }
    throw StateError('Could not allocate a room code');
  }

  @override
  Future<void> joinRoom({required String roomCode, required String guestUid}) async {
    final id = roomCode.toUpperCase();
    await _db.matchRoomDocument(id).update({
      'guestUid': guestUid,
      'status': MatchRoomStatus.selectingXi.name,
    });
  }

  @override
  Future<void> saveRoom(MatchRoom room) async {
    await _db.matchRoomDocument(room.roomId).set(room.toMap(), SetOptions(merge: true));
  }

  @override
  Future<MatchRoom?> transactRoom(
    String roomId,
    MatchRoom? Function(MatchRoom current) update,
  ) async {
    if (roomId.isEmpty) return null;
    return _db.runTransaction<MatchRoom?>((transaction) async {
      final ref = _db.matchRoomDocument(roomId);
      final snap = await transaction.get(ref);
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final current = MatchRoom.fromMap(decodeFirestoreMap(data));
      final next = update(current);
      if (next == null) return null;
      transaction.set(ref, next.toMap(), SetOptions(merge: true));
      return next;
    });
  }
}
