import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

class OnlineMatchScreen extends StatelessWidget {
  const OnlineMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: GameColors.neon,
            size: 32, // Increased size slightly to match the bold look
          ),
          // onPressed: () => context.pop(),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'ONLINE MATCH LOBBY',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Room Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GameColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GameColors.neon, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'ROOM CODE: cricket123',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Player 1 Card
              _buildPlayerCard(
                initial: 'A',
                playerName: 'Player_1',
                status: 'Ready',
                isReady: true,
              ),
              const SizedBox(height: 16),

              // Player 2 Card
              _buildPlayerCard(
                initial: 'B',
                playerName: 'Player_2',
                status: 'Waiting...',
                isReady: false,
              ),

              const Spacer(),

              // Start Match Button
              Material(
                color: GameColors.neon,
                borderRadius: BorderRadius.circular(18),
                elevation: 0,
                child: InkWell(
                  onTap: () => context.push('/match/live'),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: const Center(
                      child: Text(
                        'START MATCH',
                        style: TextStyle(
                          color: GameColors.onNeonButton,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => context.push('/match/live'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'To live match (demo)',
                        style: TextStyle(
                          color: GameColors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: GameColors.neon, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 2),
    );
  }

  Widget _buildPlayerCard({
    required String initial,
    required String playerName,
    required String status,
    required bool isReady,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameColors.cardBorder, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameColors.bg,
              border: Border.all(color: GameColors.neon, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: GameColors.neon,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'STATUS: ',
                    style: TextStyle(
                      color: GameColors.muted,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: isReady ? GameColors.neon : Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
