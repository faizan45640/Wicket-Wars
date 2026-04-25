import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/placeholder/hardcoded_live_match_data.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

// --- Live match screen (educational notes) ---------------------------------
// • All "truth" for names/scorecard rows lives in [hardcoded_live_match_data.dart].
//   This file is UI + a tiny bit of mutable state for the demo "simulate" button.
// • Layout: one vertical [Column], then [Expanded] + [ListView]. That pattern is
//   important: if you put [ListView] directly in [Column] without [Expanded],
//   you get unbounded-height errors, because [Column] tries to shrink-wrap its
//   children but [ListView] wants infinite height. [Expanded] gives the list a
//   bounded height (everything below the app bar / nav strip).
// • [formatOversFromBalls] & [formatSR] are defined in the data file: cricket
//   overs are stored as *legal ball count* (e.g. 51 balls → 8.3 overs).
// ---------------------------------------------------------------------------

/// In-play match: live line, scrollable scorecard, simulate next ball (demo data + light randomness).
class LiveMatchScreen extends StatefulWidget {
  const LiveMatchScreen({super.key});

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  // --- Simulated match state (not persisted; resets when you leave the screen) ---
  late int _runs;
  late int _wickets;
  /// Total *legal* balls bowled this innings. Overs Text uses [formatOversFromBalls].
  late int _balls;
  /// Grows as the user taps "simulate". Kept in state so the feed is interactive.
  late List<String> _commentary;
  // Commentary "view window": we show [_windowLen] lines at a time from [_commentary].
  // [_window] is the start index. Arrows change this index (like scrolling without
  // nesting a second scroll view inside the main [ListView]).
  int _window = 0;
  /// Index into the static [HardcodedLiveMatch.nextBallQuips] list.
  int _quip = 0;
  final _rand = Random();

  static const int _windowLen = 4;

  @override
  void initState() {
    super.initState();
    _runs = HardcodedLiveMatch.initialTotalRuns;
    _wickets = HardcodedLiveMatch.initialWickets;
    _balls = HardcodedLiveMatch.initialBalls;
    // [List<String>.from] copies the const list so we can [add] without mutating the original.
    _commentary = List<String>.from(HardcodedLiveMatch.initialCommentary);
  }

  /// Max start index for the commentary window: last window that still fits 4 lines.
  int get _maxWindow {
    if (_commentary.isEmpty) return 0;
    return (_commentary.length - _windowLen).clamp(0, 999);
  }

  void _bumpWindow(int delta) {
    setState(() {
      _window = (_window + delta).clamp(0, _maxWindow);
    });
  }

