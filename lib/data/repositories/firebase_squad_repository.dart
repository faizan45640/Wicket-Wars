import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../firestore/firestore_codec.dart';
import '../firestore/firestore_refs.dart';
import '../models/cricket_player.dart';
import '../models/starter_pack_opening.dart';
import 'squad_repository.dart';

class FirebaseSquadRepository implements SquadRepository {
  FirebaseSquadRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CricketPlayer _playerFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final decoded = decodeFirestoreMap(doc.data());
    decoded['id'] = decoded['id'] ?? doc.id;
    return CricketPlayer.fromMap(decoded);
  }

  @override
  Stream<List<CricketPlayer>> watchSquad(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    return _db
        .userPlayers(uid)
        .snapshots()
        .map((snap) => snap.docs.map(_playerFromDoc).toList());
  }

  @override
  Future<List<CricketPlayer>> getSquad(String uid) async {
    if (uid.isEmpty) return const [];
    final snap = await _db.userPlayers(uid).get();
    return snap.docs.map(_playerFromDoc).toList();
  }

  @override
  Future<CricketPlayer> generatePlayer({
    required String uid,
    String? prompt,
  }) async {
    final result = await _functions.httpsCallable('generatePlayer').call({
      'prompt': prompt?.trim() ?? '',
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final player = Map<String, dynamic>.from(data['player'] as Map);
    return CricketPlayer.fromMap(decodeFirestoreMap(player));
  }

  @override
  Future<StarterPackOpening> openStarterPack({required String uid}) async {
    final result = await _functions.httpsCallable('openStarterPack').call();
    final data = Map<String, dynamic>.from(result.data as Map);
    final players = List<dynamic>.from(data['players'] as List? ?? const []);
    return StarterPackOpening(
      players: [
        for (final raw in players)
          CricketPlayer.fromMap(
            decodeFirestoreMap(Map<String, dynamic>.from(raw as Map)),
          ),
      ],
      generationSource: data['generationSource'] as String? ?? 'unknown',
      alreadyOpened: data['alreadyOpened'] as bool? ?? false,
    );
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
