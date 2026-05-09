import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

class _LbRow {
  const _LbRow({
    required this.rankLabel,
    required this.name,
    required this.points,
  });

  final String rankLabel;
  final String name;
  final int points;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

/// Wireframe: GLOBAL (Firestore) / FRIENDS (placeholder) tabs.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  static final NumberFormat _pointsFormat = NumberFormat.decimalPattern('en_US');

  /// 1st / 2nd / 3rd — gold, silver, bronze (visible on dark UI).
  static const List<Color> _podium = [
    Color(0xFFFFD700), // gold
    Color(0xFFE0E0E0), // silver
    Color(0xFFCD7F32), // bronze
  ];

  static const List<_LbRow> _friendsDummy = [
    _LbRow(rankLabel: '1st', name: 'You', points: 875),
    _LbRow(rankLabel: '2nd', name: 'Teammate', points: 800),
    _LbRow(rankLabel: '3rd', name: 'RivalX', points: 720),
  ];

  static String _ordinal(int n) {
    if (n <= 0) return '$n';
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  int _tab = 0; // 0 = GLOBAL, 1 = FRIENDS

  @override
  Widget build(BuildContext context) {
    final globalAsync = ref.watch(leaderboardTopProvider);

    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GameColors.neon, size: 20),
          onPressed: () => context.go('/'),
        ),
        centerTitle: true,
        title: const Text(
          'LEADERBOARD',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: _buildTabs(),
          ),
          Expanded(
            child: _tab == 0
                ? globalAsync.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No leaderboard rows yet.\n'
                              'Saving your profile (or signing in) syncs a row when the app writes `leaderboard/{uid}`.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: GameColors.muted.withValues(alpha: 0.95),
                                height: 1.45,
                              ),
                            ),
                          ),
                        );
                      }
                      final list = entries
                          .map(
                            (e) => _LbRow(
                              rankLabel: _ordinal(e.rank ?? 1),
                              name: e.displayName,
                              points: e.rankingPoints,
                            ),
                          )
                          .toList();
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 1,
                          color: GameColors.cardBorder.withValues(alpha: 0.6),
                          indent: 12,
                          endIndent: 12,
                        ),
                        itemBuilder: (context, index) {
                          return _buildRow(list[index], index);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: GameColors.neon),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load leaderboard: $e',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade200),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _friendsDummy.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: GameColors.cardBorder.withValues(alpha: 0.6),
                      indent: 12,
                      endIndent: 12,
                    ),
                    itemBuilder: (context, index) {
                      return _buildRow(_friendsDummy[index], index);
                    },
                  ),
          ),
        ],
      ),
      // Wireframe: Squad highlighted on this screen.
      bottomNavigationBar: const GameBottomNav(selectedIndex: 1),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(child: _buildTab('GLOBAL', 0)),
        const SizedBox(width: 10),
        Expanded(child: _buildTab('FRIENDS', 1)),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _tab == index;
    return TextButton(
      onPressed: () => setState(() => _tab = index),
      style: TextButton.styleFrom(
        backgroundColor: selected ? GameColors.card : GameColors.card.withValues(alpha: 0.35),
        foregroundColor: selected ? GameColors.neon : GameColors.muted,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? GameColors.neon.withValues(alpha: 0.5) : GameColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? GameColors.neon : GameColors.muted,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildRow(_LbRow e, int index) {
    final isPodium = index < 3;
    final Color? tier = isPodium ? _podium[index] : null;

    final leading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPodium)
          Icon(
            Icons.military_tech_rounded,
            size: 22,
            color: tier,
            shadows: [BoxShadow(color: tier!.withValues(alpha: 0.45), blurRadius: 10)],
          ),
        SizedBox(
          width: isPodium ? 32 : 40,
          child: Text(
            e.rankLabel,
            style: TextStyle(
              color: isPodium ? tier : GameColors.muted.withValues(alpha: 0.95),
              fontWeight: isPodium ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        CircleAvatar(
          radius: isPodium ? 20 : 18,
          backgroundColor: GameColors.card,
          child: Text(
            e.initial,
            style: TextStyle(
              color: isPodium ? tier : GameColors.neon,
              fontWeight: FontWeight.w800,
              fontSize: isPodium ? 16 : 14,
            ),
          ),
        ),
      ],
    );

    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 14, color: isPodium ? tier : GameColors.neon),
        const SizedBox(width: 4),
        Text(
          _pointsFormat.format(e.points),
          style: TextStyle(
            color: isPodium ? tier : GameColors.muted.withValues(alpha: 0.95),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final tile = ListTile(
      leading: leading,
      title: Text(
        e.name,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isPodium ? FontWeight.w800 : FontWeight.w600,
          fontSize: isPodium ? 16 : 15,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      dense: !isPodium,
    );

    if (!isPodium) return tile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tier!.withValues(alpha: 0.7), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [tier.withValues(alpha: 0.18), tier.withValues(alpha: 0.04)],
          ),
          boxShadow: [
            BoxShadow(color: tier.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: tile,
      ),
    );
  }
}
