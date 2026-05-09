import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_codec.dart';
import '../firestore/firestore_refs.dart';
import '../models/cricket_player.dart';
import 'squad_repository.dart';

class FirebaseSquadRepository implements SquadRepository {
  FirebaseSquadRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CricketPlayer _playerFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final decoded = decodeFirestoreMap(doc.data());
    decoded['id'] = decoded['id'] ?? doc.id;
    return CricketPlayer.fromMap(decoded);
  }

  @override
  Stream<List<CricketPlayer>> watchSquad(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    return _db.userPlayers(uid).snapshots().map(
          (snap) => snap.docs.map(_playerFromDoc).toList(),
        );
  }

  @override
  Future<List<CricketPlayer>> getSquad(String uid) async {
    if (uid.isEmpty) return const [];
    final snap = await _db.userPlayers(uid).get();
    return snap.docs.map(_playerFromDoc).toList();
  }

  @override
  Future<void> upsertPlayer(String uid, CricketPlayer player) async {
    await _db
        .userPlayers(uid)
        .doc(player.id)
        .set(player.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deletePlayer(String uid, String playerId) async {
    await _db.userPlayers(uid).doc(playerId).delete();
  }
}
