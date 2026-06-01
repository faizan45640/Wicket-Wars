import 'dart:math';

import '../match_delivery_engine.dart';
import '../models/cricket_player.dart';
import '../models/match_room.dart';
import '../models/match_summary.dart';
import '../models/pitch_condition.dart';
import '../repositories/match_repository.dart';
import 'in_memory_store.dart';

class PlaceholderMatchRepository implements MatchRepository {
  final InMemoryStore _store = InMemoryStore.instance;
  final Random _random = Random();

  PlaceholderMatchRepository() {
    _store.ensureInitialized();
  }

  @override
  Future<MatchRoom> createRoom({required String hostUid}) async {
    return _store.newRoom(hostUid: hostUid, pitch: PitchCondition.balanced);
  }

  @override
  Future<MatchRoom?> getRoom(String roomId) async => _store.roomsById[roomId];

  @override
  Future<void> joinRoom({
    required String roomCode,
    required String guestUid,
  }) async {
    final room = _store.roomsById[roomCode.toUpperCase()];
    if (room == null) return;
    if (room.guestUid != null &&
        room.guestUid!.isNotEmpty &&
        room.guestUid != guestUid) {
      throw StateError('Room already has a guest.');
    }
    _store.roomsById[room.roomId] = room.copyWith(
      status: MatchRoomStatus.selectingXi,
      guestUid: guestUid,
    );
    _store.notifyRoomChanged(room.roomId);
  }

  @override
  Future<void> lockStrongestXi({required String roomId}) async {
    final room = _store.roomsById[roomId];
    if (room == null || room.guestUid == null) return;
    final hostXi = _strongestXi(room.hostUid);
    final guestXi = _strongestXi(room.guestUid);
    var next = room.copyWith(
      hostPlayingXi: hostXi.map((p) => p.id).toList(),
      guestPlayingXi: guestXi.map((p) => p.id).toList(),
      hostXiLocked: hostXi.length >= 11,
      guestXiLocked: guestXi.length >= 11,
      status:
          hostXi.length >= 11 && guestXi.length >= 11
              ? MatchRoomStatus.inProgress
              : MatchRoomStatus.selectingXi,
    );
    if (next.hostXiLocked && next.guestXiLocked && next.hostBatFirst == null) {
      final hostBatFirst = _random.nextBool();
      next = next.copyWith(
        hostBatFirst: hostBatFirst,
        inningsNumber: 1,
        chaseTarget: null,
        hostRuns: 0,
        guestRuns: 0,
        hostWickets: 0,
        guestWickets: 0,
        hostLegalBalls: 0,
        guestLegalBalls: 0,
        deliveryNumber: 0,
        commentaryTail: [
          'Toss - ${hostBatFirst ? 'Host' : 'Guest'} bats first. T20: 20 overs per innings.',
        ],
      );
    }
    await saveRoom(next);
  }

  @override
  Future<void> lockPlayingXi({
    required String roomId,
    required List<String> playerIds,
  }) async {
    final room = _store.roomsById[roomId];
    if (room == null || room.guestUid == null) return;
    final uniqueIds = playerIds.toSet().toList();
    if (uniqueIds.length != 11) {
      throw StateError('Select exactly 11 unique players.');
    }
    // Placeholder cannot know the current caller, so it keeps demo behavior.
    await lockStrongestXi(roomId: roomId);
  }

  @override
  Future<void> advanceDelivery({required String roomId}) async {
    await transactRoom(roomId, (room) {
      if (room.status == MatchRoomStatus.completed) return room;
      if (_isFinishedScoreState(room)) return _completed(room);
      final next = applyOneDelivery(
        room,
        _random,
        hostPlayers: _selectedPlayers(room.hostUid, room.hostPlayingXi),
        guestPlayers: _selectedPlayers(room.guestUid, room.guestPlayingXi),
      );
      if (next == null) return room;
      return _isFinishedScoreState(next) ? _completed(next) : next;
    });
  }

  @override
  Future<void> forceComplete({required String roomId}) async {
    await transactRoom(roomId, (room) => _completed(room));
  }