  void _simulate() {
    if (_quip >= HardcodedLiveMatch.nextBallQuips.length) {
      // [mounted] = this [State] is still in the tree. Never use [BuildContext] after
      // async gaps without checking, or you can crash. Here it's sync but good habit.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End of mock sequence — build the engine to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _balls += 1;
      // Demi weighted random runs: more 0/1/4 than 6. Duplicates in the list = higher weight.
      final out = [0, 0, 1, 1, 2, 3, 4, 4, 4, 6];
      _runs += out[_rand.nextInt(out.length)];
      if (_rand.nextDouble() < 0.08 && _wickets < 9) {
        _wickets += 1;
      }
      _commentary.add(
        "Ball ${formatOversFromBalls(_balls)}: ${HardcodedLiveMatch.nextBallQuips[_quip]}",
      );
      _quip++;
      // After a new line, jump the window to the latest lines so the user sees the update.
      _window = _maxWindow;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Derived value: same [_balls] integer drives both header and commentary strings.
    final overs = formatOversFromBalls(_balls);
    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GameColors.neon, size: 20),
          onPressed: () {
            // [context.canPop] = was this route *pushed* on top of another? If we opened
            // this screen with [go] (replace), there is nothing to pop; fall back to [go('/')].
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          'LIVE',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GameColors.neon.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'DEMO',
                  style: TextStyle(
                    color: GameColors.neon,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // [Column] > [Expanded] > [ListView]: see file header — avoids vertical overflow.
      body: Column(
        children: [
          // Fixed-height strip; not inside the [ListView] so it always stays visible.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _NavDisabledStrip(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _headerScore(overs: overs, runs: _runs, wk: _wickets),
                const SizedBox(height: 16),
                _commentaryBlock(),
                const SizedBox(height: 20),
                _playerCardBatsman(),
                const SizedBox(height: 12),
                _playerCardBowler(),
                const SizedBox(height: 20),
                _sectionTitle('BATTING (SCORECARD)'),
                const SizedBox(height: 8),
                _battingTable(),
                const SizedBox(height: 20),
                _sectionTitle('YET TO BAT'),
                const SizedBox(height: 8),
                _yetToBatList(),
                const SizedBox(height: 20),
                _sectionTitle('BOWLING'),
                const SizedBox(height: 8),
                _bowlingTable(),
                const SizedBox(height: 20),
                _sectionTitle('FALL OF WICKETS'),
                const SizedBox(height: 8),
                _fowList(),
                const SizedBox(height: 20),
                _simulateButton(),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => context.push('/match/result'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE0E0E0),
                    side: BorderSide(color: GameColors.muted.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'VIEW MATCH RESULT (demo)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Scroll to review full card — static rows + live feed above update when you tap simulate.',
                  style: TextStyle(
                    color: GameColors.muted.withValues(alpha: 0.75),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // [lockNavigation: true] — see [GameBottomNav]: tabs show a snackbar instead of routing,
      // so the user must use back (or you later add "end match" that calls [go]).
      bottomNavigationBar: const GameBottomNav(
        selectedIndex: 2,
        lockNavigation: true,
      ),
    );
  }

  Widget _headerScore({required String overs, required int runs, required int wk}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TEAMS',
            style: TextStyle(
              color: GameColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${HardcodedLiveMatch.teamUser}  vs  ${HardcodedLiveMatch.teamOpp}',
            style: const TextStyle(
              color: Color(0xFFEEEEEE),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _headChip('RUNS', '$runs', GameColors.neon),
              const SizedBox(width: 10),
              _headChip('WICKETS', '$wk', const Color(0xFFFF8A80)),
              const Spacer(),
              _headChip('OVERS', '$overs / ${HardcodedLiveMatch.maxOvers}', GameColors.muted),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _headChip(String label, String value, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GameColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _commentaryBlock() {
    final lines = _commentary;
    final start = _window.clamp(0, _maxWindow);
    final end = (start + _windowLen).clamp(0, lines.length);
    // [sublist] is a cheap "view" into the list — no copy of all strings.
    final view = lines.sublist(start, end);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMMENTARY',
                  style: TextStyle(
                    color: GameColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < view.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Text(
                    view[i],
                    style: const TextStyle(
                      color: Color(0xFFE4E4E4),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _window <= 0 ? null : () => _bumpWindow(-1),
                icon: const Icon(Icons.keyboard_arrow_up_rounded, color: GameColors.neon),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: _window >= _maxWindow ? null : () => _bumpWindow(1),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: GameColors.neon),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playerCardBatsman() {
    return _RoleCard(
      label: 'CURRENT BATSMAN',
      name: HardcodedLiveMatch.striker,
      initial: 'A',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _miniLabelBar(
            'RUNS',
            HardcodedLiveMatch.strikerRuns,
            80,
            const Color(0xFF64B5F6),
          ),
          const SizedBox(height: 10),
          _miniLabelBar(
            'BALLS',
            HardcodedLiveMatch.strikerBalls,
            50,
            GameColors.neon,
          ),
          const SizedBox(height: 6),
          Text(
            'SR ${formatSR(HardcodedLiveMatch.strikerRuns, HardcodedLiveMatch.strikerBalls)}',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: GameColors.muted.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerCardBowler() {
    return _RoleCard(
      label: 'CURRENT BOWLER',
      name: HardcodedLiveMatch.currentBowler,
      initial: 'B',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 51 balls = 8.3 overs; "-0-45-2" = maidens, runs, wickets in classic line (demo).
          Text(
            'SPELL  ${formatOversFromBalls(51)}-0-${HardcodedLiveMatch.bowlerSpellRuns}-${HardcodedLiveMatch.bowlerSpellWkts}   |   MATCH  ${HardcodedLiveMatch.bowlerInningsRuns} runs / ${HardcodedLiveMatch.bowlerInningsWkts} wkts',
            style: TextStyle(
              color: GameColors.muted.withValues(alpha: 0.9),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ENERGY (visual)',
            style: TextStyle(
              color: GameColors.muted.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: 0.55,
              minHeight: 8,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _miniLabelBar(
    String label,
    int value,
    int cap,
    Color color,
  ) {
    // [LinearProgressIndicator.value] must be null (indeterminate) or in **0.0–1.0** — not 0–100.
    // We fake a "form" bar: [value/cap] is the fill ratio; [cap] is a UI ceiling, not cricket truth.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            Text(
              '/ $cap',
              style: TextStyle(
                color: GameColors.muted.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (value / cap).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  static Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(
        color: Color(0xFFAAAAAA),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _battingTable() {
    // [Table] lays out a grid: every [TableRow] must have the *same* number of cells.
    // [columnWidths] maps column index → [TableColumnWidth]: flex vs fixed (like CSS flex vs px).
    // [b] is a Dart 3 *record* from the data file (e.g. [BatRow] with .name, .r, .b, …).
    return _tableCard(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FixedColumnWidth(32),
          2: FixedColumnWidth(32),
          3: FixedColumnWidth(32),
          4: FixedColumnWidth(32),
          5: FixedColumnWidth(44),
        },
        children: [
          TableRow(
            children: _hdrCells(['BATSMAN', 'R', 'B', '4s', '6s', 'SR']),
          ),
          for (final b in HardcodedLiveMatch.battingOrder)
            TableRow(
              children: _rowCells(
                b.name,
                [
                  '${b.r}',
                  '${b.b}',
                  '${b.fours}',
                  '${b.sixes}',
                  formatSR(b.r, b.b),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _yetToBatList() {
    return _tableCard(
      child: Column(
        children: [
          for (final b in HardcodedLiveMatch.yetToBat)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.sports_martial_arts, color: GameColors.muted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    b.name,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bowlingTable() {
    return _tableCard(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FixedColumnWidth(40),
          2: FixedColumnWidth(32),
          3: FixedColumnWidth(36),
          4: FixedColumnWidth(32),
        },
        children: [
          TableRow(
            children: _hdrCells(['BOWLER', 'O', 'M', 'R', 'W']),
          ),
          for (final w in HardcodedLiveMatch.bowlingFigures)
            TableRow(
              children: _rowCells(
                w.name,
                [
                  w.overs.toStringAsFixed(1),
                  '${w.maidens}',
                  '${w.runs}',
                  '${w.wickets}',
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _fowList() {
    return _tableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final f in HardcodedLiveMatch.fallOfWickets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${f.score} — ${f.details}',
                style: const TextStyle(
                  color: Color(0xFFDDDDDD),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static List<Widget> _hdrCells(List<String> labels) {
    return labels
        .map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              s,
              // Short column titles (R, B, W) look better right-aligned under numbers.
              textAlign: s.length <= 2 ? TextAlign.end : TextAlign.start,
              style: const TextStyle(
                color: GameColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        )
        .toList();
  }

  /// One table row: first cell = name, remaining = numeric columns (all [TextAlign.end]).
  List<Widget> _rowCells(String name, List<String> cells) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          name,
          style: const TextStyle(
            color: Color(0xFFEEEEEE),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      ...cells.map(
        (c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            c,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ];
  }

  static Widget _tableCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: child,
    );
  }

  Widget _simulateButton() {
    // [FilledButton] = Material 3 primary filled style; [icon] is shown before [label].
    return FilledButton.icon(
      onPressed: _simulate,
      style: FilledButton.styleFrom(
        backgroundColor: GameColors.neon,
        foregroundColor: GameColors.onNeonButton,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: const Icon(Icons.sports_cricket, size: 28),
      label: const Text(
        'NEXT BALL / SIMULATE',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Reusable "avatar + label + name + custom stats" row for batsman & bowler.
/// [child] is the part that differs (bars vs text) — a simple *composition* pattern.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.name,
    required this.initial,
    required this.child,
  });

  final String label;
  final String name;
  final String initial;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0E0E0E),
              border: Border.all(color: GameColors.neon.withValues(alpha: 0.5), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: GameColors.neon,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: GameColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFFAFAFA),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown at top of [body] so the user knows why bottom tabs don't navigate away.
class _NavDisabledStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // [Material] gives a splash/ink if you later wrap in [InkWell]; also sets text color.
    return Material(
      color: const Color(0xFF252525),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.block,
              size: 16,
              color: GameColors.muted.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Navigation tabs locked during play — use the back arrow to leave.',
                style: TextStyle(
                  color: GameColors.muted.withValues(alpha: 0.9),
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
