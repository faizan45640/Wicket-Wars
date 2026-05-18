import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

/// Inline, persistent auth error — preferred over a lone [SnackBar] for form failures
/// (Material guidance: associate errors with the task; [Semantics.liveRegion] for a11y).
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
    this.semanticsLabel = 'Error',
  });

  final String message;
  final VoidCallback onDismiss;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: semanticsLabel,
      child: Material(
        color: const Color(0xFF2D1F1F),
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade300,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.red.shade100,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close_rounded,
                  color: GameColors.muted,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  foregroundColor: GameColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
