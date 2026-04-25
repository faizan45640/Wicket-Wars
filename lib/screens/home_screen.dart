import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

/// Dark cricket dashboard — matches Wicket Wars home mockup.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final NumberFormat _coinFormat = NumberFormat.decimalPattern('en_US');

  static const _displayName = 'Player123';
  static const _coins = 1500;
  static const _rankingPoints = 875;

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileSection(context),
              const SizedBox(height: 24),
              _buildPlayMatchButton(context),
              const SizedBox(height: 16),
              _buildMenuCard(
                icon: Icons.groups_outlined,
                title: 'MY SQUAD',
                subtitle: '11 Active Players',
                showChevron: true,
                onTap: () => context.go('/squad'),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.fitness_center,
                title: 'TRAINING',
                subtitle: 'Improve Skills',
                newBadge: true,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.emoji_events_outlined,
                title: 'LEADERBOARD',
                subtitle: 'Rank #4,210',
                showChevron: true,
                onTap: () => context.go('/leaderboard'),
              ),
              const SizedBox(height: 12),
              _buildDailyRewardCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 0),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final initial =
        _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';
    return Tooltip(
      message: 'Profile',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/profile'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
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
                      const Text(
                        _displayName,
                        style: TextStyle(
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
                            'COINS: ${_coinFormat.format(_coins)}',
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
                            'RANKING POINTS: ${_coinFormat.format(_rankingPoints)}',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayMatchButton(BuildContext context) {
    return Material(
      color: GameColors.neon,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: () => context.go('/online-match'),
        // ------------------------,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showChevron = false,
    bool newBadge = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: GameColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GameColors.cardBorder),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
        ),
      ),
    );
  }

  Widget _buildDailyRewardCard() {
    return DottedBorder(
      color: GameColors.neon,
      strokeWidth: 1.8,
      dashPattern: const [6, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: GameColors.card,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    color: GameColors.neon,
                    size: 28,
                  ),
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
                          'Available Now',
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
        ),
      ),
    );
  }
}
