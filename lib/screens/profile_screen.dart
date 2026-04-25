import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // --- UPDATED NEON PROFILE IMAGE ---
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.bg,
                  border: Border.all(color: neonGreen, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: neonGreen.withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
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

              // ----------------------------------
              const SizedBox(height: 16),
              // Player Name
              const Text(
                'Player One',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 32),
              // Stats Cards
              _buildStatCard(
                icon: Icons.sports_cricket_outlined,
                title: 'Total Matches',
                value: '342',
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.emoji_events_outlined,
                title: 'Wins',
                value: '198',
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.percent_outlined,
                title: 'Win Rate',
                value: '58%',
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.sports_baseball_outlined,
                title: 'Total Runs',
                value: '12,450',
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.star_border_rounded,
                title: 'Ranking Points',
                value: '1250',
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.monetization_on_outlined,
                title: 'Coins',
                value: '430',
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {
                  authController.signOut();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE57373),
                  side: const BorderSide(color: Color(0xFF4A2C2C)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 3),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
