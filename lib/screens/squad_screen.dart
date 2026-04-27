import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/cricket_player.dart';
import '../data/placeholder/demo_squad.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

const Color _squadNameColor = Color(0xFFEEEEEE);
const Color _squadSubColor = Color(0xFFC8C8C8);

/// My Squad — text-only cards (name, OVR, type, stat bars), no photos.
class SquadScreen extends StatefulWidget {
  const SquadScreen({super.key});

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  late final List<CricketPlayer> _squad;

  @override
  void initState() {
    super.initState();
    _squad = buildDemoSquad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GameColors.neon, size: 20),
          onPressed: () => context.go('/'),
        ),
        centerTitle: true,
        title: const Text(
          'My Squad',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: _squad.length,
              itemBuilder: (context, index) {
                final p = _squad[index];
                return _SquadPlayerTile(
                  player: p,
                  onTap: () => context.push('/player/${p.id}', extra: p),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Material(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pick 11 players — coming in match lobby'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Playing XI',
                        style: TextStyle(
                          color: _squadNameColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check_circle_outline, color: GameColors.neon, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 1),
    );
  }
}

class _SquadPlayerTile extends StatelessWidget {
  const _SquadPlayerTile({
    required this.player,
    required this.onTap,
  });

  final CricketPlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = player.attributes;
    final ovr = a.overall;
    final batP = a.batting / 100.0;
    final bwlP = a.bowling / 100.0;

    return Material(
      color: GameColors.card,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black54,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GameColors.cardBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      player.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _squadNameColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$ovr',
                    style: const TextStyle(
                      color: GameColors.neon,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  player.isRealPlayer ? 'REAL' : 'CUSTOM',
                  style: TextStyle(
                    color: _squadSubColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              _MiniBar(
                label: 'BAT',
                value: batP,
                color: const Color(0xFF64B5F6),
              ),
              const SizedBox(height: 6),
              _MiniBar(
                label: 'BWL',
                value: bwlP,
                color: GameColors.neon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: const TextStyle(
              color: _squadSubColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
