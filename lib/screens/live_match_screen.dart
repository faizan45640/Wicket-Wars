import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/cricket_format.dart';
import '../data/match_delivery_engine.dart';
import '../data/models/innings_result.dart';
import '../data/models/match_result_args.dart';
import '../data/models/match_room.dart';
import '../data/models/match_summary.dart';
import '../data/providers.dart';
import '../data/repositories/squad_repository.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

/// T20 match: sequential innings, Firestore-backed state; each delivery uses [applyOneDelivery] inside [MatchRepository.transactRoom] on Firebase.
class LiveMatchScreen extends ConsumerStatefulWidget {
  const LiveMatchScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  final _rand = Random();
  var _finishing = false;
  var _busyBall = false;
  var _bootstrapping = false;

  Future<void> _bootstrapIfNeeded(MatchRoom room) async {
    if (_bootstrapping) return;
    if (room.status == MatchRoomStatus.completed) return;
    if (room.guestUid == null || room.guestUid!.isEmpty) return;

    _bootstrapping = true;
    try {
      final repo = ref.read(matchRepositoryProvider);
      var r = await repo.getRoom(room.roomId);
      if (!mounted || r == null) return;

      final squadRepo = ref.read(squadRepositoryProvider);
      final hostXi = await _pickXi(squadRepo, r.hostUid);
      final guestXi = await _pickXi(squadRepo, r.guestUid);

      var changed = false;
      if (!r.hostXiLocked || r.hostPlayingXi.isEmpty) {
        r = r.copyWith(hostPlayingXi: hostXi, hostXiLocked: true);
        changed = true;
      }
      if (!r.guestXiLocked || r.guestPlayingXi.isEmpty) {
        r = r.copyWith(guestPlayingXi: guestXi, guestXiLocked: true);
        changed = true;
      }
      if (r.status == MatchRoomStatus.waitingGuest ||
          r.status == MatchRoomStatus.selectingXi) {
        r = r.copyWith(status: MatchRoomStatus.inProgress);
        changed = true;
      }
      if (r.hostBatFirst == null) {
        final batFirst = _rand.nextBool();
        final startMsg =
            'Toss — ${batFirst ? 'Host' : 'Guest'} bats first. T20: 20 overs max per innings. Tap “Next delivery”.';
        var tail = [...r.commentaryTail, startMsg];
        if (tail.length > 30) tail = tail.sublist(tail.length - 30);
        r = r.copyWith(
          hostBatFirst: batFirst,
          inningsNumber: 1,
          chaseTarget: null,
          hostRuns: 0,
          guestRuns: 0,
          hostWickets: 0,
          guestWickets: 0,
          hostLegalBalls: 0,
          guestLegalBalls: 0,
          commentaryTail: tail,
        );
        changed = true;
      }
      if (changed) await repo.saveRoom(r);
    } finally {
      if (mounted) _bootstrapping = false;
    }
  }

  Future<List<String>> _pickXi(SquadRepository squadRepo, String? uid) async {
    if (uid == null || uid.isEmpty) return [];
    final list = await squadRepo.getSquad(uid);
    final sorted = [...list]..sort((a, b) => b.attributes.overall.compareTo(a.attributes.overall));
    return sorted.take(11).map((p) => p.id).toList();
  }

  Future<void> _nextDelivery() async {
    if (_busyBall || _finishing) return;
    final repo = ref.read(matchRepositoryProvider);
    var room = await repo.getRoom(widget.roomId);
    if (!mounted || room == null || room.status == MatchRoomStatus.completed) return;
    if (room.hostBatFirst == null) {
      await _bootstrapIfNeeded(room);
      room = await repo.getRoom(widget.roomId);
      if (!mounted || room == null || room.hostBatFirst == null) return;
    }

    final strikerAtCall = battingIsHost(room);
    final br = strikerAtCall ? room.hostRuns : room.guestRuns;
    if (room.inningsNumber == 2 &&
        room.chaseTarget != null &&
        br >= room.chaseTarget!) {
      await _tryFinalize(room);
      return;
    }

    _busyBall = true;
    try {
      final after = await repo.transactRoom(widget.roomId, (current) {
        return applyOneDelivery(current, _rand);
      });
      if (!mounted || after == null) return;

      if (after.inningsNumber == 2 &&
          shouldAutoCompleteMatchAfterDelivery(
            after,
            strikerWasHost: battingIsHost(after),
          )) {
        await _tryFinalize(after);
      }
    } finally {
      if (mounted) _busyBall = false;
    }
  }

