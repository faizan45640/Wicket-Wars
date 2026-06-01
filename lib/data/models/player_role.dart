enum PlayerRole {
  batter('batter', 'BAT'),
  bowler('bowler', 'BWL'),
  allRounder('allRounder', 'AR'),
  wicketKeeper('wicketKeeper', 'WK');

  const PlayerRole(this.firestoreValue, this.shortLabel);

  final String firestoreValue;
  final String shortLabel;

  String get label {
    switch (this) {
      case PlayerRole.batter:
        return 'Batter';
      case PlayerRole.bowler:
        return 'Bowler';
      case PlayerRole.allRounder:
        return 'All-rounder';
      case PlayerRole.wicketKeeper:
        return 'Wicket keeper';
    }
  }

  static PlayerRole infer({
    required int batting,
    required int bowling,
    bool wicketKeeper = false,
  }) {
    if (wicketKeeper) return PlayerRole.wicketKeeper;
    if (batting - bowling >= 12) return PlayerRole.batter;
    if (bowling - batting >= 12) return PlayerRole.bowler;
    return PlayerRole.allRounder;
  }

  static PlayerRole fromFirestore(
    Object? value, {
    required int batting,
    required int bowling,
  }) {
    final raw = value?.toString().trim();
    switch (raw) {
      case 'batter':
      case 'BAT':
        return PlayerRole.batter;
      case 'bowler':
      case 'BWL':
        return PlayerRole.bowler;
      case 'allRounder':
      case 'all-rounder':
      case 'ALL':
      case 'AR':
        return PlayerRole.allRounder;
      case 'wicketKeeper':
      case 'wicket-keeper':
      case 'WK':
        return PlayerRole.wicketKeeper;
      default:
        return infer(batting: batting, bowling: bowling);
    }
  }
}
