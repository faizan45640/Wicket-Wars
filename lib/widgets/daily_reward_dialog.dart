import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/user_profile.dart';
import '../data/providers.dart';
import '../data/streak_player_reward.dart';
import '../theme/game_colors.dart';

const List<int> kCoinRewardByDay = [50, 75, 100, 150, 200, 300, 500];

final NumberFormat _coinFmt = NumberFormat.decimalPattern('en_US');

int _rewardForStreak(int streakDays) {
  if (streakDays <= 0) return kCoinRewardByDay[0];
  final idx = (streakDays - 1).clamp(0, kCoinRewardByDay.length - 1);
  return kCoinRewardByDay[idx];
}

int _nextStreakAfterClaim(UserProfile p) {
  final last = p.lastDailyRewardClaimAt;
  final t = DateTime.now();
  final today = DateTime(t.year, t.month, t.day);
  if (last == null) return 1;
  final lastDay = DateTime(last.year, last.month, last.day);
  if (lastDay == today) return p.dailyStreak;
  final yesterday = today.subtract(const Duration(days: 1));
  if (lastDay == yesterday) return p.dailyStreak + 1;
  return 1;
}

bool _canClaim(UserProfile p) {
  final last = p.lastDailyRewardClaimAt;
  if (last == null) return true;
  final t = DateTime.now();
  final today = DateTime(t.year, t.month, t.day);
  final lastDay = DateTime(last.year, last.month, last.day);
  return today.isAfter(lastDay);
}

Future<void> showDailyRewardDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (BuildContext ctx) {
      return Consumer(
        builder: (context, ref2, _) {
          final profileAsync = ref2.watch(userProfileProvider);
          return profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Dialog(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $e'),
              ),
            ),
            data: (p) {
              if (p == null) {
                return const Dialog(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Sign in to claim rewards.'),
                  ),
                );
              }
              final canClaim = _canClaim(p);
              final displayStreak = canClaim ? _nextStreakAfterClaim(p) : p.dailyStreak;
              final todayReward = _rewardForStreak(canClaim ? displayStreak : p.dailyStreak);
              return Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.78,
                  ),
                  child: Material(
                    color: GameColors.card,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        _dialogHeader(ctx),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _streakSummary(displayStreak, canClaim),
                                const SizedBox(height: 18),
                                const Text(
                                  'DAILY COINS (7-DAY LADDER)',
                                  style: TextStyle(
                                    color: GameColors.muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...List.generate(7, (i) {
                                  final day = i + 1;
                                  final coins = kCoinRewardByDay[i];
                                  final done = day < displayStreak || (!canClaim && day <= p.dailyStreak);
                                  final isToday = day == displayStreak && canClaim;
                                  return _dayRow(
                                    day: day,
                                    coins: coins,
                                    done: done,
                                    highlight: isToday,
                                  );
                                }),
                                const SizedBox(height: 8),
                                Text(
                                  canClaim
                                      ? "Today's reward: ${_coinFmt.format(todayReward)} coins"
                                      : 'Already claimed today. Come back tomorrow.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: GameColors.neon.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        _claimBar(ctx, context, ref2, p, canClaim),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _dialogHeader(BuildContext ctx) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      border: Border(
        bottom: BorderSide(color: GameColors.cardBorder),
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.card_giftcard, color: GameColors.neon, size: 26),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'DAILY REWARD',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.4,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(ctx).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
        ),
      ],
    ),
  );
}

Widget _streakSummary(int streak, bool canClaim) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF0F1A0F),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: GameColors.neon.withValues(alpha: 0.45)),
    ),
    child: Row(
      children: [
        const Text('🔥', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LOGIN STREAK',
                style: TextStyle(
                  color: GameColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$streak day streak${canClaim ? '' : ' (locked in)'}',
                style: const TextStyle(
                  color: GameColors.neon,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Every $kStreakPlayerBonusInterval days you also get a bonus trainable player (or coins if your squad has 15+).',
                style: TextStyle(
                  color: GameColors.neon.withValues(alpha: 0.85),
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Stored in your Firestore profile.',
                style: TextStyle(
                  color: GameColors.muted.withValues(alpha: 0.95),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _dayRow({
  required int day,
  required int coins,
  required bool done,
  required bool highlight,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: highlight
          ? GameColors.neon.withValues(alpha: 0.12)
          : const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.lock_outline,
              size: 20,
              color: done ? GameColors.neon : GameColors.muted,
            ),
            const SizedBox(width: 10),
            Text(
              'Day $day',
              style: const TextStyle(
                color: Color(0xFFEEEEEE),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              _coinFmt.format(coins),
              style: TextStyle(
                color: highlight ? GameColors.neon : const Color(0xFFDDDDDD),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            if (highlight) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GameColors.neon.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TODAY',
                  style: TextStyle(
                    color: GameColors.neon,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _claimBar(
  BuildContext dialogContext,
  BuildContext scaffoldContext,
  WidgetRef ref,
  UserProfile profile,
  bool canClaim,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      border: Border(top: BorderSide(color: GameColors.cardBorder)),
    ),
    child: FilledButton(
      onPressed: canClaim
          ? () async {
              final nextStreak = _nextStreakAfterClaim(profile);
              final reward = _rewardForStreak(nextStreak);
              var updated = profile.copyWith(
                coins: profile.coins + reward,
                lastDailyRewardClaimAt: DateTime.now(),
                dailyStreak: nextStreak,
              );
              await ref.read(userRepositoryProvider).upsertProfile(updated);

              final streakBonus = await applyStreakPlayerBonus(
                nextStreakAfterClaim: nextStreak,
                uid: profile.uid,
                loadSquad: ref.read(squadRepositoryProvider).getSquad,
                savePlayer: ref.read(squadRepositoryProvider).upsertPlayer,
                loadCatalog: () =>
                    ref.read(playersCatalogRepositoryProvider).watchCatalog().first,
              );
              if (streakBonus.extraCoins > 0) {
                updated = updated.copyWith(coins: updated.coins + streakBonus.extraCoins);
                await ref.read(userRepositoryProvider).upsertProfile(updated);
              }

              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (!scaffoldContext.mounted) return;
                final messenger = ScaffoldMessenger.of(scaffoldContext);
                messenger.clearSnackBars();

                var msg =
                    'Claimed ${_coinFmt.format(reward)} coins. Streak: $nextStreak days.';
                if (streakBonus.summaryLine.isNotEmpty) {
                  msg += ' ${streakBonus.summaryLine}';
                }
                if (streakBonus.extraCoins > 0) {
                  msg +=
                      ' +${_coinFmt.format(streakBonus.extraCoins)} coins (squad full).';
                }

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      msg,
                      style: const TextStyle(
                        color: Color(0xFFFAFAFA),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: const Color(0xFF383838),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    duration: const Duration(seconds: 5),
                    showCloseIcon: true,
                    closeIconColor: GameColors.neon,
                  ),
                );
              });
            }
          : null,
      style: FilledButton.styleFrom(
        backgroundColor: GameColors.neon,
        foregroundColor: GameColors.onNeonButton,
        disabledBackgroundColor: GameColors.muted.withValues(alpha: 0.3),
        disabledForegroundColor: GameColors.muted,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        canClaim ? 'CLAIM REWARD' : 'ALREADY CLAIMED TODAY',
        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3),
      ),
    ),
  );
}
