import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/innings_result.dart';
import '../data/models/match_result_args.dart';
import '../data/placeholder/hardcoded_match_result_data.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

/// Post-match screen: scores from [MatchResultArgs] (Firestore flow) or demo fallback.
class MatchResultScreen extends StatelessWidget {
  const MatchResultScreen({super.key, this.args});

  final MatchResultArgs? args;

  @override
  Widget build(BuildContext context) {
    final MatchResultArgs effective;
    if (args != null) {
      effective = args!;
    } else {
      effective = MatchResultArgs(
        youWon: true,
        innings1: HardcodedMatchResult.innings1,
        innings2: HardcodedMatchResult.innings2,
        headline: HardcodedMatchResult.resultHeadline,
        coinsEarned: HardcodedMatchResult.coinsEarned,
        xpEarned: 40,
      );
    }

    final i1 = effective.innings1;
    final i2 = effective.innings2;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'FINAL',
              style: TextStyle(
                color: GameColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              effective.headline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameColors.neon,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
            if (args == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Demo fallback — complete a match from Online lobby for live data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GameColors.muted.withValues(alpha: 0.85), fontSize: 11),
                ),
              ),
            const SizedBox(height: 20),
            _InningsLine(label: '1st INNINGS', innings: i1),
            const SizedBox(height: 12),
            _InningsLine(label: '2nd INNINGS (chase)', innings: i2),
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _RewardsBox(
                    icon: Icons.monetization_on_rounded,
                    label: 'COINS',
                    value: effective.coinsEarned.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RewardsBox(
                    icon: Icons.bolt_rounded,
                    label: 'RANKING XP',
                    value: effective.xpEarned.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C),
                foregroundColor: const Color(0xFFF0F0F0),
                elevation: 0,
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
          ],
        ),
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
    return Card(
      color: GameColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.cardBorder),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ),
    );
  }
}

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
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: GameColors.cardBorder),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CompareCard._pairHeader(leftLabel, rightLabel),
            const SizedBox(height: 14),
            _CompareCard._statRow(
              'Runs (innings total)',
              leftRuns,
              rightRuns,
              200,
              const Color(0xFF64B5F6),
              const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _CompareCard._statRow(
              'Wkts lost',
              leftWkts,
              rightWkts,
              10,
              const Color(0xFFFFB74D),
              const Color(0xFFBA68C8),
            ),
            const SizedBox(height: 12),
            _CompareCard._statRowDouble(
              'Run rate (RPO)',
              leftRr,
              rightRr,
              12,
              GameColors.neon,
              const Color(0xFF4DD0E1),
            ),
          ],
        ),
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
  const _RewardsBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.cardBorder),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: GameColors.muted.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFF5F5F5),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
