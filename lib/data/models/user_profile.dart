import '../training_rules.dart';

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
    this.dailyStreak = 0,
    this.totalRunsScored = 0,
    this.starterPackOpened = false,
    this.trainingEnergy = kMaxTrainingEnergy,
    this.trainingEnergyUpdatedAt,
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

  /// Consecutive calendar days with a daily reward claim (updated on claim).
  final int dailyStreak;

  /// Career runs for profile stats (updated when matches complete).
  final int totalRunsScored;

  /// New accounts reveal a 15-player starter pack before normal play.
  final bool starterPackOpened;

  /// Stored training energy and the time it was last updated (for regen).
  final int trainingEnergy;
  final DateTime? trainingEnergyUpdatedAt;

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
    'dailyStreak': dailyStreak,
    'totalRunsScored': totalRunsScored,
    'starterPackOpened': starterPackOpened,
    'trainingEnergy': trainingEnergy,
    'trainingEnergyUpdatedAt':
        trainingEnergyUpdatedAt?.toUtc().toIso8601String(),
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
      lastDailyRewardClaimAt:
          map['lastDailyRewardClaimAt'] != null
              ? DateTime.parse(
                map['lastDailyRewardClaimAt'] as String,
              ).toLocal()
              : null,
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String).toLocal()
              : null,
      dailyStreak: (map['dailyStreak'] as num?)?.round() ?? 0,
      totalRunsScored: (map['totalRunsScored'] as num?)?.round() ?? 0,
      starterPackOpened: map['starterPackOpened'] as bool? ?? false,
      trainingEnergy:
          (map['trainingEnergy'] as num?)?.round() ?? kMaxTrainingEnergy,
      trainingEnergyUpdatedAt:
          map['trainingEnergyUpdatedAt'] != null
              ? DateTime.parse(
                map['trainingEnergyUpdatedAt'] as String,
              ).toLocal()
              : null,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    int? coins,
    int? rankingPoints,
    String? leagueTier,
    int? wins,
    int? losses,
    int? matchesPlayed,
    DateTime? lastDailyRewardClaimAt,
    DateTime? createdAt,
    int? dailyStreak,
    int? totalRunsScored,
    bool? starterPackOpened,
    int? trainingEnergy,
    DateTime? trainingEnergyUpdatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      coins: coins ?? this.coins,
      rankingPoints: rankingPoints ?? this.rankingPoints,
      leagueTier: leagueTier ?? this.leagueTier,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      lastDailyRewardClaimAt:
          lastDailyRewardClaimAt ?? this.lastDailyRewardClaimAt,
      createdAt: createdAt ?? this.createdAt,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      totalRunsScored: totalRunsScored ?? this.totalRunsScored,
      starterPackOpened: starterPackOpened ?? this.starterPackOpened,
      trainingEnergy: trainingEnergy ?? this.trainingEnergy,
      trainingEnergyUpdatedAt:
          trainingEnergyUpdatedAt ?? this.trainingEnergyUpdatedAt,
    );
  }
}
