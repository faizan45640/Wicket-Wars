import '../models/daily_reward_claim.dart';
import '../models/user_profile.dart';

/// `users/{uid}` profile document.
abstract class UserRepository {
  Stream<UserProfile?> watchProfile(String uid);
  Future<UserProfile?> getProfile(String uid);
  Future<void> upsertProfile(UserProfile profile);
  Future<DailyRewardClaim> claimDailyReward(String uid);
}
