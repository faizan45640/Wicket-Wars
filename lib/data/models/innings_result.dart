import '../cricket_format.dart';

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
  final bool battedFirst;

  String get scoreLine =>
      '$runs/$wicketsDown (${formatOversFromBalls(legalBallsFaced)} overs)';

  double get runRate {
    if (legalBallsFaced == 0) return 0;
    return runs / (legalBallsFaced / 6);
  }
}
