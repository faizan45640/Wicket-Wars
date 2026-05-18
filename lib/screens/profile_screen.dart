import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models/match_summary.dart';
import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static final _fmt = NumberFormat.decimalPattern('en_US');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const neonGreen = Color(0xFF00FF00);
    final profileAsync = ref.watch(userProfileProvider);
    final uid = ref.watch(currentUidProvider);
    final historyAsync =
        uid != null ? ref.watch(matchHistoryProvider(uid)) : const AsyncValue<List<MatchSummary>>.data([]);

    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: neonGreen, size: 32),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: GameColors.neon)),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: Colors.red.shade200))),
        data: (profile) {
          final p = profile;
          if (p == null) {
            return const Center(
              child: Text('No profile', style: TextStyle(color: Colors.white70)),
            );
          }
          final totalRuns = historyAsync.maybeWhen(
            data: (h) => h.fold<int>(0, (s, m) => s + m.runsFor),
            orElse: () => p.totalRunsScored,
          );
          final winRate = p.matchesPlayed > 0 ? ((p.wins / p.matchesPlayed) * 100).round() : 0;

          final initial = p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?';
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: GameColors.bg,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: neonGreen, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: neonGreen.withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: GameColors.bg,
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: neonGreen,
                          fontSize: 44,
                          fontWeight: FontWeight.w500,
                          shadows: [Shadow(color: neonGreen.withValues(alpha: 0.8), blurRadius: 10)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  p.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              if (p.email != null && p.email!.isNotEmpty)
                Center(
                  child: Text(
                    p.email!,
                    style: TextStyle(color: GameColors.muted.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  p.leagueTier,
                  style: TextStyle(
                    color: GameColors.neon.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: GameColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: GameColors.cardBorder),
                ),
                elevation: 0,
                child: Column(
                  children: [
                    _tile(Icons.sports_cricket_outlined, 'Total Matches', '${p.matchesPlayed}'),
                    _tile(Icons.emoji_events_outlined, 'Wins', '${p.wins}'),
                    _tile(Icons.close_rounded, 'Losses', '${p.losses}'),
                    _tile(Icons.percent_outlined, 'Win rate', '$winRate%'),
                    _tile(Icons.sports_baseball_outlined, 'Runs scored (history)', _fmt.format(totalRuns)),
                    _tile(Icons.star_border_rounded, 'Ranking Points', _fmt.format(p.rankingPoints)),
                    _tile(Icons.local_fire_department_outlined, 'Daily streak', '${p.dailyStreak} days'),
                    _tile(Icons.monetization_on_outlined, 'Coins', _fmt.format(p.coins), isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE57373),
                  side: const BorderSide(color: Color(0xFF4A2C2C)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 3),
    );
  }

  static Widget _tile(IconData icon, String title, String value, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white, size: 26),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: GameColors.cardBorder.withValues(alpha: 0.5),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
