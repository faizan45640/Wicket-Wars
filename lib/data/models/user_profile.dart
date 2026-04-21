/// `users/{uid}` — cloud-synced profile (coins, ranking, meta).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.coins,
    required this.rankingPoints,
    required this.leagueTier,
    required this.wins,
    required this.losses,
    required this.matchesPlayed,
    this.email,
    this.lastDailyRewardClaimAt,
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String? email;
  final int coins;
  final int rankingPoints;
  final String leagueTier;
  final int wins;
  final int losses;
  final int matchesPlayed;
  final DateTime? lastDailyRewardClaimAt;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'coins': coins,
        'rankingPoints': rankingPoints,
        'leagueTier': leagueTier,
        'wins': wins,
        'losses': losses,
        'matchesPlayed': matchesPlayed,
        'lastDailyRewardClaimAt': lastDailyRewardClaimAt?.toUtc().toIso8601String(),
        'createdAt': createdAt?.toUtc().toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Player',
      email: map['email'] as String?,
      coins: (map['coins'] as num?)?.round() ?? 0,
      rankingPoints: (map['rankingPoints'] as num?)?.round() ?? 0,
      leagueTier: map['leagueTier'] as String? ?? 'ROOKIE LEAGUE',
      wins: (map['wins'] as num?)?.round() ?? 0,
      losses: (map['losses'] as num?)?.round() ?? 0,
      matchesPlayed: (map['matchesPlayed'] as num?)?.round() ?? 0,
      lastDailyRewardClaimAt: map['lastDailyRewardClaimAt'] != null
          ? DateTime.parse(map['lastDailyRewardClaimAt'] as String).toLocal()
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String).toLocal()
          : null,
    );
  }
}
