import 'dart:math';

import 'cricket_format.dart';
import 'match_simulation.dart';
import 'models/cricket_player.dart';
import 'models/match_room.dart';

/// Who faces this innings (once [MatchRoom.hostBatFirst] is set).
bool battingIsHost(MatchRoom r) {
  final h = r.hostBatFirst;
  if (h == null) return true;
  return r.inningsNumber == 1 ? h : !h;
}

/// Apply one legal delivery; returns `null` if the striker's innings is already over or match not ready.
MatchRoom? applyOneDelivery(
  MatchRoom room,
  Random rng, {
  List<CricketPlayer> hostPlayers = const [],
  List<CricketPlayer> guestPlayers = const [],
  String? shot,
  String? bowl,
}) {
  if (room.status == MatchRoomStatus.completed) return null;
  if (room.hostBatFirst == null) return null;

  final battingHost = battingIsHost(room);
  final br = battingHost ? room.hostRuns : room.guestRuns;
  final bw = battingHost ? room.hostWickets : room.guestWickets;
  final bb = battingHost ? room.hostLegalBalls : room.guestLegalBalls;

  if (bw >= 10 || bb >= room.maxBalls) return null;

  final isChase = room.inningsNumber == 2;
  final ballsLeft = (room.maxBalls - bb).clamp(1, room.maxBalls);
  final rrr = isChase && room.chaseTarget != null
      ? ((room.chaseTarget! - br) / ballsLeft) * 6
      : 0.0;
  final bowlType = kBallTypes.contains(bowl)
      ? bowl!
      : _cpuBowl(rng, bb, room.maxBalls);
  final shotType = kShotTypes.contains(shot)
      ? shot!
      : _cpuShot(rng, bw, isChase, rrr);

  if (room.inningsNumber == 2 &&
      room.chaseTarget != null &&
      br >= room.chaseTarget!) {
    return null;
  }

  final battingLineup = battingHost ? hostPlayers : guestPlayers;
  final bowlingLineup = battingHost ? guestPlayers : hostPlayers;
  final batter = _selectBatter(battingLineup, bw, bb);
  final bowler = _selectBowler(bowlingLineup, bb);

  final ctx = SimBallContext(
    pitch: room.pitch,
    maxBalls: room.maxBalls,
    bowlType: bowlType,
    shotType: shotType,
    legalBallsInInnings: bb,
    wicketsDown: bw,
    runsScoredThisInnings: br,
    isChaseInnings: room.inningsNumber == 2,
    chaseTarget: room.chaseTarget,
    battingRating:
        batter?.attributes.batting ??
        _averageRating(battingLineup, (p) => p.attributes.batting),
    bowlingRating:
        bowler?.attributes.bowling ??
        _averageRating(bowlingLineup, (p) => p.attributes.bowling),
    fieldingRating: _averageRating(bowlingLineup, (p) => p.attributes.fielding),
    staminaRating:
        batter?.attributes.stamina ??
        _averageRating(battingLineup, (p) => p.attributes.stamina),
    consistencyRating:
        batter?.attributes.consistency ??
        _averageRating(battingLineup, (p) => p.attributes.consistency),
  );

  final sim = simulateBall(ctx, rng);
  final runs = sim.runs;
  final wicket = sim.wicket;

  var hr = room.hostRuns;
  var gr = room.guestRuns;
  var hw = room.hostWickets;
  var gw = room.guestWickets;
  var hb = room.hostLegalBalls;
  var gb = room.guestLegalBalls;

  if (battingHost) {
    hr += runs;
    hw += wicket;
    hb += 1;
  } else {
    gr += runs;
    gw += wicket;
    gb += 1;
  }

  final who = battingHost ? 'Host' : 'Guest';
  final over = formatOversFromBalls(battingHost ? hb : gb);
  final batterName = batter?.displayName ?? who;
  final bowlerName = bowler?.displayName;
  final line =
      '$over · $batterName ($shotType)${bowlerName == null ? '' : ' vs $bowlerName'} ($bowlType): ${runs > 0 ? '$runs' : 'dot'}${wicket > 0 ? ' · OUT!' : ''}';

  var inn = room.inningsNumber;
  var target = room.chaseTarget;
  var tail = [...room.commentaryTail, line];
  if (tail.length > 30) tail = tail.sublist(tail.length - 30);

  var recent = [...room.recentBalls, wicket > 0 ? 'W' : '$runs'];
  if (recent.length > 12) recent = recent.sublist(recent.length - 12);

  final newBr = battingHost ? hr : gr;
  final newBw = battingHost ? hw : gw;
  final newBb = battingHost ? hb : gb;

  if (inn == 1 && (newBw >= 10 || newBb >= room.maxBalls)) {
    target = newBr + 1;
    inn = 2;
    recent = [];
    tail = [...tail, '— End of 1st innings ($newBr/$newBw). Target: $target —'];
    if (tail.length > 30) tail = tail.sublist(tail.length - 30);
  }

  return room.copyWith(
    hostRuns: hr,
    guestRuns: gr,
    hostWickets: hw,
    guestWickets: gw,
    hostLegalBalls: hb,
    guestLegalBalls: gb,
    inningsNumber: inn,
    chaseTarget: target,
    deliveryNumber: room.deliveryNumber + 1,
    commentaryTail: tail,
    recentBalls: recent,
  );
}

