import 'models/user_profile.dart';

const List<int> kCoinRewardByDay = [50, 75, 100, 150, 200, 300, 500];

int rewardForStreak(int streakDays) {
  if (streakDays <= 0) return kCoinRewardByDay[0];
  final idx = (streakDays - 1).clamp(0, kCoinRewardByDay.length - 1);
  return kCoinRewardByDay[idx];
}

DateTime localDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

int nextStreakAfterClaim(UserProfile profile, {DateTime? now}) {
  final last = profile.lastDailyRewardClaimAt;
  final today = localDay(now ?? DateTime.now());
  if (last == null) return 1;
  final lastDay = localDay(last);
  if (lastDay == today) return profile.dailyStreak;
  final yesterday = today.subtract(const Duration(days: 1));
  if (lastDay == yesterday) return profile.dailyStreak + 1;
  return 1;
}

bool canClaimDailyReward(UserProfile profile, {DateTime? now}) {
  final last = profile.lastDailyRewardClaimAt;
  if (last == null) return true;
  return localDay(now ?? DateTime.now()).isAfter(localDay(last));
}
