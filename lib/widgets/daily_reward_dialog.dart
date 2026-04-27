import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

import '../theme/game_colors.dart';

/// Hardcoded login streak + coin ladder (swap for Firestore / [UserProfile] later).
const int kDemoStreakDays = 4;
const List<int> kCoinRewardByDay = [50, 75, 100, 150, 200, 300, 500];

final NumberFormat _coinFmt = NumberFormat.decimalPattern('en_US');

/// Shows a modal with current streak, per-day coin rewards, and a claim action.
Future<void> showDailyRewardDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (BuildContext ctx) {
      // Keep [context] (caller, e.g. Home) for [SnackBar] after [pop] — dialog [ctx] unmounts.
      // Explicit width + Material so the dialog always paints (no invisible surface).
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
            // [Column] + [Expanded] only works with a **bounded** max height from
            // [ConstrainedBox] (not [mainAxisSize: min] + [Flexible] — that often breaks layout).
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
                        _streakSummary(),
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
                          final done = day <= kDemoStreakDays;
                          final isToday = day == kDemoStreakDays;
                          return _dayRow(
                            day: day,
                            coins: coins,
                            done: done,
                            highlight: isToday,
                          );
                        }),
                        const SizedBox(height: 8),
                        Text(
                          "Today's reward: ${_coinFmt.format(kCoinRewardByDay[kDemoStreakDays - 1])} coins",
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
                _claimBar(ctx, context),
              ],
            ),
          ),
        ),
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

Widget _streakSummary() {
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
                '$kDemoStreakDays day streak',
                style: const TextStyle(
                  color: GameColors.neon,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Come back each day to climb the ladder and earn more.',
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

Widget _claimBar(BuildContext dialogContext, BuildContext scaffoldContext) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      border: Border(top: BorderSide(color: GameColors.cardBorder)),
    ),
    child: FilledButton(
      onPressed: () {
        final claimed = kCoinRewardByDay[kDemoStreakDays - 1];
        final message =
            'Claimed ${_coinFmt.format(claimed)} coins! (demo)';
        // Close the route first, then show feedback on the *next* frame. Showing a
        // [SnackBar] in the same synchronous block as [pop] is often dropped because
        // the overlay / [ScaffoldMessenger] is still updating.
        Navigator.of(dialogContext).pop();
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!scaffoldContext.mounted) return;
          final messenger = ScaffoldMessenger.of(scaffoldContext);
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFFAFAFA),
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFF383838),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              duration: const Duration(seconds: 4),
              showCloseIcon: true,
              closeIconColor: GameColors.neon,
            ),
          );
        });
      },
      style: FilledButton.styleFrom(
        backgroundColor: GameColors.neon,
        foregroundColor: GameColors.onNeonButton,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'CLAIM REWARD',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3),
      ),
    ),
  );
}
