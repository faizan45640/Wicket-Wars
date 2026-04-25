import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

/// Wireframe: GLOBAL / FRIENDS tabs, scrollable list, same game styling as home.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static final NumberFormat _pointsFormat = NumberFormat.decimalPattern('en_US');

  /// 1st / 2nd / 3rd — gold, silver, bronze (visible on dark UI).
  static const List<Color> _podium = [
    Color(0xFFFFD700), // gold
    Color(0xFFE0E0E0), // silver
    Color(0xFFCD7F32), // bronze
  ];

  /// Per wireframe dummy data (5th place skipped).
  static const List<_LbRow> _globalDummy = [
    _LbRow(rankLabel: '1st', name: 'PlayerOne', points: 1250),
    _LbRow(rankLabel: '2nd', name: 'PlayerTwo', points: 1250),
    _LbRow(rankLabel: '3rd', name: 'PlayerThro', points: 1100),
    _LbRow(rankLabel: '4th', name: 'PlayerOur', points: 1100),
    _LbRow(rankLabel: '6th', name: 'PlayerSix', points: 950),
    _LbRow(rankLabel: '7th', name: 'PlayerSix', points: 950),
    _LbRow(rankLabel: '8th', name: 'PlayerGig', points: 700),
    _LbRow(rankLabel: '9th', name: 'PlayerBno', points: 650),
    _LbRow(rankLabel: '10th', name: 'PlayerLi', points: 550),
  ];

  static const List<_LbRow> _friendsDummy = [
    _LbRow(rankLabel: '1st', name: 'You', points: 875),
    _LbRow(rankLabel: '2nd', name: 'Teammate', points: 800),
    _LbRow(rankLabel: '3rd', name: 'RivalX', points: 720),
  ];

  int _tab = 0; // 0 = GLOBAL, 1 = FRIENDS

  @override
  Widget build(BuildContext context) {
    final list = _tab == 0 ? _globalDummy : _friendsDummy;

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
            child: ListView.separated(
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
        Expanded(
          child: _TabChip(
            label: 'GLOBAL',
            selected: _tab == 0,
            onTap: () => setState(() => _tab = 0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabChip(
            label: 'FRIENDS',
            selected: _tab == 1,
            onTap: () => setState(() => _tab = 1),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_LbRow e, int index) {
    final isPodium = index < 3;
    final Color? tier = isPodium ? _podium[index] : null;

    final row = Row(
      children: [
        if (isPodium)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              Icons.military_tech_rounded,
              size: 26,
              color: tier,
              shadows: [
                BoxShadow(
                  color: tier!.withValues(alpha: 0.45),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        SizedBox(
          width: isPodium ? 38 : 44,
          child: Text(
            e.rankLabel,
            style: TextStyle(
              color: isPodium ? tier : GameColors.muted.withValues(alpha: 0.95),
              fontWeight: isPodium ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          width: isPodium ? 44 : 40,
          height: isPodium ? 44 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isPodium ? tier! : GameColors.cardBorder,
              width: isPodium ? 2.2 : 1.5,
            ),
            color: GameColors.card,
            boxShadow: isPodium
                ? [
                    BoxShadow(
                      color: tier!.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            e.initial,
            style: TextStyle(
              color: isPodium ? tier : GameColors.neon,
              fontWeight: FontWeight.w800,
              fontSize: isPodium ? 18 : 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            e.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isPodium ? FontWeight.w800 : FontWeight.w600,
              fontSize: isPodium ? 16 : 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPodium
                      ? tier!.withValues(alpha: 0.55)
                      : GameColors.neon.withValues(alpha: 0.4),
                ),
                color: isPodium ? tier!.withValues(alpha: 0.12) : null,
              ),
              child: Icon(
                Icons.star_rounded,
                size: 14,
                color: isPodium ? tier : GameColors.neon,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'POINTS: ${_pointsFormat.format(e.points)}',
              style: TextStyle(
                color: isPodium ? tier : GameColors.muted.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );

    if (!isPodium) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: row,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tier!.withValues(alpha: 0.7), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              tier.withValues(alpha: 0.18),
              tier.withValues(alpha: 0.04),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: tier.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: row,
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? GameColors.card : GameColors.card.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? GameColors.neon.withValues(alpha: 0.5) : GameColors.cardBorder,
              width: selected ? 1.5 : 1,
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
        ),
      ),
    );
  }
}
