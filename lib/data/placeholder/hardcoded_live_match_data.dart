// Static demo data for LiveMatchScreen (replace with live engine + Firestore later).
//
// Record types (Dart 3):
//   typedef BatRow = ({ ... }) lets each row be a single lightweight object; fields
//   are read as row.name, row.r, etc. No separate class file needed for mock data.
//
// Overs math:
//   We store the innings as a total *legal ball count* in live UI state ([_balls]).
//   [formatOversFromBalls] turns that into cricket notation: every 6 balls = 1 over,
//   remainder = balls in the current over (e.g. 51 → 8.3).

typedef BatRow = ({String name, int r, int b, int fours, int sixes});
typedef BowlRow = ({String name, double overs, int maidens, int runs, int wickets});
typedef FowRow = ({int score, String details});

abstract final class HardcodedLiveMatch {
  static const String teamUser = 'Player1';
  static const String teamOpp = 'CPU';

  /// Innings: 8 complete overs + 3 balls = 8.3
  static const int maxOvers = 20;
  static const int initialTotalRuns = 45;
  static const int initialWickets = 2;
  static const int initialBalls = 8 * 6 + 3; // 8.3

  static const String striker = 'Player A';
  static const int strikerRuns = 32;
  static const int strikerBalls = 28;

  static const String currentBowler = 'Bowler B';
  static const int bowlerSpellRuns = 45;
  static const int bowlerSpellWkts = 2;
  static const int bowlerInningsRuns = 260; // "season" style fig in wireframe
  static const int bowlerInningsWkts = 2;

  static const List<String> initialCommentary = [
    "Over 8.3: A beautiful drive down to long-off for four!",
    "The field spreads — batsman looks comfortable at the crease.",
    "Bowler B comes around the wicket, shaping the ball in.",
    "Dot ball — good line on middle and off.",
    "Slight mix-up! They scramble back for two; fielder fumbles at mid-wicket.",
  ];

  static const List<String> nextBallQuips = [
    "Flicked off the pads into the leg side — the crowd roars.",
    "Edged! Falls short of first slip. Lucky escape.",
    "Bouncer! Batter ducks under comfortably.",
    "Slower ball — deceived, caught at cover (simulated).",
    "Mighty heave! Just clears the inner ring for one.",
    "Yorker dug out to long-on. They push for a second…",
  ];

  static const List<BatRow> battingOrder = [
    (name: 'Player A', r: 32, b: 28, fours: 3, sixes: 0),
    (name: 'Player C', r: 8, b: 12, fours: 1, sixes: 0),
    (name: 'Player D', r: 0, b: 1, fours: 0, sixes: 0),
  ];

  static const List<BatRow> yetToBat = [
    (name: 'Player E', r: 0, b: 0, fours: 0, sixes: 0),
    (name: 'Player F', r: 0, b: 0, fours: 0, sixes: 0),
  ];

  static const List<BowlRow> bowlingFigures = [
    (name: 'Bowler B', overs: 8.3, maidens: 0, runs: 45, wickets: 2),
    (name: 'Bowler M', overs: 6.0, maidens: 1, runs: 28, wickets: 0),
    (name: 'Bowler X', overs: 2.0, maidens: 0, runs: 18, wickets: 0),
  ];

  static const List<FowRow> fallOfWickets = [
    (score: 12, details: '1-12 Opener 8 (c mid-off b Bowler M)'),
    (score: 34, details: '2-34 No.3 4 (b Bowler B)'),
  ];
}

/// Converts total legal balls → "overs.balls" string (8.3 means 8 overs and 3 balls).
String formatOversFromBalls(int totalBalls) {
  if (totalBalls <= 0) return '0.0';
  final o = totalBalls ~/ 6; // ~/ is integer division
  final b = totalBalls % 6;
  return '$o.$b';
}

/// Strike rate: runs per 100 balls, standard cricket stat.
String formatSR(int runs, int balls) {
  if (balls == 0) return '0.0';
  return ((runs / balls) * 100).toStringAsFixed(1);
}
