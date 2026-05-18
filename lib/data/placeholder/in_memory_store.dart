import 'dart:math';

import '../models/cricket_player.dart';
import '../models/leaderboard_entry.dart';
import '../models/match_room.dart';
import '../models/match_summary.dart';
import '../models/pitch_condition.dart';
import '../models/player_attributes.dart';
import '../models/player_tier.dart';
import '../models/user_profile.dart';

/// Shared fake backend until Firestore is wired.
final class InMemoryStore {
  InMemoryStore._();
  static final InMemoryStore instance = InMemoryStore._();

  static const String demoUid = 'placeholder_uid';

  final _random = Random();
  bool _initialized = false;

  late UserProfile demoProfile;
  late Map<String, CricketPlayer> demoPlayersById;
  late List<LeaderboardEntry> demoLeaderboard;
  final Map<String, MatchRoom> roomsById = {};
  final Map<String, List<MatchSummary>> matchHistoryByUid = {};

  void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    demoProfile = UserProfile(
      uid: demoUid,
      displayName: 'Player123',
      email: 'demo@wicketwars.local',
      coins: 1500,
      rankingPoints: 875,
      leagueTier: 'PRO LEAGUE',
      wins: 42,
      losses: 20,
      matchesPlayed: 62,
      lastDailyRewardClaimAt: null,
      createdAt: DateTime.utc(2025, 1, 1),
      dailyStreak: 0,
      totalRunsScored: 0,
    );

    demoPlayersById = {
      for (var i = 0; i < 11; i++)
        'p_$i': CricketPlayer(
          id: 'p_$i',
          displayName: 'Squad Player ${i + 1}',
          isRealPlayer: i.isEven,
          playerTier: i.isEven ? PlayerTier.premium : PlayerTier.free,
          avatarUrl: null,
          cardImageAsset: null,
          attributes: PlayerAttributes(
            batting: 55 + i * 3,
            bowling: 50 + (i % 5) * 4,
            fielding: 52 + i,
            stamina: 60,
            consistency: 58,
          ),
        ),
    };

    demoLeaderboard = [
      LeaderboardEntry(uid: 'u1', displayName: 'TopCoach', rankingPoints: 12000, wins: 200, rank: 1),
      LeaderboardEntry(
        uid: demoUid,
        displayName: demoProfile.displayName,
        rankingPoints: demoProfile.rankingPoints,
        wins: demoProfile.wins,
        rank: 4210,
      ),
      LeaderboardEntry(uid: 'u2', displayName: 'SpinnerKing', rankingPoints: 800, wins: 12, rank: 12050),
    ];

    matchHistoryByUid[demoUid] = [];
  }

  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  MatchRoom newRoom({required String hostUid, PitchCondition pitch = PitchCondition.balanced}) {
    final code = generateRoomCode().toUpperCase();
    final room = MatchRoom(
      roomId: code,
      roomCode: code,
      status: MatchRoomStatus.waitingGuest,
      pitch: pitch,
      hostUid: hostUid,
    );
    roomsById[code] = room;
    return room;
  }
}
