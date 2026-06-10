/// Tuning + pure helpers for the overhauled player training system.
///
/// Mechanics: per-player potential cap, diminishing returns, single-attribute
/// sessions, scaling coin cost, daily training energy, and risk (crit/fail).
library;

/// Max training energy a profile can hold.
const int kMaxTrainingEnergy = 5;

/// Minutes to regenerate one training energy point.
const int kEnergyRefillMinutes = 20;

/// Energy granted by watching a rewarded ad.
const int kAdEnergyReward = 2;

/// Free players can never train past this overall, even on a lucky roll.
const int kFreePotentialCeiling = 95;

/// Coin cost of one training session, scaling with the player's overall.
int trainingCoinCost(int overall) => 20 + overall;

/// Stable per-player potential headroom (8..22) derived from the card id, so a
/// player's ceiling is consistent across sessions before it is persisted.
int potentialHeadroomFromId(String id) {
  final sum = id.codeUnits.fold<int>(0, (a, b) => a + b);
  return 8 + (sum % 15);
}

/// Diminishing base gain: the higher the attribute, the smaller the step.
int trainBaseGain(int attrValue) {
  if (attrValue >= 95) return 0;
  if (attrValue >= 85) return 1;
  if (attrValue >= 70) return 2;
  return 3;
}

/// Result of a training roll, used for player feedback.
enum TrainOutcome { crit, normal, weak, fail, capped }

class TrainResult {
  const TrainResult({required this.gain, required this.outcome});
  final int gain;
  final TrainOutcome outcome;
}

/// Computes a training result for a single attribute.
///
/// [roll] is a 0..1 random used for the risk mechanic. Returns 0 gain with
/// [TrainOutcome.capped] when the player is at potential or the attribute is
/// maxed (caller should not spend resources in that case).
TrainResult computeTrainResult({
  required int attrValue,
  required int overall,
  required int potential,
  required double roll,
}) {
  if (overall >= potential || attrValue >= 100) {
    return const TrainResult(gain: 0, outcome: TrainOutcome.capped);
  }
  final base = trainBaseGain(attrValue);
  if (base == 0) {
    return const TrainResult(gain: 0, outcome: TrainOutcome.capped);
  }
  int gain;
  TrainOutcome outcome;
  if (roll < 0.20) {
    gain = base + 2;
    outcome = TrainOutcome.crit;
  } else if (roll < 0.80) {
    gain = base;
    outcome = TrainOutcome.normal;
  } else {
    gain = (base - 2).clamp(0, base);
    outcome = gain == 0 ? TrainOutcome.fail : TrainOutcome.weak;
  }
  if (attrValue + gain > 100) gain = 100 - attrValue;
  return TrainResult(gain: gain, outcome: outcome);
}

/// Current usable energy given the stored value and last-update time.
int effectiveEnergy(int stored, DateTime? updatedAt, DateTime now) {
  if (updatedAt == null) return kMaxTrainingEnergy;
  final gained = now.difference(updatedAt).inMinutes ~/ kEnergyRefillMinutes;
  final total = stored + gained;
  if (total > kMaxTrainingEnergy) return kMaxTrainingEnergy;
  return total < 0 ? 0 : total;
}

/// Timestamp to store after spending one energy (preserves partial refill).
DateTime energyStampAfterSpend(int stored, DateTime? updatedAt, DateTime now) {
  final eff = effectiveEnergy(stored, updatedAt, now);
  if (eff >= kMaxTrainingEnergy || updatedAt == null) return now;
  final gained = now.difference(updatedAt).inMinutes ~/ kEnergyRefillMinutes;
  return updatedAt.add(Duration(minutes: kEnergyRefillMinutes * gained));
}

/// Time until energy is fully recharged (zero when already full).
Duration timeToFullEnergy(int stored, DateTime? updatedAt, DateTime now) {
  final eff = effectiveEnergy(stored, updatedAt, now);
  if (eff >= kMaxTrainingEnergy) return Duration.zero;
  final remaining = kMaxTrainingEnergy - eff;
  final toNext = timeToNextEnergy(stored, updatedAt, now);
  return toNext + Duration(minutes: kEnergyRefillMinutes * (remaining - 1));
}

/// Time until the next energy point regenerates (zero when full).
Duration timeToNextEnergy(int stored, DateTime? updatedAt, DateTime now) {
  if (updatedAt == null) return Duration.zero;
  if (effectiveEnergy(stored, updatedAt, now) >= kMaxTrainingEnergy) {
    return Duration.zero;
  }
  final gained = now.difference(updatedAt).inMinutes ~/ kEnergyRefillMinutes;
  final nextAt = updatedAt.add(
    Duration(minutes: kEnergyRefillMinutes * (gained + 1)),
  );
  final d = nextAt.difference(now);
  return d.isNegative ? Duration.zero : d;
}
