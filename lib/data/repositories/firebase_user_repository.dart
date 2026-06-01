import 'package:cloud_firestore/cloud_firestore.dart';

import '../daily_reward.dart';
import '../firestore/firestore_codec.dart';
import '../firestore/firestore_refs.dart';
import '../models/daily_reward_claim.dart';
import '../models/user_profile.dart';
import '../onboarding_seed.dart';
import 'user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Set<String> _seedWriteStarted = {};

  UserProfile _defaultProfile(String uid) {
    return starterProfile(uid: uid, displayName: 'Player');
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _db.userDocument(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) {
        if (!_seedWriteStarted.contains(uid)) {
          _seedWriteStarted.add(uid);
          upsertProfile(
            _defaultProfile(uid),
          ).then((_) {}, onError: (_, __) => _seedWriteStarted.remove(uid));
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

    await _db.leaderboardCollection().doc(profile.uid).set({
      'uid': profile.uid,
      'displayName': profile.displayName,
      'rankingPoints': profile.rankingPoints,
      'wins': profile.wins,
    }, SetOptions(merge: true));
  }

  @override
  Future<DailyRewardClaim> claimDailyReward(String uid) async {
    if (uid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'User id is required.');
    }

    final userRef = _db.userDocument(uid);
    final leaderboardRef = _db.leaderboardCollection().doc(uid);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data();
      final current =
          snap.exists && data != null
              ? UserProfile.fromMap(decodeFirestoreMap(data))
              : _defaultProfile(uid);

      if (!canClaimDailyReward(current)) {
        return DailyRewardClaim(
          claimed: false,
          profile: current,
          rewardCoins: 0,
          streakDay: current.dailyStreak,
        );
      }

      final streakDay = nextStreakAfterClaim(current);
      final rewardCoins = rewardForStreak(streakDay);
      final updated = current.copyWith(
        coins: current.coins + rewardCoins,
        lastDailyRewardClaimAt: DateTime.now().toUtc(),
        dailyStreak: streakDay,
      );

      tx.set(userRef, updated.toMap(), SetOptions(merge: true));
      tx.set(leaderboardRef, {
        'uid': updated.uid,
        'displayName': updated.displayName,
        'rankingPoints': updated.rankingPoints,
        'wins': updated.wins,
      }, SetOptions(merge: true));

      return DailyRewardClaim(
        claimed: true,
        profile: updated,
        rewardCoins: rewardCoins,
        streakDay: streakDay,
      );
    });
  }
}
