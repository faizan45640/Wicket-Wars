import 'models/catalog_player.dart';
import 'models/cricket_player.dart';
import 'models/player_attributes.dart';
import 'models/player_role.dart';
import 'models/player_tier.dart';

/// Every N consecutive daily-claim days, user earns a trainee for their squad (or coins if squad is full).
const int kStreakPlayerBonusInterval = 4;

/// Starter packs grant 15 players; daily streaks can grow the long-term squad beyond that.
const int kDailyRewardMaxSquadPlayers = 30;

const int kStreakBonusCoinsWhenSquadFull = 175;

bool qualifiesForStreakPlayerBonus(int nextStreakAfterClaim) {
  return nextStreakAfterClaim > 0 &&
      nextStreakAfterClaim % kStreakPlayerBonusInterval == 0;
}

/// Smallest OVR cap used in-app for generated recruits (matches trainable custom cards).
CricketPlayer _defaultStreakRecruit({
  required String id,
  required int streakDay,
}) {
  return CricketPlayer(
    id: id,
    displayName: 'Streak recruit (day $streakDay)',
    isRealPlayer: false,
    playerTier: PlayerTier.free,
    role: PlayerRole.allRounder,
    country: 'Generated',
    battingStyle: 'Right-hand bat',
    bowlingStyle: 'Right-arm medium',
    generatedBio:
        'A daily streak recruit generated for consistent Wicket Wars play.',
    attributes: const PlayerAttributes(
      batting: 48,
      bowling: 46,
      fielding: 50,
      stamina: 52,
      consistency: 47,
    ),
  );
}

CatalogPlayer? _firstTrainableTemplate(List<CatalogPlayer> catalog) {
  for (final c in catalog) {
    if (!c.isRealPlayer && c.playerTier == PlayerTier.free) {
      return c;
    }
  }
  return null;
}

class StreakPlayerBonusOutcome {
  const StreakPlayerBonusOutcome({
    required this.summaryLine,
    this.extraCoins = 0,
  });

  /// Short line for SnackBar / dialog (empty if no bonus this claim).
  final String summaryLine;

  /// Added when squad is at capacity (Firestore profile update by caller).
  final int extraCoins;
}

/// When [qualifiesForStreakPlayerBonus] is true, adds a player or coins. Safe to call after daily coins are saved.
Future<StreakPlayerBonusOutcome> applyStreakPlayerBonus({
  required int nextStreakAfterClaim,
  required String uid,
  required Future<List<CricketPlayer>> Function(String uid) loadSquad,
  required Future<void> Function(String uid, CricketPlayer player) savePlayer,
  required Future<List<CatalogPlayer>> Function() loadCatalog,
  int maxSquadPlayers = kDailyRewardMaxSquadPlayers,
}) async {
  if (!qualifiesForStreakPlayerBonus(nextStreakAfterClaim)) {
    return const StreakPlayerBonusOutcome(summaryLine: '');
  }

  final squad = await loadSquad(uid);
  if (squad.length >= maxSquadPlayers) {
    return const StreakPlayerBonusOutcome(
      summaryLine: '', // Caller builds message with coin amount
      extraCoins: kStreakBonusCoinsWhenSquadFull,
    );
  }

  final catalog = await loadCatalog();
  final template = _firstTrainableTemplate(catalog);
  final id =
      'streak_${nextStreakAfterClaim}_${DateTime.now().millisecondsSinceEpoch}';
  final CricketPlayer player;
  if (template != null) {
    player = template
        .toSquadPlayer(squadPlayerId: id)
        .copyWith(
          displayName: '${template.displayName} · S$nextStreakAfterClaim',
          generatedBio:
              'Earned as a day $nextStreakAfterClaim daily streak reward.',
        );
  } else {
    player = _defaultStreakRecruit(id: id, streakDay: nextStreakAfterClaim);
  }

  await savePlayer(uid, player);
  return StreakPlayerBonusOutcome(
    summaryLine:
        'Day $nextStreakAfterClaim bonus: ${player.displayName} added to your squad!',
  );
}
