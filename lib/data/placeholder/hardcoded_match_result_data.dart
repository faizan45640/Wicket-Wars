// Hardcoded T20-style result: two *team* innings (not individual batters' cards).

import '../models/innings_result.dart';

abstract final class HardcodedMatchResult {
  static const String userTeam = 'Player1';
  static const String oppTeam = 'CPU';
  static const int coinsEarned = 250;

  static const String resultHeadline = '$userTeam WON BY 5 WICKETS';

  static const InningsResult innings1 = InningsResult(
    teamName: oppTeam,
    runs: 150,
    wicketsDown: 10,
    legalBallsFaced: 120,
    battedFirst: true,
  );

  static const InningsResult innings2 = InningsResult(
    teamName: userTeam,
    runs: 151,
    wicketsDown: 5,
    legalBallsFaced: 118,
    battedFirst: false,
  );
}
