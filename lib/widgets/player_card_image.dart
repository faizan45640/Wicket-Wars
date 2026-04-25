import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

/// Card art: real = PNG in [imagePath] (transparent background works best, [BoxFit.contain]);
/// custom = “ghost” silhouette like FIFA; empty path on real = same ghost until you add a PNG.
class PlayerCardImage extends StatelessWidget {
  const PlayerCardImage({
    super.key,
    this.imagePath,
    required this.isReal,
    this.playerName,
    this.topCornersOnly = false,
  });

  final String? imagePath;
  final bool isReal;
  final String? playerName;

  /// When embedded at the top of a FUT card, round only the top corners to match the frame.
  final bool topCornersOnly;

  static const double _aspectWidth = 3;
  static const double _aspectHeight = 4;

  BorderRadius get _radius => topCornersOnly
      ? const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        )
      : BorderRadius.circular(12);

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim() ?? '';
    final Widget child;
    if (isReal && path.isNotEmpty) {
      child = _RealPlayerPng(path: path);
    } else if (isReal) {
      child = const _FifaRealSilhouette();
    } else {
      child = const _FifaCustomSilhouette();
    }

    return Semantics(
      label: playerName ?? (isReal ? 'Player card' : 'Unknown player'),
      child: AspectRatio(
        aspectRatio: _aspectWidth / _aspectHeight,
        child: ClipRRect(
          borderRadius: _radius,
          child: child,
        ),
      ),
    );
  }
}

class _RealPlayerPng extends StatelessWidget {
  const _RealPlayerPng({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF080A08),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const _FifaRealSilhouette(),
      ),
    );
  }
}

/// Real player, no asset yet — soft neon “cutout” look (transparent feel).
class _FifaRealSilhouette extends StatelessWidget {
  const _FifaRealSilhouette();

  @override
  Widget build(BuildContext context) {
    return const _FifaFigureLayer(showQuestionMark: false);
  }
}

/// Custom / generated — ghost figure + “?”.
class _FifaCustomSilhouette extends StatelessWidget {
  const _FifaCustomSilhouette();

  @override
  Widget build(BuildContext context) {
    return const _FifaFigureLayer(showQuestionMark: true);
  }
}

class _FifaFigureLayer extends StatelessWidget {
  const _FifaFigureLayer({required this.showQuestionMark});

  final bool showQuestionMark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A100C),
                Color(0xFF040604),
                Color(0xFF0B120E),
              ],
            ),
          ),
        ),
        // Soft floor glow (FUT-style)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GameColors.neon.withValues(alpha: 0.0),
                  GameColors.neon.withValues(alpha: 0.06),
                ],
              ),
            ),
          ),
        ),
        // Transparent “Player” — layered icons read like a light cutout
        Center(
          child: Opacity(
            opacity: 0.18,
            child: Transform.translate(
              offset: const Offset(0, 6),
              child: Icon(
                Icons.person,
                size: 120,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Center(
          child: Opacity(
            opacity: 0.32,
            child: Transform.translate(
              offset: const Offset(0, 6),
              child: Icon(
                Icons.person,
                size: 120,
                color: GameColors.neon,
              ),
            ),
          ),
        ),
        if (showQuestionMark)
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                '?',
                style: TextStyle(
                  color: Color(0xFFE8E8E8),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
