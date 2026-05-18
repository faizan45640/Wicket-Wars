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
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield await getProfile(uid);
  }
}