  @override
  Future<void> claimResult({required String roomId}) async {
    final room = _store.roomsById[roomId];
    if (room == null || room.status != MatchRoomStatus.completed) return;
    for (final uid in [room.hostUid, room.guestUid]) {
      if (uid == null || room.resultAppliedUids.contains(uid)) continue;
      final profile =
          uid == InMemoryStore.demoUid
              ? _store.demoProfile
              : _store.extraProfilesByUid[uid] ??
                  _store.demoProfile.copyWith(uid: uid);
      final stats = _rewardStats(room, uid);
      final updated = profile.copyWith(
        wins: profile.wins + (stats.won ? 1 : 0),
        losses: profile.losses + (!stats.won && !stats.tie ? 1 : 0),
        matchesPlayed: profile.matchesPlayed + 1,
        coins: profile.coins + stats.coins,
        rankingPoints: profile.rankingPoints + stats.xp,
        totalRunsScored: profile.totalRunsScored + stats.runsFor,
      );
      if (uid == InMemoryStore.demoUid) {
        _store.demoProfile = updated;
      } else {
        _store.extraProfilesByUid[uid] = updated;
      }
      _store.matchHistoryByUid
          .putIfAbsent(uid, () => [])
          .add(
            MatchSummary(
              matchId: roomId,
              completedAt: room.completedAt ?? DateTime.now(),
              opponentDisplayName: 'Opponent',
              won: stats.won,
              runsFor: stats.runsFor,
              runsAgainst: stats.runsAgainst,
              coinsEarned: stats.coins,
              xpEarned: stats.xp,
            ),
          );
    }
    await saveRoom(
      room.copyWith(
        resultAppliedUids: [
          if (room.hostUid != null) room.hostUid!,
          if (room.guestUid != null) room.guestUid!,
        ],
      ),
    );
  }

  @override
  Future<void> saveRoom(MatchRoom room) async {
    _store.roomsById[room.roomId] = room;
    _store.notifyRoomChanged(room.roomId);
  }

  @override
  Future<MatchRoom?> transactRoom(
    String roomId,
    MatchRoom? Function(MatchRoom current) update,
  ) async {
    final current = _store.roomsById[roomId];
    if (current == null) return null;
    final next = update(current);
    if (next == null) return null;
    _store.roomsById[roomId] = next;
    _store.notifyRoomChanged(roomId);
    return next;
  }

  @override
  Stream<MatchRoom?> watchRoom(String roomId) => _store.watchRoom(roomId);

  List<CricketPlayer> _strongestXi(String? uid) {
    final squad = _squad(uid)
      ..sort((a, b) => b.attributes.overall.compareTo(a.attributes.overall));
    return squad.take(11).toList();
  }

  List<CricketPlayer> _squad(String? uid) {
    if (uid == null || uid.isEmpty) return [];
    if (uid == InMemoryStore.demoUid) {
      return _store.demoPlayersById.values.toList();
    }
    return _store.extraSquadsByUid[uid]?.values.toList() ??
        _store.demoPlayersById.values.toList();
  }

  List<CricketPlayer> _selectedPlayers(String? uid, List<String> ids) {
    final squad = _squad(uid);
    final byId = {for (final p in squad) p.id: p};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  bool _isFinishedScoreState(MatchRoom room) {
    if (room.inningsNumber != 2) return false;
    return shouldAutoCompleteMatchAfterDelivery(
      room,
      strikerWasHost: battingIsHost(room),
    );
  }

  MatchRoom _completed(MatchRoom room) {
    final winnerUid =
        room.hostRuns == room.guestRuns
            ? null
            : (room.hostRuns > room.guestRuns ? room.hostUid : room.guestUid);
    return room.copyWith(
      status: MatchRoomStatus.completed,
      winnerUid: winnerUid,
      completedAt: DateTime.now(),
      commentaryTail: [
        ...room.commentaryTail,
        winnerUid == null
            ? 'Match tied - ${room.hostRuns} runs each.'
            : 'Match complete - ${room.hostRuns}/${room.hostWickets} vs ${room.guestRuns}/${room.guestWickets}.',
      ],
    );
  }

  _RewardStats _rewardStats(MatchRoom room, String uid) {
    final youHost = room.hostUid == uid;
    final runsFor = youHost ? room.hostRuns : room.guestRuns;
    final runsAgainst = youHost ? room.guestRuns : room.hostRuns;
    final tie = runsFor == runsAgainst;
    final won = !tie && runsFor > runsAgainst;
    return _RewardStats(
      runsFor: runsFor,
      runsAgainst: runsAgainst,
      won: won,
      tie: tie,
      coins: tie ? 35 + (runsFor ~/ 3) : 40 + (won ? 90 : 15) + (runsFor ~/ 3),
      xp: tie ? 18 : (won ? 30 : 12),
    );
  }
}

class _RewardStats {
  const _RewardStats({
    required this.runsFor,
    required this.runsAgainst,
    required this.won,
    required this.tie,
    required this.coins,
    required this.xp,
  });

  final int runsFor;
  final int runsAgainst;
  final bool won;
  final bool tie;
  final int coins;
  final int xp;
}
