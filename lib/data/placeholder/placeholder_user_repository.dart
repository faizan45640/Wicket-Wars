import '../daily_reward.dart';
import '../models/daily_reward_claim.dart';
import '../models/user_profile.dart';
import '../repositories/user_repository.dart';
import 'in_memory_store.dart';

class PlaceholderUserRepository implements UserRepository {
  final InMemoryStore _store = InMemoryStore.instance;

  PlaceholderUserRepository() {
    _store.ensureInitialized();
  }

  UserProfile _profileForUid(String uid) {
    if (uid == InMemoryStore.demoUid) return _store.demoProfile;
    final existing = _store.extraProfilesByUid[uid];
    if (existing != null) return existing;
    final base = _store.demoProfile;
    return UserProfile(
      uid: uid,
      displayName: base.displayName,
      email: base.email,
      coins: base.coins,
      rankingPoints: base.rankingPoints,
      leagueTier: base.leagueTier,
      wins: base.wins,
      losses: base.losses,
      matchesPlayed: base.matchesPlayed,
      lastDailyRewardClaimAt: base.lastDailyRewardClaimAt,
      createdAt: base.createdAt,
      dailyStreak: base.dailyStreak,
      totalRunsScored: base.totalRunsScored,
      starterPackOpened: base.starterPackOpened,
    );
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    if (uid.isEmpty) return null;
    return _profileForUid(uid);
  }

  @override
  Future<void> upsertProfile(UserProfile profile) async {
    if (profile.uid == InMemoryStore.demoUid) {
      _store.demoProfile = profile;
      return;
    }
    _store.extraProfilesByUid[profile.uid] = profile;
  }

  @override
  Future<DailyRewardClaim> claimDailyReward(String uid) async {
    final current = await getProfile(uid);
    if (current == null) {
      throw ArgumentError.value(uid, 'uid', 'User id is required.');
    }
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
    await upsertProfile(updated);
    return DailyRewardClaim(
      claimed: true,
      profile: updated,
      rewardCoins: rewardCoins,
      streakDay: streakDay,
    );
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield await getProfile(uid);
  }
}
