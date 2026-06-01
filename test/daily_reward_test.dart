import 'package:flutter_test/flutter_test.dart';
import 'package:wicket_wars/data/daily_reward.dart';
import 'package:wicket_wars/data/models/user_profile.dart';

void main() {
  UserProfile profile({DateTime? lastClaim, int streak = 0}) {
    return UserProfile(
      uid: 'u1',
      displayName: 'Player',
      coins: 0,
      rankingPoints: 0,
      leagueTier: 'ROOKIE LEAGUE',
      wins: 0,
      losses: 0,
      matchesPlayed: 0,
      lastDailyRewardClaimAt: lastClaim,
      dailyStreak: streak,
    );
  }

  test('daily reward can only be claimed once per local day', () {
    final now = DateTime(2026, 5, 31, 10);
    expect(canClaimDailyReward(profile(), now: now), isTrue);
    expect(canClaimDailyReward(profile(lastClaim: now), now: now), isFalse);
    expect(
      canClaimDailyReward(
        profile(lastClaim: DateTime(2026, 5, 30, 23)),
        now: now,
      ),
      isTrue,
    );
  });

  test('streak continues from yesterday and resets after a missed day', () {
    final now = DateTime(2026, 5, 31, 10);
    expect(
      nextStreakAfterClaim(
        profile(lastClaim: DateTime(2026, 5, 30, 8), streak: 3),
        now: now,
      ),
      4,
    );
    expect(
      nextStreakAfterClaim(
        profile(lastClaim: DateTime(2026, 5, 29, 8), streak: 3),
        now: now,
      ),
      1,
    );
  });

  test('coin ladder caps at final reward amount', () {
    expect(rewardForStreak(1), 50);
    expect(rewardForStreak(4), 150);
    expect(rewardForStreak(99), 500);
  });
}
