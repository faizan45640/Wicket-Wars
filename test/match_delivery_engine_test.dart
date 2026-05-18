import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wicket_wars/data/match_delivery_engine.dart';
import 'package:wicket_wars/data/models/match_room.dart';
import 'package:wicket_wars/data/models/pitch_condition.dart';

void main() {
  test('applyOneDelivery advances legal ball count', () {
    final rng = Random(1);
    final room = MatchRoom(
      roomId: 'ABC',
      roomCode: 'ABC',
      status: MatchRoomStatus.inProgress,
      pitch: PitchCondition.balanced,
      hostUid: 'h',
      guestUid: 'g',
      hostBatFirst: true,
      inningsNumber: 1,
      hostLegalBalls: 0,
    );
    final next = applyOneDelivery(room, rng);
    expect(next, isNotNull);
    expect(next!.hostLegalBalls, 1);
  });

  test('applyOneDelivery returns null when striker innings over', () {
    final room = MatchRoom(
      roomId: 'ABC',
      roomCode: 'ABC',
      status: MatchRoomStatus.inProgress,
      pitch: PitchCondition.balanced,
      hostUid: 'h',
      guestUid: 'g',
      hostBatFirst: true,
      inningsNumber: 1,
      hostWickets: 10,
    );
    expect(applyOneDelivery(room, Random(1)), isNull);
  });
}
