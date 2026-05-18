import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_codec.dart';
import '../firestore/firestore_refs.dart';
import '../models/user_profile.dart';
import 'user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Set<String> _seedWriteStarted = {};

  UserProfile _defaultProfile(String uid) {
    return UserProfile(
      uid: uid,
      displayName: 'Player',
      coins: 500,
      rankingPoints: 0,
      leagueTier: 'ROOKIE LEAGUE',
      wins: 0,
      losses: 0,
      matchesPlayed: 0,
      createdAt: DateTime.now().toUtc(),
      dailyStreak: 0,
      totalRunsScored: 0,
    );
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _db.userDocument(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) {
        if (!_seedWriteStarted.contains(uid)) {
          _seedWriteStarted.add(uid);
          upsertProfile(_defaultProfile(uid)).then(
            (_) {},
            onError: (_, __) => _seedWriteStarted.remove(uid),
          );
        }
        return _defaultProfile(uid);
      }
      return UserProfile.fromMap(decodeFirestoreMap(data));
    });
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    if (uid.isEmpty) return null;
    final snap = await _db.userDocument(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return _defaultProfile(uid);
    return UserProfile.fromMap(decodeFirestoreMap(data));
  }

  @override
  Future<void> upsertProfile(UserProfile profile) async {
    await _db
        .userDocument(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));

    await _db
        .leaderboardCollection()
        .doc(profile.uid)
        .set({
          'uid': profile.uid,
          'displayName': profile.displayName,
          'rankingPoints': profile.rankingPoints,
          'wins': profile.wins,
        }, SetOptions(merge: true));
  }
}
