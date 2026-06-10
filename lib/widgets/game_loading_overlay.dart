import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

/// Full-screen, game-style loading overlay with an animated cricket ball,
/// cycling flavor text, and a neon progress bar. Pure Flutter (no packages).
///
/// Place it as the top child of a [Stack] wrapped in [Positioned.fill] and
/// toggle [visible]. It fades itself in/out and ignores touches when hidden.
class GameLoadingOverlay extends StatefulWidget {
  const GameLoadingOverlay({
    super.key,
    required this.visible,
    this.title = 'LOADING',
    this.messages,
  });

  final bool visible;
  final String title;
  final List<String>? messages;

  /// Flavor lines for auth flows (signup / login).
  static const List<String> authMessages = [
    'Walking out to the middle…',
    'Marking the crease…',
    'Polishing the new ball…',
    'Setting the field…',
    'Reading the pitch report…',
    'Padding up…',
    'Tossing the coin…',
    'Briefing the captain…',
  ];

  /// Flavor lines for opening the starter pack.
  static const List<String> packMessages = [
    'Shuffling the squad deck…',
    'Scouting raw talent…',
    'Signing player contracts…',
    'Printing premium cards…',
    'Polishing the gold foil…',
    'Sorting the line-up…',
  ];

  @override
  State<GameLoadingOverlay> createState() => _GameLoadingOverlayState();
}

class _GameLoadingOverlayState extends State<GameLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Timer? _msgTimer;
  int _msgIndex = 0;

  List<String> get _messages =>
      widget.messages ?? GameLoadingOverlay.authMessages;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _start();
  }

  @override
  void didUpdateWidget(covariant GameLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _start();
    } else if (!widget.visible && oldWidget.visible) {
      _stop();
    }
  }

  void _start() {
    _msgIndex = 0;
    _spin.repeat();
    _msgTimer?.cancel();
    _msgTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
    });
  }

  void _stop() {
    _msgTimer?.cancel();
    _msgTimer = null;
    _spin.stop();
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Material(
          color: Colors.transparent,
          child: Container(
            color: GameColors.bg.withValues(alpha: 0.97),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: AnimatedBuilder(
                      animation: _spin,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _LoaderPainter(_spin.value),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: GameColors.neon,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 24,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder:
                          (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.5),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                      child: Text(
                        _messages[_msgIndex],
                        key: ValueKey(_msgIndex),
                        style: TextStyle(
                          color: GameColors.muted.withValues(alpha: 0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        minHeight: 6,
                        backgroundColor: GameColors.card,
                        color: GameColors.neon,
                      ),
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

class _LoaderPainter extends CustomPainter {
  _LoaderPainter(this.t);

  /// Animation value 0..1.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final angle = t * 2 * math.pi;

    // Rotating neon arc orbiting the ball.
    final ringRect = Rect.fromCircle(center: center, radius: radius - 5);
    final arcPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: [GameColors.neon.withValues(alpha: 0.0), GameColors.neon],
            transform: GradientRotation(angle),
          ).createShader(ringRect);
    canvas.drawArc(ringRect, angle, math.pi * 1.5, false, arcPaint);

    // Cricket ball.
    final ballRadius = radius * 0.5;
    final ballRect = Rect.fromCircle(center: center, radius: ballRadius);
    final ballPaint =
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.4),
            colors: [Color(0xFFE2564A), Color(0xFF9E1B14)],
          ).createShader(ballRect);
    canvas.drawCircle(center, ballRadius, ballPaint);

    final glowPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.16);
    canvas.drawCircle(center, ballRadius * 0.72, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter old) => old.t != t;
}
