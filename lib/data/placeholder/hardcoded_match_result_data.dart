// Hardcoded T20-style result: two *team* innings (not individual batters' cards).

import 'hardcoded_live_match_data.dart' show formatOversFromBalls;

/// One completed innings in the result summary.
class InningsResult {
  const InningsResult({
    required this.teamName,
    required this.runs,
    required this.wicketsDown,
    required this.legalBallsFaced,
    required this.battedFirst,
  });

  final String teamName;
  final int runs;
  final int wicketsDown;
  final int legalBallsFaced;
  /// True = this side set the target; false = chase.
  final bool battedFirst;

  String get scoreLine => '$runs/$wicketsDown (${formatOversFromBalls(legalBallsFaced)} overs)';

  /// Team run rate: runs per over (6 balls = 1 over).
  double get runRate {
    if (legalBallsFaced == 0) return 0;
    return runs / (legalBallsFaced / 6);
  }
}

abstract final class HardcodedMatchResult {
  static const String userTeam = 'Player1';
  static const String oppTeam = 'CPU';
  static const int coinsEarned = 250;

  /// Chasing team won in the 2nd innings (5 wickets in hand, target passed).
  static const String resultHeadline = '$userTeam WON BY 5 WICKETS';

  /// First innings: CPU all out. Second innings: Player1 chases 151.
  static const InningsResult innings1 = InningsResult(
    teamName: oppTeam,
    runs: 150,
    wicketsDown: 10,
    legalBallsFaced: 120, // 20.0
    battedFirst: true,
  );

  static const InningsResult innings2 = InningsResult(
    teamName: userTeam,
    runs: 151,
    wicketsDown: 5,
    legalBallsFaced: 118, // 19.4
    battedFirst: false,
  );
}
