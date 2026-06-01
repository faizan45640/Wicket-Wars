import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/models/match_result_args.dart';
import 'auth/go_router_auth_refresh.dart';
import 'theme/game_colors.dart';
import 'screens/home_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/live_match_screen.dart';
import 'screens/login_screen.dart';
import 'screens/match_result_screen.dart';
import 'screens/online_match_screen.dart';
import 'screens/player_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/starter_pack_screen.dart';
import 'screens/squad_screen.dart';

/// Central routing. Unauthenticated users are sent to [LoginScreen] via [redirect].
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: goRouterAuthRefresh,
  redirect: (BuildContext context, GoRouterState state) {
    final loggedIn = goRouterAuthRefresh.isSignedIn;
    final path = state.matchedLocation;
    final authRoute = path == '/login' || path == '/signup';
    if (!loggedIn && !authRoute) {
      return '/login';
    }
    if (loggedIn && authRoute) {
      return '/';
    }
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        return const SignupScreen();
      },
    ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/starter-pack',
      builder: (BuildContext context, GoRouterState state) {
        return const StarterPackScreen();
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
      path: '/player/:id',
      builder: (BuildContext context, GoRouterState state) {
        final p = PlayerDetailRoute.playerFromState(state);
        if (p == null) {
          return Scaffold(
            backgroundColor: GameColors.bg,
            appBar: AppBar(
              backgroundColor: GameColors.bg,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: GameColors.neon,
                ),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Player',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: const Center(
              child: Text(
                'Player not found',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        return PlayerDetailScreen(player: p);
      },
    ),
    GoRoute(
      path: '/matches',
      builder: (BuildContext context, GoRouterState state) {
        return const OnlineMatchScreen();
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileScreen();
      },
    ),
    GoRoute(
      path: '/online-match',
      builder: (BuildContext context, GoRouterState state) {
        return const OnlineMatchScreen();
      },
    ),
    GoRoute(
      path: '/match/live/:roomId',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['roomId'] ?? '';
        return LiveMatchScreen(roomId: id);
      },
    ),
    GoRoute(
      path: '/match/result',
      builder: (BuildContext context, GoRouterState state) {
        return MatchResultScreen(args: state.extra as MatchResultArgs?);
      },
    ),
  ],
);
