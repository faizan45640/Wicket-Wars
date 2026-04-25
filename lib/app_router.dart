import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/placeholder_tab_screen.dart';
import 'screens/squad_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/online_match_screen.dart';

/// Central routing - home, leaderboard, and tab placeholders.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (BuildContext context, GoRouterState state) {
        return const LeaderboardScreen();
      },
    ),
    GoRoute(
      path: '/squad',
      builder: (BuildContext context, GoRouterState state) {
        return const SquadScreen();
      },
    ),
    GoRoute(
      path: '/matches',
      builder: (BuildContext context, GoRouterState state) {
        return const PlaceholderTabScreen(title: 'MATCHES', navIndex: 2);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileScreen();
      },
    ),
    // ... existing routes
    GoRoute(
      path: '/online-match',
      builder: (BuildContext context, GoRouterState state) {
        return const OnlineMatchScreen();
      },
    ),
  ],
);
