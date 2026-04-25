import 'package:flutter/material.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              // Profile Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.card,
                  border: Border.all(color: GameColors.cardBorder, width: 2),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 60,
                  color: GameColors.muted,
                ),
              ),
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