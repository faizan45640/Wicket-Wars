import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/cricket_player.dart';
import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

const Color _squadNameColor = Color(0xFFEEEEEE);
const Color _squadSubColor = Color(0xFFC8C8C8);

/// My Squad — text-only cards (name, OVR, type, stat bars), no photos.
class SquadScreen extends ConsumerWidget {
  const SquadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    final squadAsync = uid != null ? ref.watch(squadProvider(uid)) : null;

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
      body: uid == null
          ? const Center(
              child: Text('Sign in to view your squad.', style: TextStyle(color: Colors.white70)),
            )
          : Column(
              children: [
                Expanded(
                  child: squadAsync!.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: GameColors.neon),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load squad: $e',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade200),
                        ),
                      ),
                    ),
                    data: (squad) {
                      if (squad.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No players in Firestore yet.\n'
                              'They will appear here when you add cards (or seed data in the console).',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: GameColors.muted.withValues(alpha: 0.95),
                                height: 1.4,
                              ),
                            ),
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: squad.length,
                        itemBuilder: (context, index) {
                          final p = squad[index];
                          return _SquadPlayerTile(
                            player: p,
                            onTap: () => context.push('/player/${p.id}', extra: p),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pick 11 players — coming in match lobby'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                      foregroundColor: _squadNameColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, color: GameColors.neon, size: 22),
                    label: const Text(
                      'Select Playing XI',
                      style: TextStyle(
                        color: _squadNameColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.3,
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
