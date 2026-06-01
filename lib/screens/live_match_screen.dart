import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/cricket_format.dart';
import '../data/match_delivery_engine.dart';
import '../data/models/innings_result.dart';
import '../data/models/match_result_args.dart';
import '../data/models/match_room.dart';
import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

class LiveMatchScreen extends ConsumerStatefulWidget {
  const LiveMatchScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  var _busy = false;
  var _resultOpening = false;
  String? _error;

  Future<void> _lockMyXi(MatchRoom room) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null || _busy) return;
    final isHost = room.hostUid == uid;
    final isGuest = room.guestUid == uid;
    if (!isHost && !isGuest) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(matchRepositoryProvider)
          .lockStrongestXi(roomId: room.roomId);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _nextDelivery(MatchRoom room) async {
    if (_busy || room.status != MatchRoomStatus.inProgress) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(matchRepositoryProvider)
          .advanceDelivery(roomId: room.roomId);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forceEnd(MatchRoom room) async {
    if (_busy || room.status == MatchRoomStatus.completed) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(matchRepositoryProvider)
          .forceComplete(roomId: room.roomId);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openResult(MatchRoom room) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null || _resultOpening) return;
    _resultOpening = true;
    try {
      await ref.read(matchRepositoryProvider).claimResult(roomId: room.roomId);
      if (!mounted) return;
      context.push('/match/result', extra: await _resultArgs(room, uid));
    } finally {
      _resultOpening = false;
    }
  }

  Future<MatchResultArgs> _resultArgs(MatchRoom room, String uid) async {
    final userRepo = ref.read(userRepositoryProvider);
    final hostName =
        room.hostUid == null
            ? 'Host'
            : (await userRepo.getProfile(room.hostUid!))?.displayName ?? 'Host';
    final guestName =
        room.guestUid == null
            ? 'Guest'
            : (await userRepo.getProfile(room.guestUid!))?.displayName ??
                'Guest';
    final hostFirst = room.hostBatFirst ?? true;
    final stats = _rewardStats(room, uid);
    final firstName = hostFirst ? hostName : guestName;
    final secondName = hostFirst ? guestName : hostName;
    return MatchResultArgs(
      youWon: stats.won,
      headline:
          stats.tie
              ? 'MATCH TIED - ${stats.runsFor} runs each'
              : (stats.won ? 'YOU WIN' : 'YOU LOSE'),
      coinsEarned: stats.coins,
      xpEarned: stats.xp,
      innings1: InningsResult(
        teamName: firstName,
        runs: hostFirst ? room.hostRuns : room.guestRuns,
        wicketsDown: hostFirst ? room.hostWickets : room.guestWickets,
        legalBallsFaced: (hostFirst
                ? room.hostLegalBalls
                : room.guestLegalBalls)
            .clamp(1, 120),
        battedFirst: true,
      ),
      innings2: InningsResult(
        teamName: secondName,
        runs: hostFirst ? room.guestRuns : room.hostRuns,
        wicketsDown: hostFirst ? room.guestWickets : room.hostWickets,
        legalBallsFaced: (hostFirst
                ? room.guestLegalBalls
                : room.hostLegalBalls)
            .clamp(1, 120),
        battedFirst: false,
      ),
    );
  }

  _RewardStats _rewardStats(MatchRoom room, String uid) {
    final youHost = room.hostUid == uid;
    final runsFor = youHost ? room.hostRuns : room.guestRuns;
    final runsAgainst = youHost ? room.guestRuns : room.hostRuns;
    final tie = runsFor == runsAgainst;
    final won = !tie && runsFor > runsAgainst;
    final coins =
        tie ? 35 + (runsFor ~/ 3) : 40 + (won ? 90 : 15) + (runsFor ~/ 3);
    final xp = tie ? 18 : (won ? 30 : 12);
    return _RewardStats(
      runsFor: runsFor,
      runsAgainst: runsAgainst,
      won: won,
      tie: tie,
      coins: coins,
      xp: xp,
    );
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
          onPressed: () => context.go('/matches'),
        ),
      ),
      body: roomAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: GameColors.neon),
            ),
        error:
            (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load room: $e',
                  style: TextStyle(color: Colors.red.shade200),
                ),
              ),
            ),
        data: (room) {
          if (room == null) {
            return const Center(
              child: Text(
                'Room not found',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          if (uid == null) {
            return const Center(
              child: Text(
                'Not signed in',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          final isParticipant = room.hostUid == uid || room.guestUid == uid;
          final youHost = room.hostUid == uid;
          final myLocked = youHost ? room.hostXiLocked : room.guestXiLocked;
          final phaseLabel = _phaseLabel(room);
          final battingHost =
              room.hostBatFirst == null ? null : battingIsHost(room);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade200, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Room ${room.roomCode} - ${room.pitch.name} pitch',
                style: TextStyle(
                  color: GameColors.muted.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phaseLabel,
                style: const TextStyle(
                  color: GameColors.neon,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (battingHost != null)
                Text(
                  'Batting: ${battingHost ? 'Host' : 'Guest'}',
                  style: TextStyle(
                    color: GameColors.muted.withValues(alpha: 0.95),
                    fontSize: 13,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _scoreCard(
                      'Host\n${room.hostRuns}/${room.hostWickets}\n${formatOversFromBalls(room.hostLegalBalls)}',
                      youHost ? GameColors.neon : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _scoreCard(
                      'Guest\n${room.guestRuns}/${room.guestWickets}\n${formatOversFromBalls(room.guestLegalBalls)}',
                      !youHost && room.guestUid == uid
                          ? GameColors.neon
                          : Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _lockStatus(room),
              const SizedBox(height: 16),
              if (!isParticipant)
                const Text(
                  'Viewer mode: watch the live scoreboard and commentary.',
                  style: TextStyle(color: Colors.white70),
                )
              else if (room.guestUid == null || room.guestUid!.isEmpty)
                const Text(
                  'Waiting for the opponent to join with this room code.',
                  style: TextStyle(color: Colors.white70),
                )
              else if (room.status == MatchRoomStatus.completed)
                FilledButton(
                  onPressed: _busy ? null : () => _openResult(room),
                  style: FilledButton.styleFrom(
                    backgroundColor: GameColors.neon,
                    foregroundColor: GameColors.onNeonButton,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text(
                    'VIEW RESULT',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                )
              else if (!myLocked)
                FilledButton(
                  onPressed: _busy ? null : () => _lockMyXi(room),
                  style: FilledButton.styleFrom(
                    backgroundColor: GameColors.neon,
                    foregroundColor: GameColors.onNeonButton,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text(
                    'LOCK STRONGEST XI',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                )
              else if (!room.hostXiLocked || !room.guestXiLocked)
                const Text(
                  'Your XI is locked. Waiting for the other player.',
                  style: TextStyle(color: Colors.white70),
                )
              else ...[
                FilledButton(
                  onPressed:
                      _busy || room.hostBatFirst == null
                          ? null
                          : () => _nextDelivery(room),
                  style: FilledButton.styleFrom(
                    backgroundColor: GameColors.neon,
                    foregroundColor: GameColors.onNeonButton,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child:
                      _busy
                          ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: GameColors.onNeonButton,
                            ),
                          )
                          : const Text(
                            'NEXT DELIVERY',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : () => _forceEnd(room),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade200,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('END MATCH NOW'),
                ),
              ],
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
                ...room.commentaryTail.reversed
                    .take(12)
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          line,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
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

  static String _phaseLabel(MatchRoom room) {
    if (room.status == MatchRoomStatus.completed) return 'Completed';
    if (room.guestUid == null || room.guestUid!.isEmpty) {
      return 'Waiting for guest';
    }
    if (!room.hostXiLocked || !room.guestXiLocked) return 'Selecting XI';
    if (room.hostBatFirst == null) return 'Starting match';
    final target = room.chaseTarget;
    return room.inningsNumber == 1
        ? '1st innings'
        : '2nd innings${target == null ? '' : ' - Target $target'}';
  }

  static Widget _lockStatus(MatchRoom room) {
    return Row(
      children: [
        Expanded(
          child: _pill(
            'Host XI',
            room.hostXiLocked
                ? '${room.hostPlayingXi.length}/11 locked'
                : 'Not locked',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _pill(
            'Guest XI',
            room.guestXiLocked
                ? '${room.guestPlayingXi.length}/11 locked'
                : 'Not locked',
          ),
        ),
      ],
    );
  }

  static Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: GameColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
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
