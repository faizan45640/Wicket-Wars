import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/daily_reward.dart';
import '../data/models/user_profile.dart';
import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/daily_reward_dialog.dart';
import '../widgets/game_bottom_nav.dart';
import '../widgets/monetization_banner.dart';
import '../widgets/training_player_picker.dart';

/// Dark cricket dashboard — matches Wicket Wars home mockup.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static final NumberFormat _coinFormat = NumberFormat.decimalPattern('en_US');

  static String _squadSubtitle(WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return 'Sign in';
    final squad = ref.watch(squadProvider(uid));
    return squad.maybeWhen(
      data:
          (s) =>
              s.isEmpty
                  ? '0 players · open squad to sync from Firestore'
                  : '${s.length} player(s)',
      loading: () => 'Loading squad…',
      orElse: () => '…',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    ref.listen(userProfileProvider, (previous, next) {
      final profile = next.valueOrNull;
      if (profile != null && !profile.starterPackOpened) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/starter-pack');
        });
      }
    });
    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'CRICKET SIM MASTER',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: GameColors.neon),
            tooltip: 'Profile',
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Card(
              color: GameColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: GameColors.cardBorder),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: _buildProfileSection(context, profileAsync),
              ),
            ),
            const SizedBox(height: 16),
            _buildPlayMatchButton(context),
            const SizedBox(height: 12),
            _buildMenuButton(
              icon: Icons.groups_outlined,
              title: 'MY SQUAD',
              subtitle: _squadSubtitle(ref),
              showChevron: true,
              onTap: () => context.go('/squad'),
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              icon: Icons.fitness_center,
              title: 'TRAINING',
              subtitle: 'Improve Skills',
              newBadge: true,
              onTap: () => showTrainingPlayerPicker(context, ref),
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              icon: Icons.emoji_events_outlined,
              title: 'LEADERBOARD',
              subtitle: profileAsync.maybeWhen(
                data:
                    (p) =>
                        '${_coinFormat.format(p?.rankingPoints ?? 0)} pts · tap to view global',
                orElse: () => 'Global standings',
              ),
              showChevron: true,
              onTap: () => context.go('/leaderboard'),
            ),
            const SizedBox(height: 12),
            _buildDailyRewardCard(context, ref),
            const SizedBox(height: 16),
            const Center(child: MonetizationBanner()),
          ],
        ),
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 0),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    AsyncValue<UserProfile?> profileAsync,
  ) {
    return profileAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GameColors.neon,
                ),
              ),
            ),
          ),
      error:
          (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Could not load profile: $e',
              style: TextStyle(color: Colors.red.shade200, fontSize: 13),
            ),
          ),
      data: (p) {
        final displayName = p?.displayName ?? 'Player';
        final coins = p?.coins ?? 0;
        final rankingPoints = p?.rankingPoints ?? 0;
        final initial =
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: GameColors.neon, width: 2),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: GameColors.card,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: GameColors.neon,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: GameColors.neon,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.amber.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'COINS: ${_coinFormat.format(coins)}',
                        style: TextStyle(
                          color: GameColors.muted.withValues(alpha: 0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.star_border_rounded,
                        color: GameColors.neon.withValues(alpha: 0.9),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RANKING POINTS: ${_coinFormat.format(rankingPoints)}',
                        style: TextStyle(
                          color: GameColors.muted.withValues(alpha: 0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayMatchButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.go('/matches'),
      style: ElevatedButton.styleFrom(
        backgroundColor: GameColors.neon,
        foregroundColor: GameColors.onNeonButton,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'START COMPETITION',
                  style: TextStyle(
                    color: GameColors.onNeonButton.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PLAY MATCH',
                  style: TextStyle(
                    color: GameColors.onNeonButton,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GameColors.onNeonButton,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_cricket,
              color: GameColors.neon,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showChevron = false,
    bool newBadge = false,
    VoidCallback? onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: GameColors.card,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: GameColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: GameColors.muted, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: GameColors.muted.withValues(alpha: 0.95),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (newBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else if (showChevron)
            Icon(
              Icons.chevron_right,
              color: GameColors.muted.withValues(alpha: 0.7),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyRewardCard(BuildContext context, WidgetRef ref) {
    final subtitle = ref
        .watch(userProfileProvider)
        .maybeWhen(
          data: (p) {
            if (p == null) return 'Sign in';
            if (canClaimDailyReward(p)) return 'Tap to claim coins';
            return 'Next reward tomorrow';
          },
          orElse: () => '…',
        );
    return DottedBorder(
      color: GameColors.neon,
      strokeWidth: 1.8,
      dashPattern: const [6, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: ElevatedButton(
          onPressed: () => showDailyRewardDialog(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: GameColors.card,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard, color: GameColors.neon, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DAILY REWARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: GameColors.neon,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: GameColors.neon,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
