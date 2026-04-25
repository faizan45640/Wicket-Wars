import 'package:flutter/material.dart';

import '../data/models/cricket_player.dart';
import '../data/models/player_attributes.dart';
import '../theme/game_colors.dart';
import 'player_card_image.dart';

// Readable on dark + neon UI
const Color _textPrimary = Color(0xFFF2F2F2);
const Color _textSecondary = Color(0xFFCCCCCC);
const Color _textMuted = Color(0xFFB0B0B0);

/// Full player card: FIFA-style [PlayerCardImage] (transparent / PNG) + stats.
Future<void> showFifaStylePlayerCard(
  BuildContext context, {
  required CricketPlayer player,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (ctx) {
      return _FifaCardDialog(player: player);
    },
  );
}

String _positionLabel(PlayerAttributes a) {
  if (a.batting - a.bowling >= 12) return 'BAT';
  if (a.bowling - a.batting >= 12) return 'BWL';
  return 'ALL';
}

class _FifaCardDialog extends StatelessWidget {
  const _FifaCardDialog({required this.player});

  final CricketPlayer player;

  @override
  Widget build(BuildContext context) {
    final a = player.attributes;
    final ovr = a.overall;
    final pos = _positionLabel(a);
    const accent = GameColors.neon;
    const innerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1e2836),
        Color(0xFF121a14),
        GameColors.card,
      ],
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.94, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        GameColors.neon.withValues(alpha: 0.55),
                        GameColors.cardBorder,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GameColors.neon.withValues(alpha: 0.12),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            PlayerCardImage(
                              imagePath: player.cardImageAsset,
                              isReal: player.isRealPlayer,
                              playerName: player.displayName,
                              topCornersOnly: true,
                            ),
                            Positioned(
                              left: 10,
                              top: 10,
                              child: _GlassStatPill(
                                child: Text(
                                  '$ovr',
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 10,
                              child: _GlassStatPill(
                                child: Text(
                                  pos,
                                  style: const TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          decoration: const BoxDecoration(gradient: innerGradient),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                player.displayName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                player.isRealPlayer ? 'VERIFIED' : 'CUSTOM',
                                style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'ATTRIBUTES',
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _StatRow(
                                label: 'BAT',
                                value: a.batting,
                                color: const Color(0xFF64B5F6),
                              ),
                              const SizedBox(height: 8),
                              _StatRow(
                                label: 'BWL',
                                value: a.bowling,
                                color: const Color(0xFFFFB74D),
                              ),
                              const SizedBox(height: 8),
                              _StatRow(
                                label: 'FLD',
                                value: a.fielding,
                                color: const Color(0xFF81C784),
                              ),
                              const SizedBox(height: 8),
                              _StatRow(
                                label: 'STA',
                                value: a.stamina,
                                color: const Color(0xFFBA68C8),
                              ),
                              const SizedBox(height: 8),
                              _StatRow(
                                label: 'CON',
                                value: a.consistency,
                                color: const Color(0xFF4DD0E1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _textPrimary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassStatPill extends StatelessWidget {
  const _GlassStatPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final v = (value / 100).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
