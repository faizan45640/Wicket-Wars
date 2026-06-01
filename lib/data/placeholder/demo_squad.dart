import '../models/cricket_player.dart';
import '../models/player_attributes.dart';
import '../models/player_role.dart';
import '../models/player_tier.dart';

/// Same squad used on [SquadScreen] and the training player picker (IDs must match).
List<CricketPlayer> buildDemoSquad() {
  const letters = 'ABCDEFGHIJKL';
  return List.generate(letters.length, (i) {
    final l = letters[i];
    int clamp100(int v) => v.clamp(0, 100);
    final bat = clamp100(55 + i * 3);
    final bwl = clamp100(48 + (i % 5) * 4);
    final fld = clamp100(50 + i * 2);
    final sta = clamp100(58 + (i % 3));
    final con = clamp100(52 + i);
    return CricketPlayer(
      id: 'p_$i',
      displayName: 'Player $l',
      isRealPlayer: i.isEven,
      playerTier: i.isEven ? PlayerTier.premium : PlayerTier.free,
      role: PlayerRole.infer(batting: bat, bowling: bwl, wicketKeeper: i == 4),
      country:
          const [
            'Pakistan',
            'India',
            'Australia',
            'England',
            'Sri Lanka',
            'South Africa',
            'New Zealand',
            'Bangladesh',
            'Afghanistan',
            'West Indies',
            'UAE',
            'Nepal',
          ][i],
      battingStyle: i.isEven ? 'Right-hand bat' : 'Left-hand bat',
      bowlingStyle:
          i == 4
              ? 'Wicket keeper'
              : i % 3 == 0
              ? 'Right-arm fast'
              : 'Right-arm spin',
      cardImageAsset: null,
      attributes: PlayerAttributes(
        batting: bat,
        bowling: bwl,
        fielding: fld,
        stamina: sta,
        consistency: con,
      ),
    );
  });
}
