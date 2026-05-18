import 'dart:math';

import 'cricket_format.dart';
import 'match_simulation.dart';
import 'models/match_room.dart';

/// Who faces this innings (once [MatchRoom.hostBatFirst] is set).
bool battingIsHost(MatchRoom r) {
  final h = r.hostBatFirst;
  if (h == null) return true;
  return r.inningsNumber == 1 ? h : !h;
}

/// Apply one legal delivery; returns `null` if the striker's innings is already over or match not ready.
MatchRoom? applyOneDelivery(MatchRoom room, Random rng) {
  if (room.status == MatchRoomStatus.completed) return null;
  if (room.hostBatFirst == null) return null;

  final battingHost = battingIsHost(room);
  final br = battingHost ? room.hostRuns : room.guestRuns;
  final bw = battingHost ? room.hostWickets : room.guestWickets;
  final bb = battingHost ? room.hostLegalBalls : room.guestLegalBalls;

  if (bw >= 10 || bb >= 120) return null;

  if (room.inningsNumber == 2 &&
      room.chaseTarget != null &&
      br >= room.chaseTarget!) {
    return null;
  }

  final ctx = SimBallContext(
    pitch: room.pitch,
    legalBallsInInnings: bb,
    wicketsDown: bw,
    runsScoredThisInnings: br,
    isChaseInnings: room.inningsNumber == 2,
    chaseTarget: room.chaseTarget,
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
  final line =
      '$over · $who: ${runs > 0 ? '$runs' : 'dot'}${wicket > 0 ? ' · OUT!' : ''}';

  var inn = room.inningsNumber;
  var target = room.chaseTarget;
  var tail = [...room.commentaryTail, line];
  if (tail.length > 30) tail = tail.sublist(tail.length - 30);

  final newBr = battingHost ? hr : gr;
  final newBw = battingHost ? hw : gw;
  final newBb = battingHost ? hb : gb;

  if (inn == 1 && (newBw >= 10 || newBb >= 120)) {
    target = newBr + 1;
    inn = 2;
    tail = [
      ...tail,
      '— End of 1st innings ($newBr/$newBw). Target: $target —',
    ];
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
    commentaryTail: tail,
  );
}

/// After a delivery, whether the match should move to result (2nd innings finished or chase met).
bool shouldAutoCompleteMatchAfterDelivery(MatchRoom room, {required bool strikerWasHost}) {
  if (room.inningsNumber != 2) return false;
  final score = strikerWasHost ? room.hostRuns : room.guestRuns;
  if (room.chaseTarget != null && score >= room.chaseTarget!) return true;
  final wk = strikerWasHost ? room.hostWickets : room.guestWickets;
  final bl = strikerWasHost ? room.hostLegalBalls : room.guestLegalBalls;
  if (wk >= 10 || bl >= 120) return true;
  return false;
}
