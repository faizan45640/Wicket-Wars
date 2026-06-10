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
    this.maxBalls = 120,
    this.bowlType,
    this.shotType,
    this.chaseTarget,
    this.battingRating = 60,
    this.bowlingRating = 60,
    this.fieldingRating = 60,
    this.staminaRating = 60,
    this.consistencyRating = 60,
  });

  final PitchCondition pitch;

  /// Legal deliveries that make up one innings (overs × 6).
  final int maxBalls;

  /// Chosen delivery type (`pace`/`bouncer`/`yorker`/`spin`) — null = neutral.
  final String? bowlType;

  /// Chosen shot type (`block`/`drive`/`loft`/`pull`) — null = neutral.
  final String? shotType;

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

  bool get isDeathOvers => legalBallsInInnings >= maxBalls * 0.75;

  /// Required runs per over to win (meaningful only in chase).
  double get requiredRunRatePerOver {
    if (!isChaseInnings || chaseTarget == null) return 0;
    final need = chaseTarget! - runsScoredThisInnings;
    if (need <= 0) return 0;
    final ballsLeft = (maxBalls - legalBallsInInnings).clamp(1, maxBalls);
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
    } else if (rrr <= 5 && ctx.legalBallsInInnings > ctx.maxBalls * 0.5) {
      pDot *= 1.05;
      p6 *= 0.92;
      pW *= 0.96;
    }
  }

  final m = matchupFactors(ctx.bowlType, ctx.shotType);
  pDot *= m[0];
  p1 *= m[1];
  p2 *= m[2];
  p3 *= m[3];
  p4 *= m[4];
  p6 *= m[5];
  pW *= m[6];

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

/// Allowed interactive choices, shared with the backend engine.
const List<String> kBallTypes = ['pace', 'bouncer', 'yorker', 'spin'];
const List<String> kShotTypes = ['block', 'drive', 'loft', 'pull'];

/// Multiplicative outcome modifiers from the bowl-type vs shot-type matchup.
/// Order: [dot, 1, 2, 3, 4, 6, W]. Mirrors `matchupFactors` in functions/index.js.
List<double> matchupFactors(String? bowl, String? shot) {
  final f = <double>[1, 1, 1, 1, 1, 1, 1];
  switch (shot) {
    case 'block':
      f[0] *= 1.6;
      f[1] *= 0.8;
      f[2] *= 0.5;
      f[3] *= 0.3;
      f[4] *= 0.25;
      f[5] *= 0.1;
      f[6] *= 0.45;
      break;
    case 'drive':
      f[0] *= 0.95;
      f[1] *= 1.1;
      f[2] *= 1.1;
      f[4] *= 1.35;
      f[5] *= 0.8;
      break;
    case 'loft':
      f[0] *= 0.9;
      f[1] *= 0.6;
      f[4] *= 1.5;
      f[5] *= 2.4;
      f[6] *= 1.9;
      break;
    case 'pull':
      f[0] *= 0.92;
      f[2] *= 1.2;
      f[4] *= 1.45;
      f[5] *= 1.6;
      f[6] *= 1.5;
      break;
  }
  switch (bowl) {
    case 'bouncer':
      f[5] *= 1.15;
      f[6] *= 1.1;
      break;
    case 'yorker':
      f[0] *= 1.4;
      f[1] *= 0.9;
      f[4] *= 0.5;
      f[5] *= 0.4;
      f[6] *= 1.2;
      break;
    case 'spin':
      f[1] *= 1.1;
      f[5] *= 0.9;
      f[6] *= 1.05;
      break;
  }
  if (bowl == 'yorker' && (shot == 'loft' || shot == 'pull')) {
    f[6] *= 1.8;
    f[4] *= 0.5;
    f[5] *= 0.4;
  }
  if (bowl == 'yorker' && shot == 'block') {
    f[6] *= 0.7;
    f[0] *= 1.1;
  }
  if (bowl == 'bouncer' && shot == 'pull') {
    f[4] *= 1.4;
    f[5] *= 1.5;
    f[6] *= 0.7;
  }
  if (bowl == 'bouncer' && (shot == 'drive' || shot == 'block')) {
    f[0] *= 1.2;
    f[6] *= 1.25;
  }
  if (bowl == 'spin' && shot == 'loft') f[6] *= 1.5;
  if (bowl == 'spin' && shot == 'pull') f[6] *= 1.2;
  if (bowl == 'pace' && shot == 'drive') f[4] *= 1.2;
  return f;
}
