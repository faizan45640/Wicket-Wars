import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/game_colors.dart';

/// Same bottom bar as the home screen; [selectedIndex] 0=Home, 1=Squad, 2=Matches, 3=Profile.
class GameBottomNav extends StatelessWidget {
  const GameBottomNav({
    super.key,
    required this.selectedIndex,
    this.lockNavigation = false,
  });

  final int selectedIndex;

  /// When true (e.g. live match), tab taps show a message instead of navigating.
  final bool lockNavigation;

  void _goOrLock(BuildContext context, int index) {
    if (lockNavigation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finish the match or use the back button to leave.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/squad');
        break;
      case 2:
        context.go('/matches');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: const BoxDecoration(
        color: GameColors.bottomBar,
        border: Border(top: BorderSide(color: GameColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Item(
              icon: Icons.home_rounded,
              label: 'HOME',
              selected: selectedIndex == 0,
              onTap: () => _goOrLock(context, 0),
            ),
            _Item(
              icon: Icons.groups_outlined,
              label: 'SQUAD',
              selected: selectedIndex == 1,
              onTap: () => _goOrLock(context, 1),
            ),
            _Item(
              icon: Icons.sports_cricket,
              label: 'MATCHES',
              selected: selectedIndex == 2,
              onTap: () => _goOrLock(context, 2),
            ),
            _Item(
              icon: Icons.person_outline,
              label: 'PROFILE',
              selected: selectedIndex == 3,
              onTap: () => _goOrLock(context, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GameColors.neon : GameColors.muted.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 26,
              shadows: selected
                  ? [
                      Shadow(
                        color: GameColors.neon.withValues(alpha: 0.75),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            if (selected)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: GameColors.neon,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