String _cpuBowl(Random rng, int legalBalls, int maxBalls) {
  final death = legalBalls >= maxBalls * 0.75;
  return _weighted(rng, [
    ('pace', death ? 2 : 3),
    ('bouncer', death ? 3 : 2),
    ('yorker', death ? 4 : 2),
    ('spin', 3),
  ]);
}

String _cpuShot(Random rng, int wicketsDown, bool isChase, double rrr) {
  if (isChase && rrr >= 10) {
    return _weighted(rng, [
      ('loft', 4),
      ('pull', 3),
      ('drive', 2),
      ('block', 1),
    ]);
  }
  if (wicketsDown >= 7) {
    return _weighted(rng, [
      ('block', 4),
      ('drive', 3),
      ('pull', 1),
      ('loft', 1),
    ]);
  }
  return _weighted(rng, [
    ('drive', 4),
    ('pull', 2),
    ('block', 2),
    ('loft', 2),
  ]);
}

String _weighted(Random rng, List<(String, int)> options) {
  final total = options.fold<int>(0, (a, o) => a + o.$2);
  var u = rng.nextDouble() * total;
  for (final o in options) {
    u -= o.$2;
    if (u <= 0) return o.$1;
  }
  return options.last.$1;
}

CricketPlayer? _selectBatter(
  List<CricketPlayer> lineup,
  int wicketsDown,
  int balls,
) {
  if (lineup.isEmpty) return null;
  final index = wicketsDown.clamp(0, lineup.length - 1);
  if (balls < 6 && lineup.length > 1) return lineup[balls.isEven ? 0 : 1];
  return lineup[index];
}

CricketPlayer? _selectBowler(List<CricketPlayer> lineup, int balls) {
  if (lineup.isEmpty) return null;
  final sorted = [...lineup]
    ..sort((a, b) => b.attributes.bowling.compareTo(a.attributes.bowling));
  final over = balls ~/ 6;
  return sorted[over % sorted.length];
}

int _averageRating(
  List<CricketPlayer> players,
  int Function(CricketPlayer p) pick,
) {
  if (players.isEmpty) return 60;
  final total = players.fold<int>(0, (sum, p) => sum + pick(p));
  return (total / players.length).round().clamp(0, 100);
}

/// After a delivery, whether the match should move to result (2nd innings finished or chase met).
bool shouldAutoCompleteMatchAfterDelivery(
  MatchRoom room, {
  required bool strikerWasHost,
}) {
  if (room.inningsNumber != 2) return false;
  final score = strikerWasHost ? room.hostRuns : room.guestRuns;
  if (room.chaseTarget != null && score >= room.chaseTarget!) return true;
  final wk = strikerWasHost ? room.hostWickets : room.guestWickets;
  final bl = strikerWasHost ? room.hostLegalBalls : room.guestLegalBalls;
  if (wk >= 10 || bl >= room.maxBalls) return true;
  return false;
}
