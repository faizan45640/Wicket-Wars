/// Stored under `users/{uid}/matchHistory/{matchId}` after completion.
class MatchSummary {
  const MatchSummary({
    required this.matchId,
    required this.completedAt,
    required this.opponentDisplayName,
    required this.won,
    required this.runsFor,
    required this.runsAgainst,
    required this.coinsEarned,
    required this.xpEarned,
  });

  final String matchId;
  final DateTime completedAt;
  final String opponentDisplayName;
  final bool won;
  final int runsFor;
  final int runsAgainst;
  final int coinsEarned;
  final int xpEarned;

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'completedAt': completedAt.toUtc().toIso8601String(),
        'opponentDisplayName': opponentDisplayName,
        'won': won,
        'runsFor': runsFor,
        'runsAgainst': runsAgainst,
        'coinsEarned': coinsEarned,
        'xpEarned': xpEarned,
      };

  factory MatchSummary.fromMap(Map<String, dynamic> map) {
    return MatchSummary(
      matchId: map['matchId'] as String? ?? '',
      completedAt: DateTime.parse(map['completedAt'] as String).toLocal(),
      opponentDisplayName: map['opponentDisplayName'] as String? ?? '',
      won: map['won'] as bool? ?? false,
      runsFor: (map['runsFor'] as num?)?.round() ?? 0,
      runsAgainst: (map['runsAgainst'] as num?)?.round() ?? 0,
      coinsEarned: (map['coinsEarned'] as num?)?.round() ?? 0,
      xpEarned: (map['xpEarned'] as num?)?.round() ?? 0,
    );
  }
}
