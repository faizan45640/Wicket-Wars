import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Defining the neon color here for easy access,
    // you can also move this to your GameColors class.
    const Color neonGreen = Color(0xFF00FF00);

    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: neonGreen, size: 32),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: GameColors.bg,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: neonGreen, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: neonGreen.withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: GameColors.bg,
                  child: Text(
                    'P',
                    style: TextStyle(
                      color: neonGreen,
                      fontSize: 44,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(color: neonGreen, blurRadius: 10)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Player One',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: GameColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: GameColors.cardBorder),
            ),
            elevation: 0,
            child: Column(
              children: [
                _buildStatTile(icon: Icons.sports_cricket_outlined, title: 'Total Matches', value: '342'),
                _buildStatTile(icon: Icons.emoji_events_outlined, title: 'Wins', value: '198'),
                _buildStatTile(icon: Icons.percent_outlined, title: 'Win Rate', value: '58%'),
                _buildStatTile(icon: Icons.sports_baseball_outlined, title: 'Total Runs', value: '12,450'),
                _buildStatTile(icon: Icons.star_border_rounded, title: 'Ranking Points', value: '1250'),
                _buildStatTile(icon: Icons.monetization_on_outlined, title: 'Coins', value: '430', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE57373),
              side: const BorderSide(color: Color(0xFF4A2C2C)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 3),
    );
  }

  static Widget _buildStatTile({
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white, size: 28),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: GameColors.cardBorder.withValues(alpha: 0.5),
              indent: 16, endIndent: 16),
      ],
    );
  }
}
