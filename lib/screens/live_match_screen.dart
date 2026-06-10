import 'dart:async';

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

  Timer? _autoTimer;
  bool get _autoPlaying => _autoTimer != null;

  /// Drives the per-delivery countdown and CPU auto-fill when a side stalls.
  Timer? _ticker;

  /// Seconds each side gets to lock a pick before CPU fills the gap.
  static const int _choiceWindowSecs = 20;

  /// The server deadline value we are currently counting against, plus the
  /// local time we first observed it. Measuring elapsed time locally (instead
  /// of trusting the server's absolute timestamp) keeps the countdown reliable
  /// even when the phone clock is skewed from the server clock.
  int? _windowKey;
  DateTime? _windowStart;

  String? _hostName;
  String? _guestName;
  String _namesKey = '';

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker(MatchRoom room) {
    _syncWindow(room);
    final live = room.status == MatchRoomStatus.inProgress &&
        room.hostBatFirst != null;
    if (live && _ticker == null) {
      _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _onTick();
      });
    } else if (!live && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  /// Reset the local countdown whenever the server opens a new choice window
  /// (i.e. the deadline value changes after a delivery resolves).
  void _syncWindow(MatchRoom room) {
    final key = room.choiceDeadlineMs;
    if (key != _windowKey) {
      _windowKey = key;
      _windowStart = key == null ? null : DateTime.now();
    }
  }

  void _onTick() {
    if (!mounted) return;
    final room = ref.read(matchRoomProvider(widget.roomId)).valueOrNull;
    if (room == null || room.status != MatchRoomStatus.inProgress) {
      if (mounted) setState(() {});
      return;
    }
    _syncWindow(room);
    final uid = ref.read(currentUidProvider);
    final isParticipant = uid != null &&
        (room.hostUid == uid || room.guestUid == uid);
    final secs = _secondsLeft(room);
    // Once this client's local window lapses, ask the server to resolve the
    // ball — CPU fills whichever side didn't lock a pick in time. Measuring
    // locally avoids clock-skew instantly timing out the room creator.
    if (!_autoPlaying &&
        !_busy &&
        isParticipant &&
        secs != null &&
        secs <= 0) {
      _submitChoice(room, force: true);
      return;
    }
    if (mounted) setState(() {});
  }

  void _ensureNames(MatchRoom room) {
    final key = '${room.hostUid}_${room.guestUid}';
    if (_namesKey == key) return;
    _namesKey = key;
    unawaited(_loadNames(room));
  }

  Future<void> _loadNames(MatchRoom room) async {
    final userRepo = ref.read(userRepositoryProvider);
    String? h;
    String? g;
    if (room.hostUid != null && room.hostUid!.isNotEmpty) {
      h = (await userRepo.getProfile(room.hostUid!))?.displayName;
    }
    if (room.guestUid != null && room.guestUid!.isNotEmpty) {
      g = (await userRepo.getProfile(room.guestUid!))?.displayName;
    }
    if (!mounted) return;
    setState(() {
      _hostName = h;
      _guestName = g;
    });
  }

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

  Future<void> _nextDelivery(MatchRoom room, {String? shot, String? bowl}) async {
    if (_busy || room.status != MatchRoomStatus.inProgress) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(matchRepositoryProvider)
          .advanceDelivery(roomId: room.roomId, shot: shot, bowl: bowl);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _localBatting(MatchRoom room, String uid) {
    if (room.hostBatFirst == null) return true;
    final youHost = room.hostUid == uid;
    return youHost == battingIsHost(room);
  }

  /// Lock this player's pick for the pending delivery (handshake path).
  Future<void> _submitChoice(
    MatchRoom room, {
    String? shot,
    String? bowl,
    bool force = false,
  }) async {
    if (_busy || room.status != MatchRoomStatus.inProgress) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(matchRepositoryProvider).submitChoice(
            roomId: room.roomId,
            shot: shot,
            bowl: bowl,
            force: force,
          );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _playChoice(MatchRoom room, bool batting, String value) {
    _submitChoice(
      room,
      shot: batting ? value : null,
      bowl: batting ? null : value,
    );
  }

  void _toggleAutoPlay() {
    if (_autoTimer != null) {
      _autoTimer!.cancel();
      setState(() => _autoTimer = null);
      return;
    }
    setState(() {
      _autoTimer = Timer.periodic(const Duration(milliseconds: 1100), (t) {
        final room = ref.read(matchRoomProvider(widget.roomId)).valueOrNull;
        if (room == null ||
            room.status != MatchRoomStatus.inProgress ||
            room.hostBatFirst == null) {
          t.cancel();
          if (mounted) setState(() => _autoTimer = null);
          return;
        }
        if (!_busy) _nextDelivery(room);
      });
    });
  }

  void _stopAutoPlay() {
    if (_autoTimer == null) return;
    _autoTimer!.cancel();
    _autoTimer = null;
  }

  Future<void> _forceEnd(MatchRoom room) async {
    if (_busy || room.status == MatchRoomStatus.completed) return;
    _stopAutoPlay();
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
    final hostName = _hostName ?? 'Host';
    final guestName = _guestName ?? 'Guest';
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
            .clamp(1, room.maxBalls),
        battedFirst: true,
      ),
      innings2: InningsResult(
        teamName: secondName,
        runs: hostFirst ? room.guestRuns : room.hostRuns,
        wicketsDown: hostFirst ? room.guestWickets : room.hostWickets,
        legalBallsFaced: (hostFirst
                ? room.guestLegalBalls
                : room.hostLegalBalls)
            .clamp(1, room.maxBalls),
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
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'LIVE MATCH',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: GameColors.neon),
          onPressed: () => _confirmExit(),
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
          _ensureNames(room);
          _syncTicker(room);
          final inMatch =
              room.hostBatFirst != null &&
              (room.status == MatchRoomStatus.inProgress ||
                  room.status == MatchRoomStatus.completed);
          if (room.status == MatchRoomStatus.completed) _stopAutoPlay();
          return inMatch
              ? _matchView(room, uid)
              : _preMatchView(room, uid);
        },
      ),
    );
  }

  Future<void> _confirmExit() async {
    if (!_autoPlaying) {
      if (mounted) context.go('/matches');
      return;
    }
    _stopAutoPlay();
    if (mounted) context.go('/matches');
  }

  // ----- PRE-MATCH (lobby / XI lock) -----

  Widget _preMatchView(MatchRoom room, String uid) {
    final youHost = room.hostUid == uid;
    final isParticipant = room.hostUid == uid || room.guestUid == uid;
    final myLocked = youHost ? room.hostXiLocked : room.guestXiLocked;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null) ...[
          _errorBox(_error!),
          const SizedBox(height: 12),
        ],
        _metaLine(room),
        const SizedBox(height: 8),
        Text(
          _phaseLabel(room),
          style: const TextStyle(
            color: GameColors.neon,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        _lockStatus(room),
        const SizedBox(height: 20),
        if (!isParticipant)
          const Text(
            'Viewer mode: watch the live scoreboard and commentary.',
            style: TextStyle(color: Colors.white70),
          )
        else if (room.guestUid == null || room.guestUid!.isEmpty)
          const _Hint('Waiting for the opponent to join with this room code.')
        else if (!myLocked)
          _primaryButton(
            label: 'LOCK STRONGEST XI',
            onPressed: _busy ? null : () => _lockMyXi(room),
            busy: _busy,
          )
        else
          const _Hint('Your XI is locked. Waiting for the other player.'),
      ],
    );
  }

  // ----- IN-MATCH (tabbed) -----

  Widget _matchView(MatchRoom room, String uid) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _scoreboard(room, uid),
          Container(
            color: GameColors.bg,
            child: const TabBar(
              indicatorColor: GameColors.neon,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: GameColors.muted,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
              tabs: [
                Tab(text: 'LIVE'),
                Tab(text: 'COMMENTARY'),
                Tab(text: 'SCORECARD'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _liveTab(room, uid),
                _commentaryTab(room),
                _scorecardTab(room),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreboard(MatchRoom room, String uid) {
    final hostName = _hostName ?? 'Host';
    final guestName = _guestName ?? 'Guest';
    final battingHost = room.hostBatFirst == null ? true : battingIsHost(room);
    final battingName = battingHost ? hostName : guestName;
    final bowlingName = battingHost ? guestName : hostName;
    final runs = battingHost ? room.hostRuns : room.guestRuns;
    final wkts = battingHost ? room.hostWickets : room.guestWickets;
    final balls = battingHost ? room.hostLegalBalls : room.guestLegalBalls;
    final crr = balls == 0 ? 0.0 : runs / (balls / 6);
    final completed = room.status == MatchRoomStatus.completed;
    final isChase = room.inningsNumber == 2 && room.chaseTarget != null;
    final need = isChase ? (room.chaseTarget! - runs) : 0;
    final ballsLeft = (room.maxBalls - balls).clamp(0, room.maxBalls);
    final rrr =
        isChase && ballsLeft > 0 && need > 0 ? (need / ballsLeft) * 6 : 0.0;

    final youBatting = (battingHost && room.hostUid == uid) ||
        (!battingHost && room.guestUid == uid);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GameColors.neon.withValues(alpha: 0.16), GameColors.card],
        ),
        border: const Border(
          bottom: BorderSide(color: GameColors.neon, width: 2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _phasePill(completed ? 'RESULT' : _phaseLabel(room)),
              const Spacer(),
              Text(
                '${room.oversPerInnings} ov · ${room.pitch.name}',
                style: TextStyle(
                  color: GameColors.muted.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  battingName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: youBatting ? GameColors.neon : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (youBatting)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: _Badge('YOU'),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$runs/$wkts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '(${formatOversFromBalls(balls)}/${room.oversPerInnings})',
                style: TextStyle(
                  color: GameColors.muted.withValues(alpha: 0.95),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'CRR ${crr.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isChase) ...[
                const SizedBox(width: 12),
                Text(
                  'RRR ${rrr.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: rrr >= 10 ? Colors.amber : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'vs $bowlingName',
                style: TextStyle(
                  color: GameColors.muted.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (isChase && !completed) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: GameColors.bg.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GameColors.cardBorder),
              ),
              child: Text(
                need <= 0
                    ? 'Target reached!'
                    : 'Need $need run${need == 1 ? '' : 's'} off $ballsLeft ball${ballsLeft == 1 ? '' : 's'} · Target ${room.chaseTarget}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ----- LIVE TAB -----

  Widget _liveTab(MatchRoom room, String uid) {
    final isParticipant = room.hostUid == uid || room.guestUid == uid;
    final completed = room.status == MatchRoomStatus.completed;
    final recent = _recentBalls(room);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null) ...[
          _errorBox(_error!),
          const SizedBox(height: 12),
        ],
        const Text(
          'THIS OVER',
          style: TextStyle(
            color: GameColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Text(
            completed ? 'Match finished.' : 'No deliveries yet.',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final b in recent) _ballChip(b)],
          ),
        const SizedBox(height: 20),
        if (completed)
          _primaryButton(
            label: 'VIEW RESULT',
            onPressed: _busy ? null : () => _openResult(room),
            busy: false,
          )
        else if (isParticipant) ...[
          if (_autoPlaying)
            _primaryButton(
              label: 'PAUSE SIMULATION',
              icon: Icons.pause_rounded,
              onPressed: _toggleAutoPlay,
              busy: false,
            )
          else ...[
            _choicePanel(room, uid),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: room.hostBatFirst == null ? null : _toggleAutoPlay,
                    icon: const Icon(Icons.fast_forward_rounded, size: 18),
                    label: const Text('AUTO SIM'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GameColors.neon,
                      side: const BorderSide(color: GameColors.neon),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: _busy ? null : () => _forceEnd(room),
                    child: Text(
                      'End match',
                      style: TextStyle(color: Colors.red.shade200),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ] else
          const Text(
            'Viewer mode: watch the live scoreboard and commentary.',
            style: TextStyle(color: Colors.white70),
          ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(color: GameColors.cardBorder, height: 1),
          const SizedBox(height: 16),
          const Text(
            'LATEST',
            style: TextStyle(
              color: GameColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          ...room.commentaryTail.reversed
              .take(4)
              .map((line) => _commentaryLine(line, compact: true)),
        ],
      ],
    );
  }

  Widget _choicePanel(MatchRoom room, String uid) {
    if (room.hostBatFirst == null) {
      return const Text(
        'Match starting…',
        style: TextStyle(color: Colors.white54),
      );
    }
    final batting = _localBatting(room, uid);
    final options = batting ? _shotOptions : _bowlOptions;
    final myChoice = batting ? room.pendingShot : room.pendingBowl;
    final oppChoice = batting ? room.pendingBowl : room.pendingShot;
    final locked = myChoice != null;
    final secs = _secondsLeft(room);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              batting
                  ? Icons.sports_cricket_rounded
                  : Icons.sports_baseball_rounded,
              color: GameColors.neon,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                batting ? 'CHOOSE YOUR SHOT' : 'CHOOSE YOUR DELIVERY',
                style: const TextStyle(
                  color: GameColors.neon,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            if (secs != null) _countdownChip(secs),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          batting
              ? 'Both sides pick at once — counter the bowler.'
              : 'Both sides pick at once — beat the batter.',
          style: TextStyle(
            color: GameColors.muted.withValues(alpha: 0.9),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        if (locked)
          _waitingForOpponent(batting, myChoice, oppChoice != null, secs)
        else ...[
          Row(
            children: [
              Expanded(child: _choiceTile(room, batting, options[0], false)),
              const SizedBox(width: 10),
              Expanded(child: _choiceTile(room, batting, options[1], false)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _choiceTile(room, batting, options[2], false)),
              const SizedBox(width: 10),
              Expanded(child: _choiceTile(room, batting, options[3], false)),
            ],
          ),
          const SizedBox(height: 8),
          _opponentStatus(oppChoice != null),
        ],
      ],
    );
  }

  Widget _countdownChip(int secs) {
    final hot = secs <= 5;
    final color = hot ? Colors.amber : GameColors.neon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            '${secs}s',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _opponentStatus(bool oppReady) {
    return Row(
      children: [
        Icon(
          oppReady ? Icons.check_circle_rounded : Icons.more_horiz_rounded,
          size: 14,
          color: oppReady ? GameColors.neon : GameColors.muted,
        ),
        const SizedBox(width: 6),
        Text(
          oppReady ? 'Opponent locked in' : 'Opponent is choosing…',
          style: TextStyle(
            color: oppReady ? GameColors.neon : GameColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _waitingForOpponent(
    bool batting,
    String myChoiceValue,
    bool oppReady,
    int? secs,
  ) {
    final opt = (batting ? _shotOptions : _bowlOptions).firstWhere(
      (o) => o.value == myChoiceValue,
      orElse: () => batting ? _shotOptions.first : _bowlOptions.first,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GameColors.neon),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(opt.icon, color: GameColors.neon, size: 20),
              const SizedBox(width: 8),
              Text(
                'You locked: ${opt.label}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GameColors.neon,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  oppReady
                      ? 'Both locked — playing the ball…'
                      : (secs != null
                          ? 'Waiting for opponent… auto-picks in ${secs}s'
                          : 'Waiting for opponent…'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Seconds left in the current choice window (`null` if no live window).
  /// Counted from when this client first saw the window open, so a skewed
  /// device clock can't make the timer expire instantly.
  int? _secondsLeft(MatchRoom room) {
    if (room.choiceDeadlineMs == null || _windowStart == null) return null;
    final elapsedMs = DateTime.now().difference(_windowStart!).inMilliseconds;
    final leftMs = _choiceWindowSecs * 1000 - elapsedMs;
    return (leftMs / 1000).ceil().clamp(0, _choiceWindowSecs);
  }

  Widget _choiceTile(
    MatchRoom room,
    bool batting,
    _ChoiceOption opt,
    bool disabled,
  ) {
    final off = disabled || _busy;
    return InkWell(
      onTap: off ? null : () => _playChoice(room, batting, opt.value),
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: off ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: GameColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GameColors.neon.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Icon(opt.icon, color: GameColors.neon, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      opt.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: GameColors.muted.withValues(alpha: 0.9),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- COMMENTARY TAB -----

  Widget _commentaryTab(MatchRoom room) {
    if (room.commentaryTail.isEmpty) {
      return const Center(
        child: Text(
          'Commentary will appear here once the match starts.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    final lines = room.commentaryTail.reversed.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: lines.length,
      itemBuilder: (context, i) => _commentaryLine(lines[i]),
    );
  }

  Widget _commentaryLine(String line, {bool compact = false}) {
    final isSeparator =
        line.startsWith('--') || line.startsWith('—') || line.startsWith('Toss');
    final isWicket = line.contains('OUT!');
    final isBoundary =
        line.endsWith(': 4') || line.endsWith(': 6') || line.contains(': 6 ');

    if (isSeparator) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Expanded(child: Divider(color: GameColors.cardBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                line.replaceAll('--', '').replaceAll('—', '').trim(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GameColors.neon.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Expanded(child: Divider(color: GameColors.cardBorder)),
          ],
        ),
      );
    }

    final accent = isWicket
        ? Colors.red.shade300
        : (isBoundary ? GameColors.neon : Colors.white70);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5, right: 10),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              line,
              style: TextStyle(
                color: isWicket || isBoundary ? accent : Colors.white70,
                fontSize: 13,
                fontWeight:
                    isWicket || isBoundary ? FontWeight.w800 : FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----- SCORECARD TAB -----

  Widget _scorecardTab(MatchRoom room) {
    final hostName = _hostName ?? 'Host';
    final guestName = _guestName ?? 'Guest';
    final hostFirst = room.hostBatFirst ?? true;
    final firstName = hostFirst ? hostName : guestName;
    final secondName = hostFirst ? guestName : hostName;
    final firstRuns = hostFirst ? room.hostRuns : room.guestRuns;
    final firstWkts = hostFirst ? room.hostWickets : room.guestWickets;
    final firstBalls = hostFirst ? room.hostLegalBalls : room.guestLegalBalls;
    final secondRuns = hostFirst ? room.guestRuns : room.hostRuns;
    final secondWkts = hostFirst ? room.guestWickets : room.hostWickets;
    final secondBalls = hostFirst ? room.guestLegalBalls : room.hostLegalBalls;
    final firstXi = hostFirst ? room.hostPlayingXi : room.guestPlayingXi;
    final secondXi = hostFirst ? room.guestPlayingXi : room.hostPlayingXi;
    final secondStarted = room.inningsNumber == 2 || secondBalls > 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _inningsCard(
          title: '1st Innings',
          team: firstName,
          runs: firstRuns,
          wkts: firstWkts,
          balls: firstBalls,
          maxOvers: room.oversPerInnings,
          xiCount: firstXi.length,
          active: room.inningsNumber == 1 &&
              room.status == MatchRoomStatus.inProgress,
        ),
        const SizedBox(height: 14),
        if (secondStarted)
          _inningsCard(
            title: '2nd Innings',
            team: secondName,
            runs: secondRuns,
            wkts: secondWkts,
            balls: secondBalls,
            maxOvers: room.oversPerInnings,
            xiCount: secondXi.length,
            active: room.inningsNumber == 2 &&
                room.status == MatchRoomStatus.inProgress,
            target: room.chaseTarget,
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GameColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GameColors.cardBorder),
            ),
            child: Text(
              '$secondName bats second — yet to begin.',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: GameColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GameColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metaRow(
                'Format',
                '${room.oversPerInnings} ${room.oversPerInnings == 1 ? 'over' : 'overs'} a side',
              ),
              const SizedBox(height: 6),
              _metaRow('Pitch', _capitalize(room.pitch.name)),
              const SizedBox(height: 6),
              _metaRow('Status', _phaseLabel(room)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inningsCard({
    required String title,
    required String team,
    required int runs,
    required int wkts,
    required int balls,
    required int maxOvers,
    required int xiCount,
    required bool active,
    int? target,
  }) {
    final rr = balls == 0 ? 0.0 : runs / (balls / 6);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? GameColors.neon : GameColors.cardBorder,
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: GameColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (active) const _Badge('LIVE'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            team,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$runs/$wkts',
                style: const TextStyle(
                  color: GameColors.neon,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${formatOversFromBalls(balls)}/$maxOvers ov)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Run rate ${rr.toStringAsFixed(2)}'
            '${target != null ? ' · Target $target' : ''}'
            ' · $xiCount players',
            style: TextStyle(
              color: GameColors.muted.withValues(alpha: 0.95),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ----- shared bits -----

  List<_Ball> _recentBalls(MatchRoom room) {
    final out = <_Ball>[];
    for (final code in room.recentBalls) {
      if (code == 'W') {
        out.add(const _Ball(runs: 0, wicket: true));
      } else {
        final n = int.tryParse(code);
        if (n != null) out.add(_Ball(runs: n, wicket: false));
      }
    }
    if (out.length <= 6) return out;
    return out.sublist(out.length - 6);
  }

  Widget _ballChip(_Ball b) {
    final Color color;
    final String label;
    if (b.wicket) {
      color = Colors.red.shade400;
      label = 'W';
    } else if (b.runs == 0) {
      color = GameColors.muted;
      label = '•';
    } else if (b.runs >= 6) {
      color = GameColors.neon;
      label = '6';
    } else if (b.runs == 4) {
      color = Colors.lightBlueAccent;
      label = '4';
    } else {
      color = Colors.white70;
      label = '${b.runs}';
    }
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _metaLine(MatchRoom room) {
    return Text(
      'Room ${room.roomCode} · ${room.oversPerInnings} ${room.oversPerInnings == 1 ? 'over' : 'overs'} · '
      '${room.pitch.name} pitch',
      style: TextStyle(
        color: GameColors.muted.withValues(alpha: 0.9),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: GameColors.muted, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool busy = false,
    IconData? icon,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: GameColors.onNeonButton,
              ),
            )
          : (icon != null ? Icon(icon) : const SizedBox.shrink()),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: GameColors.neon,
        foregroundColor: GameColors.onNeonButton,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.red.shade200, fontSize: 13),
      ),
    );
  }

  Widget _phasePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: GameColors.neon.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameColors.neon.withValues(alpha: 0.6)),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: GameColors.neon,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _phaseLabel(MatchRoom room) {
    if (room.status == MatchRoomStatus.completed) {
      final h = room.hostRuns;
      final g = room.guestRuns;
      if (h == g) return 'Match tied';
      final hostWon = h > g;
      final winner = hostWon ? (_hostName ?? 'Host') : (_guestName ?? 'Guest');
      return '$winner won';
    }
    if (room.guestUid == null || room.guestUid!.isEmpty) {
      return 'Waiting for guest';
    }
    if (!room.hostXiLocked || !room.guestXiLocked) return 'Selecting XI';
    if (room.hostBatFirst == null) return 'Starting match';
    final target = room.chaseTarget;
    return room.inningsNumber == 1
        ? '1st innings'
        : '2nd innings${target == null ? '' : ' · chasing $target'}';
  }

  Widget _lockStatus(MatchRoom room) {
    return Row(
      children: [
        Expanded(
          child: _pill(
            'Host XI',
            room.hostXiLocked
                ? '${room.hostPlayingXi.length}/11 locked'
                : 'Not locked',
            room.hostXiLocked,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _pill(
            'Guest XI',
            room.guestXiLocked
                ? '${room.guestPlayingXi.length}/11 locked'
                : 'Not locked',
            room.guestXiLocked,
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, String value, bool ready) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ready ? GameColors.neon : GameColors.cardBorder,
        ),
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
            style: TextStyle(
              color: ready ? GameColors.neon : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Ball {
  const _Ball({required this.runs, required this.wicket});
  final int runs;
  final bool wicket;
}

class _ChoiceOption {
  const _ChoiceOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.hint,
  });
  final String value;
  final String label;
  final IconData icon;
  final String hint;
}

const List<_ChoiceOption> _shotOptions = [
  _ChoiceOption(
    value: 'block',
    label: 'Block',
    icon: Icons.shield_rounded,
    hint: 'Safe, few runs',
  ),
  _ChoiceOption(
    value: 'drive',
    label: 'Drive',
    icon: Icons.sports_cricket_rounded,
    hint: 'Balanced, finds 4s',
  ),
  _ChoiceOption(
    value: 'loft',
    label: 'Loft',
    icon: Icons.rocket_launch_rounded,
    hint: 'Big 6s, risky',
  ),
  _ChoiceOption(
    value: 'pull',
    label: 'Pull',
    icon: Icons.swipe_left_rounded,
    hint: 'Great vs short',
  ),
];

const List<_ChoiceOption> _bowlOptions = [
  _ChoiceOption(
    value: 'pace',
    label: 'Pace',
    icon: Icons.speed_rounded,
    hint: 'Length ball',
  ),
  _ChoiceOption(
    value: 'bouncer',
    label: 'Bouncer',
    icon: Icons.arrow_upward_rounded,
    hint: 'Short, hurries batter',
  ),
  _ChoiceOption(
    value: 'yorker',
    label: 'Yorker',
    icon: Icons.vertical_align_bottom_rounded,
    hint: 'Chokes runs',
  ),
  _ChoiceOption(
    value: 'spin',
    label: 'Spin',
    icon: Icons.cyclone_rounded,
    hint: 'Tempts the loft',
  ),
];

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: GameColors.neon,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: GameColors.onNeonButton,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
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
