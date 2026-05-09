import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_codec.dart';
import '../firestore/firestore_refs.dart';
import '../models/leaderboard_entry.dart';
import 'leaderboard_repository.dart';

class FirebaseLeaderboardRepository implements LeaderboardRepository {
  FirebaseLeaderboardRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  List<LeaderboardEntry> _mapDocs(QuerySnapshot<Map<String, dynamic>> snap) {
    final rows = snap.docs.map((d) {
      final m = decodeFirestoreMap(d.data());
      m['uid'] = m['uid'] ?? d.id;
      return LeaderboardEntry.fromMap(m);
    }).toList();
    for (var i = 0; i < rows.length; i++) {
      rows[i] = LeaderboardEntry(
        uid: rows[i].uid,
        displayName: rows[i].displayName,
        rankingPoints: rows[i].rankingPoints,
        wins: rows[i].wins,
        rank: i + 1,
      );
    }
    return rows;
  }

  @override
  Stream<List<LeaderboardEntry>> watchTop({int limit = 50}) {
    return _db
        .leaderboardCollection()
        .orderBy('rankingPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map(_mapDocs);
  }

  @override
  Future<List<LeaderboardEntry>> getTop({int limit = 50}) async {
    final snap = await _db
        .leaderboardCollection()
        .orderBy('rankingPoints', descending: true)
        .limit(limit)
        .get();
    return _mapDocs(snap);
  }
}
