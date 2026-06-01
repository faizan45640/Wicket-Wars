import 'dart:math';

import 'models/pitch_condition.dart';

/// One weighted delivery outcome (simplified T20: no wides/no-balls/extras).
class SimBallResult {
  const SimBallResult({required this.runs, required this.wicket});

  final int runs;
  final int wicket;
}

/// Context for tuning probabilities — see [simulateBall].
class SimBallContext {
  const SimBallContext({
    required this.pitch,
    required this.legalBallsInInnings,
    required this.wicketsDown,
    required this.runsScoredThisInnings,
    required this.isChaseInnings,
    this.chaseTarget,
    this.battingRating = 60,
    this.bowlingRating = 60,
    this.fieldingRating = 60,
    this.staminaRating = 60,
    this.consistencyRating = 60,
  });

  final PitchCondition pitch;
  final int legalBallsInInnings;
  final int wicketsDown;
  final int runsScoredThisInnings;
  final bool isChaseInnings;
  final int? chaseTarget;
  final int battingRating;
  final int bowlingRating;
  final int fieldingRating;
  final int staminaRating;
  final int consistencyRating;

  bool get isDeathOvers => legalBallsInInnings >= 90;

  /// Required runs per over to win (meaningful only in chase).
  double get requiredRunRatePerOver {
    if (!isChaseInnings || chaseTarget == null) return 0;
    final need = chaseTarget! - runsScoredThisInnings;
    if (need <= 0) return 0;
    final ballsLeft = (120 - legalBallsInInnings).clamp(1, 120);
    return (need / ballsLeft) * 6;
  }
}

/// Sample one ball using pitch, match phase, death overs, and chase pressure.
SimBallResult simulateBall(SimBallContext ctx, Random rng) {
  // Base T20-ish frequencies (roughly ~40% scoring shots incl. 1s, rest dots + dismissals).
  var pDot = 0.36;
  var p1 = 0.28;
  var p2 = 0.12;
  var p3 = 0.02;
  var p4 = 0.10;
  var p6 = 0.08;
  var pW = 0.04;

  final battingEdge = ((ctx.battingRating - ctx.bowlingRating) / 100).clamp(
    -0.5,
    0.5,
  );
  final fieldingEdge = ((ctx.fieldingRating - 60) / 100).clamp(-0.4, 0.4);
  final staminaEdge = ((ctx.staminaRating - 60) / 100).clamp(-0.4, 0.4);
  final consistencyEdge = ((ctx.consistencyRating - 60) / 100).clamp(-0.4, 0.4);

  pDot *= 1 - battingEdge * 0.35 - consistencyEdge * 0.12;
  p1 *= 1 + consistencyEdge * 0.10;
  p2 *= 1 + battingEdge * 0.12 + staminaEdge * 0.10;
  p4 *= 1 + battingEdge * 0.55;
  p6 *= 1 + battingEdge * 0.70;
  pW *= 1 - battingEdge * 0.45 + fieldingEdge * 0.22 - consistencyEdge * 0.12;

  switch (ctx.pitch) {
    case PitchCondition.flat:
      pDot *= 0.92;
      p4 *= 1.12;
      p6 *= 1.15;
      pW *= 0.88;
      break;
    case PitchCondition.grassy:
      pDot *= 1.08;
      pW *= 1.22;
      p4 *= 0.9;
      p6 *= 0.85;
      break;
    case PitchCondition.balanced:
      break;
  }

  if (ctx.isDeathOvers) {
    pDot *= 0.92;
    p4 *= 1.08;
    p6 *= 1.1;
    pW *= 1.06;
  }

  if (ctx.wicketsDown >= 7) {
    pDot *= 1.06;
    p6 *= 0.88;
    pW *= 0.94;
  }

  if (ctx.isChaseInnings && ctx.chaseTarget != null) {
    final rrr = ctx.requiredRunRatePerOver;
    if (rrr >= 11) {
      pDot *= 0.9;
      p4 *= 1.1;
      p6 *= 1.18;
      pW *= 1.08;
    } else if (rrr <= 5 && ctx.legalBallsInInnings > 60) {
      pDot *= 1.05;
      p6 *= 0.92;
      pW *= 0.96;
    }
  }

  var probs = <double>[pDot, p1, p2, p3, p4, p6, pW];
  final sum = probs.reduce((a, b) => a + b);
  probs = probs.map((p) => p / sum).toList();

  final u = rng.nextDouble();
  var c = 0.0;
  for (var i = 0; i < probs.length; i++) {
    c += probs[i];
    if (u <= c) {
      switch (i) {
        case 0:
          return const SimBallResult(runs: 0, wicket: 0);
        case 1:
          return const SimBallResult(runs: 1, wicket: 0);
        case 2:
          return const SimBallResult(runs: 2, wicket: 0);
        case 3:
          return const SimBallResult(runs: 3, wicket: 0);
        case 4:
          return const SimBallResult(runs: 4, wicket: 0);
        case 5:
          return const SimBallResult(runs: 6, wicket: 0);
        case 6:
        default:
          return const SimBallResult(runs: 0, wicket: 1);
      }
    }
  }
  return const SimBallResult(runs: 0, wicket: 0);
}
