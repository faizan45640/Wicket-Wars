import 'package:flutter_test/flutter_test.dart';
import 'package:wicket_wars/data/models/catalog_player.dart';
import 'package:wicket_wars/data/models/cricket_player.dart';
import 'package:wicket_wars/data/models/player_attributes.dart';
import 'package:wicket_wars/data/models/player_role.dart';
import 'package:wicket_wars/data/models/player_tier.dart';

void main() {
  const attributes = PlayerAttributes(
    batting: 78,
    bowling: 54,
    fielding: 70,
    stamina: 66,
    consistency: 72,
  );

  test('CricketPlayer serializes rich squad metadata', () {
    const player = CricketPlayer(
      id: 'p1',
      displayName: 'Aarav Striker',
      isRealPlayer: false,
      playerTier: PlayerTier.free,
      role: PlayerRole.batter,
      country: 'India',
      battingStyle: 'Right-hand bat',
      bowlingStyle: 'Part-time off spin',
      generatedBio: 'Aggressive top-order batter.',
      avatarUrl: 'https://example.com/player.png',
      cardImageAsset: 'assets/images/player.png',
      attributes: attributes,
    );

    final map = player.toMap();
    expect(map['role'], 'batter');
    expect(map['country'], 'India');
    expect(map['avatarUrl'], 'https://example.com/player.png');

    final decoded = CricketPlayer.fromMap(map);
    expect(decoded.effectiveRole, PlayerRole.batter);
    expect(decoded.countryLabel, 'India');
    expect(decoded.battingStyle, 'Right-hand bat');
    expect(decoded.generatedBio, 'Aggressive top-order batter.');
  });

  test('CricketPlayer infers role for older Firestore docs', () {
    final decoded = CricketPlayer.fromMap({
      'id': 'legacy',
      'displayName': 'Legacy Player',
      'isRealPlayer': false,
      'playerTier': 'free',
      'attributes': attributes.toMap(),
    });

    expect(decoded.effectiveRole, PlayerRole.batter);
    expect(decoded.countryLabel, 'Unknown');
  });

  test('CatalogPlayer passes metadata into squad player copy', () {
    const catalog = CatalogPlayer(
      id: 'c1',
      displayName: 'Catalog Keeper',
      isRealPlayer: true,
      playerTier: PlayerTier.premium,
      role: PlayerRole.wicketKeeper,
      country: 'Pakistan',
      battingStyle: 'Left-hand bat',
      bowlingStyle: 'Wicket keeper',
      generatedBio: 'Reliable keeper-batter.',
      attributes: attributes,
    );

    final squad = catalog.toSquadPlayer(squadPlayerId: 's1');
    expect(squad.catalogPlayerId, 'c1');
    expect(squad.effectiveRole, PlayerRole.wicketKeeper);
    expect(squad.country, 'Pakistan');
    expect(squad.generatedBio, 'Reliable keeper-batter.');
  });
}
