import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/game_colors.dart';

/// Bottom navigation helper: wraps [NavigationBar] with the app's dark palette.
/// [selectedIndex] 0=Home, 1=Squad, 2=Matches, 3=Profile.
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
      case 1:
        context.go('/squad');
      case 2:
        context.go('/matches');
      case 3:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: GameColors.bottomBar,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          height: 64,
          indicatorColor: GameColors.neon.withValues(alpha: 0.18),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final sel = states.contains(WidgetState.selected);
            return IconThemeData(
              color: sel ? GameColors.neon : GameColors.muted.withValues(alpha: 0.55),
              size: 26,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final sel = states.contains(WidgetState.selected);
            return TextStyle(
              color: sel ? GameColors.neon : GameColors.muted.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            );
          }),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _goOrLock(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'HOME',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'SQUAD',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_cricket),
            label: 'MATCHES',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}
