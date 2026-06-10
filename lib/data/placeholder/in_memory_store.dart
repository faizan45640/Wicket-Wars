import 'dart:async';
import 'dart:math';

import '../models/cricket_player.dart';
import '../models/leaderboard_entry.dart';
import '../models/match_room.dart';
import '../models/match_summary.dart';
import '../models/pitch_condition.dart';
import '../models/player_attributes.dart';
import '../models/player_role.dart';
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
  final Map<String, StreamController<MatchRoom?>> _roomControllers = {};
  final Map<String, List<MatchSummary>> matchHistoryByUid = {};
  final Map<String, UserProfile> extraProfilesByUid = {};

  /// Squads for non-demo UIDs (widget tests, offline streak bonuses, etc.).
  final Map<String, Map<String, CricketPlayer>> extraSquadsByUid = {};

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
      starterPackOpened: true,
    );

    demoPlayersById = {
      for (var i = 0; i < 11; i++)
        'p_$i': CricketPlayer(
          id: 'p_$i',
          displayName: 'Squad Player ${i + 1}',
          isRealPlayer: i.isEven,
          playerTier: i.isEven ? PlayerTier.premium : PlayerTier.free,
          role: PlayerRole.infer(
            batting: 55 + i * 3,
            bowling: 50 + (i % 5) * 4,
            wicketKeeper: i == 4,
          ),
          country:
              const [
                'Pakistan',
                'India',
                'Australia',
                'England',
                'Sri Lanka',
                'South Africa',
                'New Zealand',
                'Bangladesh',
                'Afghanistan',
                'West Indies',
                'UAE',
              ][i],
          battingStyle: i.isEven ? 'Right-hand bat' : 'Left-hand bat',
          bowlingStyle:
              i == 4
                  ? 'Wicket keeper'
                  : i % 3 == 0
                  ? 'Right-arm fast'
                  : 'Right-arm spin',
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
      LeaderboardEntry(
        uid: 'u1',
        displayName: 'TopCoach',
        rankingPoints: 12000,
        wins: 200,
        rank: 1,
      ),
      LeaderboardEntry(
        uid: demoUid,
        displayName: demoProfile.displayName,
        rankingPoints: demoProfile.rankingPoints,
        wins: demoProfile.wins,
        rank: 4210,
      ),
      LeaderboardEntry(
        uid: 'u2',
        displayName: 'SpinnerKing',
        rankingPoints: 800,
        wins: 12,
        rank: 12050,
      ),
    ];

    matchHistoryByUid[demoUid] = [];
  }

  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  MatchRoom newRoom({
    required String hostUid,
    PitchCondition pitch = PitchCondition.balanced,
    int overs = 20,
  }) {
    final code = generateRoomCode().toUpperCase();
    final room = MatchRoom(
      roomId: code,
      roomCode: code,
      status: MatchRoomStatus.waitingGuest,
      pitch: pitch,
      oversPerInnings: overs,
      hostUid: hostUid,
    );
    roomsById[code] = room;
    notifyRoomChanged(code);
    return room;
  }

  Stream<MatchRoom?> watchRoom(String roomId) {
    final controller = _roomControllers.putIfAbsent(
      roomId,
      () => StreamController<MatchRoom?>.broadcast(),
    );
    return (() async* {
      yield roomsById[roomId];
      yield* controller.stream;
    })();
  }

  void notifyRoomChanged(String roomId) {
    final controller = _roomControllers[roomId];
    if (controller == null || controller.isClosed) return;
    controller.add(roomsById[roomId]);
  }
}
