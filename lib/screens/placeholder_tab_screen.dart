import 'package:flutter/material.dart';

import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

/// Temporary screen until Squad / Matches / Profile are built.
class PlaceholderTabScreen extends StatelessWidget {
  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.navIndex,
    this.subtitle = 'Coming soon',
  });

  final String title;
  final int navIndex;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameColors.muted.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ),
      ),
      bottomNavigationBar: GameBottomNav(selectedIndex: navIndex),
    );
  }
}
