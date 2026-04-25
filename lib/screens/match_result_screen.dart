import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/placeholder/hardcoded_match_result_data.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

/// Post-match screen: both teams' scores (innings), comparison stats, reward, home.
class MatchResultScreen extends StatelessWidget {
  const MatchResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const i1 = HardcodedMatchResult.innings1;
    const i2 = HardcodedMatchResult.innings2;
    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'MATCH RESULT',
          style: TextStyle(
            color: Color(0xFFEEEEEE),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.6,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'WINNER / FINAL SCORE',
            style: TextStyle(
              color: GameColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            HardcodedMatchResult.resultHeadline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameColors.neon,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          _InningsLine(
            label: '1st INNINGS',
            innings: i1,
          ),
          const SizedBox(height: 12),
          _InningsLine(
            label: '2nd INNINGS (chase)',
            innings: i2,
          ),
          const SizedBox(height: 8),
          Text(
            '${i1.teamName} ${i1.runs}/${i1.wicketsDown}  ·  ${i2.teamName} ${i2.runs}/${i2.wicketsDown}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameColors.muted.withValues(alpha: 0.95),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'TEAM COMPARISON (INNINGS)',
            style: TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          _CompareCard(
            leftLabel: i1.teamName,
            rightLabel: i2.teamName,
            leftRuns: i1.runs,
            rightRuns: i2.runs,
            leftWkts: i1.wicketsDown,
            rightWkts: i2.wicketsDown,
            leftRr: i1.runRate,
            rightRr: i2.runRate,
          ),
          const SizedBox(height: 8),
          Text(
            'Bars are scaled vs a notional cap (runs 200, run rate 12). Demo only.',
            style: TextStyle(
              color: GameColors.muted.withValues(alpha: 0.65),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 24),
          _RewardsBox(coins: HardcodedMatchResult.coinsEarned),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => context.go('/'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              foregroundColor: const Color(0xFFF0F0F0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: GameColors.cardBorder),
              ),
            ),
            child: const Text(
              'RETURN TO HOME',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back, color: GameColors.muted, size: 18),
            label: const Text(
              'Return to dashboard',
              style: TextStyle(
                color: GameColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 2),
    );
  }
}

class _InningsLine extends StatelessWidget {
  const _InningsLine({required this.label, required this.innings});

  final String label;
  final InningsResult innings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: GameColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            innings.teamName,
            style: const TextStyle(
              color: Color(0xFFFAFAFA),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            innings.scoreLine,
            style: TextStyle(
              color: GameColors.neon.withValues(alpha: 0.95),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Side-by-side: each row is one stat (runs, wkts lost, run rate) for *both* teams.
class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftRuns,
    required this.rightRuns,
    required this.leftWkts,
    required this.rightWkts,
    required this.leftRr,
    required this.rightRr,
  });

  final String leftLabel;
  final String rightLabel;
  final int leftRuns;
  final int rightRuns;
  final int leftWkts;
  final int rightWkts;
  final double leftRr;
  final double rightRr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pairHeader(leftLabel, rightLabel),
          const SizedBox(height: 14),
          _statRow(
            'Runs (innings total)',
            leftRuns,
            rightRuns,
            200,
            const Color(0xFF64B5F6),
            const Color(0xFF81C784),
          ),
          const SizedBox(height: 12),
          _statRow(
            'Wkts lost',
            leftWkts,
            rightWkts,
            10,
            const Color(0xFFFFB74D),
            const Color(0xFFBA68C8),
          ),
          const SizedBox(height: 12),
          _statRowDouble(
            'Run rate (RPO)',
            leftRr,
            rightRr,
            12,
            GameColors.neon,
            const Color(0xFF4DD0E1),
          ),
        ],
      ),
    );
  }

  static Widget _pairHeader(String a, String b) {
    return Row(
      children: [
        Expanded(
          child: Text(
            a,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          'vs',
          style: TextStyle(
            color: GameColors.muted.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            b,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _statRow(
    String title,
    int left,
    int right,
    int cap,
    Color leftC,
    Color rightC,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: GameColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _barPair(left.toString(), (left / cap).clamp(0.0, 1.0), leftC),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _barPair(right.toString(), (right / cap).clamp(0.0, 1.0), rightC),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _statRowDouble(
    String title,
    double left,
    double right,
    double cap,
    Color leftC,
    Color rightC,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: GameColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _barPair(
                left.toStringAsFixed(2),
                (left / cap).clamp(0.0, 1.0),
                leftC,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _barPair(
                right.toStringAsFixed(2),
                (right / cap).clamp(0.0, 1.0),
                rightC,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _barPair(String value, double frac, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _RewardsBox extends StatelessWidget {
  const _RewardsBox({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 32),
          const SizedBox(width: 12),
          Text(
            'COINS EARNED: $coins',
            style: const TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
