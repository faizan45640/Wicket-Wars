import 'package:flutter/material.dart';

import '../theme/game_colors.dart';
import 'game_bottom_nav.dart';
import 'monetization_banner.dart';

/// Full-width container that anchors the banner ad to the bottom of the
/// screen. Sits flush above the navigation bar with a subtle top divider.
class AdBottomBar extends StatelessWidget {
  const AdBottomBar({super.key, this.withSafeArea = false});

  /// Set true only when this is the bottom-most widget (no nav bar below it),
  /// so it reserves space for the system gesture inset itself.
  final bool withSafeArea;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: GameColors.bg,
        border: Border(top: BorderSide(color: GameColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Center(child: MonetizationBanner()),
    );
    if (!withSafeArea) return bar;
    return SafeArea(top: false, child: bar);
  }
}

/// Convenience bottom area: an anchored banner ad above the standard
/// [GameBottomNav]. Use as a Scaffold `bottomNavigationBar`.
class BannerWithNav extends StatelessWidget {
  const BannerWithNav({
    super.key,
    required this.selectedIndex,
    this.lockNavigation = false,
  });

  final int selectedIndex;
  final bool lockNavigation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AdBottomBar(),
        GameBottomNav(
          selectedIndex: selectedIndex,
          lockNavigation: lockNavigation,
        ),
      ],
    );
  }
}
