import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_codec.dart';
import '../firestore/firestore_refs.dart';
import '../models/match_summary.dart';
import 'match_history_repository.dart';

class FirebaseMatchHistoryRepository implements MatchHistoryRepository {
  FirebaseMatchHistoryRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> append(String uid, MatchSummary summary) async {
    await _db
        .userMatchHistory(uid)
        .doc(summary.matchId)
        .set(summary.toMap());
  }

  @override
  Stream<List<MatchSummary>> watchRecent(String uid, {int limit = 20}) {
    if (uid.isEmpty) return Stream.value(const []);
    return _db
        .userMatchHistory(uid)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MatchSummary.fromMap(decodeFirestoreMap(d.data())))
            .toList());
  }
}