  Future<void> _tryFinalize(MatchRoom room) async {
    if (room.status == MatchRoomStatus.completed) return;
    await _completeMatch(room);
  }

  Future<void> _completeMatch(MatchRoom room) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null || !mounted) return;

    setState(() => _finishing = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final oppUid =
          room.hostUid == uid ? room.guestUid : room.hostUid;
      var oppName = 'Practice opponent';
      if (oppUid != null && oppUid.isNotEmpty) {
        final oppProfile = await userRepo.getProfile(oppUid);
        oppName = oppProfile?.displayName ?? 'Opponent';
      }

      final profile = await userRepo.getProfile(uid);
      final yourName = profile?.displayName ?? 'You';

      final hUid = room.hostUid;
      final gUid = room.guestUid;
      final hostName =
          hUid != null ? (await userRepo.getProfile(hUid))?.displayName ?? 'Host' : 'Host';
      final guestName =
          gUid != null ? (await userRepo.getProfile(gUid))?.displayName ?? 'Guest' : 'Guest';

      final youHost = room.hostUid == uid;
      final myRuns = youHost ? room.hostRuns : room.guestRuns;
      final oppRuns = youHost ? room.guestRuns : room.hostRuns;

      final won = myRuns > oppRuns;
      final tie = myRuns == oppRuns;
      final coins = tie
          ? 35 + (myRuns ~/ 3)
          : 40 + (won ? 90 : 15) + (myRuns ~/ 3);
      final xp = tie ? 18 : (won ? 30 : 12);

      final hostBatFirst = room.hostBatFirst ?? true;
      final firstName = hostBatFirst ? hostName : guestName;
      final secondName = hostBatFirst ? guestName : hostName;
      final firstRuns = hostBatFirst ? room.hostRuns : room.guestRuns;
      final firstWkts = hostBatFirst ? room.hostWickets : room.guestWickets;
      final firstBalls = hostBatFirst ? room.hostLegalBalls : room.guestLegalBalls;
      final secondRuns = hostBatFirst ? room.guestRuns : room.hostRuns;
      final secondWkts = hostBatFirst ? room.guestWickets : room.hostWickets;
      final secondBalls = hostBatFirst ? room.guestLegalBalls : room.hostLegalBalls;

      final innings1 = InningsResult(
        teamName: firstName,
        runs: firstRuns,
        wicketsDown: firstWkts,
        legalBallsFaced: firstBalls.clamp(1, 120),
        battedFirst: true,
      );
      final innings2 = InningsResult(
        teamName: secondName,
        runs: secondRuns,
        wicketsDown: secondWkts,
        legalBallsFaced: secondBalls.clamp(1, 120),
        battedFirst: false,
      );

      final headline = tie
          ? 'MATCH TIED — $myRuns runs each'
          : (won ? '$yourName WINS' : '$oppName WINS');

      await ref.read(matchHistoryRepositoryProvider).append(
            uid,
            MatchSummary(
              matchId: '${room.roomId}_${DateTime.now().millisecondsSinceEpoch}',
              completedAt: DateTime.now(),
              opponentDisplayName: oppName,
              won: won && !tie,
              runsFor: myRuns,
              runsAgainst: oppRuns,
              coinsEarned: coins,
              xpEarned: xp,
            ),
          );

      if (profile != null) {
        await userRepo.upsertProfile(
          profile.copyWith(
            wins: profile.wins + (won && !tie ? 1 : 0),
            losses: profile.losses + (!won && !tie ? 1 : 0),
            matchesPlayed: profile.matchesPlayed + 1,
            coins: profile.coins + coins,
            rankingPoints: profile.rankingPoints + xp,
            totalRunsScored: profile.totalRunsScored + myRuns,
          ),
        );
      }

      await ref.read(matchRepositoryProvider).saveRoom(
            room.copyWith(
              status: MatchRoomStatus.completed,
              completedAt: DateTime.now(),
            ),
          );

      if (!mounted) return;
      final args = MatchResultArgs(
        youWon: won && !tie,
        innings1: innings1,
        innings2: innings2,
        headline: headline,
        coinsEarned: coins,
        xpEarned: xp,
      );
      context.pushReplacement('/match/result', extra: args);
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Future<void> _forceEndAndSave() async {
    final repo = ref.read(matchRepositoryProvider);
    final room = await repo.getRoom(widget.roomId);
    if (!mounted || room == null || room.status == MatchRoomStatus.completed) return;
    await _completeMatch(room);
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUidProvider);
    final roomAsync = ref.watch(matchRoomProvider(widget.roomId));

    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        title: const Text(
          'LIVE MATCH',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: GameColors.neon),
          onPressed: () => context.go('/'),
        ),
      ),
      body: roomAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GameColors.neon),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load room: $e', style: TextStyle(color: Colors.red.shade200)),
          ),
        ),
        data: (room) {
          if (room == null) {
            return const Center(
              child: Text('Room not found', style: TextStyle(color: Colors.white70)),
            );
          }
          if (uid == null) {
            return const Center(
              child: Text('Not signed in', style: TextStyle(color: Colors.white70)),
            );
          }

          if (room.guestUid == null || room.guestUid!.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Waiting for an opponent to join this room with the code.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (room.status != MatchRoomStatus.completed) {
              _bootstrapIfNeeded(room);
            }
          });

          final youHost = room.hostUid == uid;
          final hostLabel = youHost ? 'You (host)' : 'Host';
          final guestLabel = !youHost && room.guestUid == uid
              ? 'You (guest)'
              : (room.guestUid != null && room.guestUid!.isNotEmpty ? 'Guest' : 'Guest (open)');

          final tossed = room.hostBatFirst != null;
          final battingHost = tossed ? battingIsHost(room) : null;
          final phaseLabel = !tossed
              ? 'Starting…'
              : (room.inningsNumber == 1 ? '1st innings' : '2nd innings (chase)');
          final chase = room.chaseTarget;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Room ${room.roomCode} · ${room.pitch.name} pitch',
                style: TextStyle(
                  color: GameColors.muted.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phaseLabel +
                    (chase != null && room.inningsNumber == 2 ? ' · Target $chase' : ''),
                style: const TextStyle(color: GameColors.neon, fontWeight: FontWeight.w800),
              ),
              if (tossed && battingHost != null)
                Text(
                  'Batting: ${battingHost ? hostLabel : guestLabel}',
                  style: TextStyle(color: GameColors.muted.withValues(alpha: 0.95), fontSize: 13),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _scoreCard(
                      '$hostLabel\n${room.hostRuns}/${room.hostWickets}\n${formatOversFromBalls(room.hostLegalBalls)}',
                      GameColors.neon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _scoreCard(
                      '$guestLabel\n${room.guestRuns}/${room.guestWickets}\n${formatOversFromBalls(room.guestLegalBalls)}',
                      Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Host XI: ${room.hostPlayingXi.length} · Guest XI: ${room.guestPlayingXi.length} (auto top 11 by OVR)',
                style: TextStyle(color: GameColors.muted.withValues(alpha: 0.9), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                'Each tap runs one legal delivery for the current innings (both players can use the same device or take turns online — Firestore keeps state).',
                style: TextStyle(color: GameColors.muted.withValues(alpha: 0.95), fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _finishing ||
                        room.status == MatchRoomStatus.completed ||
                        !tossed ||
                        _busyBall
                    ? null
                    : _nextDelivery,
                style: FilledButton.styleFrom(
                  backgroundColor: GameColors.neon,
                  foregroundColor: GameColors.onNeonButton,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _busyBall
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: GameColors.onNeonButton),
                      )
                    : const Text(
                        'NEXT DELIVERY',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _finishing || room.status == MatchRoomStatus.completed
                    ? null
                    : _forceEndAndSave,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4A2C2C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _finishing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('END MATCH NOW (current scores)'),
              ),
              if (room.commentaryTail.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'COMMENTARY',
                  style: TextStyle(
                    color: GameColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ...room.commentaryTail.reversed.take(10).map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(line, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                    ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 2),
    );
  }

  static Widget _scoreCard(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: accent,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),
      ),
    );
  }
}
