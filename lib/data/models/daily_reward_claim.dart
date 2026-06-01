import 'user_profile.dart';

class DailyRewardClaim {
  const DailyRewardClaim({
    required this.claimed,
    required this.profile,
    required this.rewardCoins,
    required this.streakDay,
  });

  final bool claimed;
  final UserProfile profile;
  final int rewardCoins;
  final int streakDay;
}
