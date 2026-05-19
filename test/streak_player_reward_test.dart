import 'package:flutter_test/flutter_test.dart';
import 'package:wicket_wars/data/models/cricket_player.dart';
import 'package:wicket_wars/data/models/player_attributes.dart';
import 'package:wicket_wars/data/models/player_tier.dart';
import 'package:wicket_wars/data/streak_player_reward.dart';

void main() {
  test('qualifies every 4th day', () {
    expect(qualifiesForStreakPlayerBonus(0), false);
    expect(qualifiesForStreakPlayerBonus(3), false);
    expect(qualifiesForStreakPlayerBonus(4), true);
    expect(qualifiesForStreakPlayerBonus(8), true);
  });

  test('day 4 adds a trainable player when squad has room', () async {
    CricketPlayer? saved;
    final out = await applyStreakPlayerBonus(
      nextStreakAfterClaim: 4,
      uid: 'u1',
      loadSquad: (_) async => [],
      savePlayer: (uid, CricketPlayer p) async {
        saved = p;
      },
      loadCatalog: () async => [],
    );
    expect(out.extraCoins, 0);
    expect(out.summaryLine, contains('added'));
    expect(saved, isNotNull);
    expect(saved!.canTrainAndUpgrade, true);
  });

  test('squad full yields coins not player', () async {
    final big = List<CricketPlayer>.generate(
      15,
      (i) => CricketPlayer(
        id: 'p$i',
        displayName: 'P$i',
        isRealPlayer: false,
        playerTier: PlayerTier.free,
        attributes: const PlayerAttributes(
          batting: 50,
          bowling: 50,
          fielding: 50,
          stamina: 50,
          consistency: 50,
        ),
      ),
    );
    var saved = false;
    final out = await applyStreakPlayerBonus(
      nextStreakAfterClaim: 4,
      uid: 'u1',
      loadSquad: (_) async => big,
      savePlayer: (_, __) async {
        saved = true;
      },
      loadCatalog: () async => [],
    );
    expect(out.extraCoins, kStreakBonusCoinsWhenSquadFull);
    expect(saved, false);
  });
}
