import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/cricket_player.dart';
import '../data/models/player_tier.dart';
import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';
import '../widgets/monetization_banner.dart';
import '../widgets/player_card_image.dart';

const Color _squadNameColor = Color(0xFFEEEEEE);
const Color _squadSubColor = Color(0xFFC8C8C8);

/// My Squad — player-card grid with portraits, role, tier, and core stats.
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: GameColors.neon,
            size: 20,
          ),
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
      body:
          uid == null
              ? const Center(
                child: Text(
                  'Sign in to view your squad.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: squadAsync!.when(
                      loading:
                          () => const Center(
                            child: CircularProgressIndicator(
                              color: GameColors.neon,
                            ),
                          ),
                      error:
                          (e, _) => Center(
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
                                  color: GameColors.muted.withValues(
                                    alpha: 0.95,
                                  ),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          );
                        }
                        final sorted = [...squad]..sort(
                          (a, b) => b.attributes.overall.compareTo(
                            a.attributes.overall,
                          ),
                        );
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.66,
                              ),
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            final p = sorted[index];
                            return _SquadPlayerTile(
                              player: p,
                              onTap:
                                  () =>
                                      context.push('/player/${p.id}', extra: p),
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
                            content: Text(
                              'Pick 11 players in the online match lobby.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2A2A),
                        foregroundColor: _squadNameColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: GameColors.neon,
                        size: 22,
                      ),
                      label: const Text(
                        'Playing XI',
                        style: TextStyle(
                          color: _squadNameColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Center(child: MonetizationBanner()),
                  ),
                ],
              ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 1),
    );
  }
}

class _SquadPlayerTile extends StatelessWidget {
  const _SquadPlayerTile({required this.player, required this.onTap});

  final CricketPlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = player.attributes;
    final ovr = a.overall;
    final tierLabel =
        player.playerTier == PlayerTier.premium ? 'PREMIUM' : 'FREE';
    final typeLabel = player.isRealPlayer ? 'REAL' : 'CUSTOM';

    return Material(
      color: GameColors.card,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black54,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GameColors.cardBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: PlayerCardImage(
                        imageAsset: player.cardImageAsset,
                        imageUrl: player.avatarUrl,
                        isReal: player.isRealPlayer,
                        playerName: player.displayName,
                      ),
                    ),
                    Positioned(left: 6, top: 6, child: _RatingPill(ovr: ovr)),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: _RolePill(label: player.effectiveRole.shortLabel),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                player.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _squadNameColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${player.roleLabel} · ${player.countryLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _squadSubColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$typeLabel · $tierLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      player.playerTier == PlayerTier.premium
                          ? Colors.amber.shade400
                          : GameColors.muted.withValues(alpha: 0.95),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.45,
                ),
              ),
              const SizedBox(height: 8),
              _MiniStatRow(
                batting: a.batting,
                bowling: a.bowling,
                fielding: a.fielding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.ovr});

  final int ovr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameColors.neon.withValues(alpha: 0.55)),
      ),
      child: Text(
        '$ovr',
        style: const TextStyle(
          color: GameColors.neon,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          height: 1,
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _squadNameColor,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.4,
          height: 1,
        ),
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  const _MiniStatRow({
    required this.batting,
    required this.bowling,
    required this.fielding,
  });

  final int batting;
  final int bowling;
  final int fielding;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, int value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: GameColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _squadSubColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        stat('BAT', batting, const Color(0xFF64B5F6)),
        const SizedBox(width: 4),
        stat('BWL', bowling, const Color(0xFFFFB74D)),
        const SizedBox(width: 4),
        stat('FLD', fielding, const Color(0xFF81C784)),
      ],
    );
  }
}
