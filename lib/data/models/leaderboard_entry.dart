/// `leaderboard/{uid}` or denormalized row in a `leaderboard` query.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.rankingPoints,
    required this.wins,
    this.rank,
  });

  final String uid;
  final String displayName;
  final int rankingPoints;
  final int wins;
  final int? rank;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'rankingPoints': rankingPoints,
        'wins': wins,
        'rank': rank,
      };

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      rankingPoints: (map['rankingPoints'] as num?)?.round() ?? 0,
      wins: (map['wins'] as num?)?.round() ?? 0,
      rank: (map['rank'] as num?)?.round(),
    );
  }
}
