import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wicket_wars/data/match_delivery_engine.dart';
import 'package:wicket_wars/data/models/cricket_player.dart';
import 'package:wicket_wars/data/models/match_room.dart';
import 'package:wicket_wars/data/models/player_attributes.dart';
import 'package:wicket_wars/data/models/player_tier.dart';
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
    expect(next.deliveryNumber, 1);
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

  test('applyOneDelivery includes selected player names in commentary', () {
    final room = MatchRoom(
      roomId: 'ABC',
      roomCode: 'ABC',
      status: MatchRoomStatus.inProgress,
      pitch: PitchCondition.balanced,
      hostUid: 'h',
      guestUid: 'g',
      hostBatFirst: true,
      inningsNumber: 1,
    );
    final next = applyOneDelivery(
      room,
      Random(2),
      hostPlayers: [_player('bat_1', 'Opener One', batting: 90, bowling: 30)],
      guestPlayers: [
        _player('bowl_1', 'Strike Bowler', batting: 30, bowling: 90),
      ],
    );
    expect(next, isNotNull);
    expect(next!.commentaryTail.last, contains('Opener One'));
    expect(next.commentaryTail.last, contains('Strike Bowler'));
  });
}

CricketPlayer _player(
  String id,
  String name, {
  required int batting,
  required int bowling,
}) {
  return CricketPlayer(
    id: id,
    displayName: name,
    isRealPlayer: false,
    playerTier: PlayerTier.free,
    attributes: PlayerAttributes(
      batting: batting,
      bowling: bowling,
      fielding: 60,
      stamina: 60,
      consistency: 60,
    ),
  );
}
