import 'models/cricket_player.dart';
import 'models/player_attributes.dart';
import 'models/player_role.dart';
import 'models/player_tier.dart';
import 'models/user_profile.dart';
import 'repositories/squad_repository.dart';
import 'repositories/user_repository.dart';

UserProfile starterProfile({
  required String uid,
  required String displayName,
  String? email,
}) {
  return UserProfile(
    uid: uid,
    displayName: displayName.trim().isEmpty ? 'Player' : displayName.trim(),
    email: email?.trim().isEmpty ?? true ? null : email!.trim().toLowerCase(),
    coins: 1500,
    rankingPoints: 0,
    leagueTier: 'ROOKIE LEAGUE',
    wins: 0,
    losses: 0,
    matchesPlayed: 0,
    createdAt: DateTime.now().toUtc(),
    dailyStreak: 0,
    totalRunsScored: 0,
    starterPackOpened: false,
  );
}

List<CricketPlayer> starterSquad() {
  const seeds = [
    (
      name: 'Aarav Striker',
      role: PlayerRole.batter,
      country: 'India',
      bat: 'Right-hand bat',
      bowl: 'Part-time off spin',
    ),
    (
      name: 'Bilal Swing',
      role: PlayerRole.bowler,
      country: 'Pakistan',
      bat: 'Right-hand bat',
      bowl: 'Right-arm fast medium',
    ),
    (
      name: 'Zain Finisher',
      role: PlayerRole.batter,
      country: 'Pakistan',
      bat: 'Left-hand bat',
      bowl: 'Does not bowl',
    ),
    (
      name: 'Hamza Cutter',
      role: PlayerRole.bowler,
      country: 'Bangladesh',
      bat: 'Right-hand bat',
      bowl: 'Left-arm medium',
    ),
    (
      name: 'Rayyan Keeper',
      role: PlayerRole.wicketKeeper,
      country: 'UAE',
      bat: 'Right-hand bat',
      bowl: 'Wicket keeper',
    ),
    (
      name: 'Arjun Anchor',
      role: PlayerRole.batter,
      country: 'Sri Lanka',
      bat: 'Right-hand bat',
      bowl: 'Leg spin',
    ),
    (
      name: 'Kabir Spin',
      role: PlayerRole.bowler,
      country: 'Afghanistan',
      bat: 'Left-hand bat',
      bowl: 'Right-arm leg spin',
    ),
    (
      name: 'Usman Pace',
      role: PlayerRole.bowler,
      country: 'Pakistan',
      bat: 'Right-hand bat',
      bowl: 'Right-arm fast',
    ),
    (
      name: 'Ibrahim Cover',
      role: PlayerRole.allRounder,
      country: 'South Africa',
      bat: 'Right-hand bat',
      bowl: 'Right-arm medium',
    ),
    (
      name: 'Rohan Sweep',
      role: PlayerRole.batter,
      country: 'England',
      bat: 'Left-hand bat',
      bowl: 'Part-time slow left arm',
    ),
    (
      name: 'Daniyal Yorker',
      role: PlayerRole.bowler,
      country: 'Australia',
      bat: 'Right-hand bat',
      bowl: 'Right-arm death pace',
    ),
  ];

  return [
    for (var i = 0; i < seeds.length; i++)
      CricketPlayer(
        id: 'starter_${i + 1}',
        displayName: seeds[i].name,
        isRealPlayer: false,
        playerTier: i < 2 ? PlayerTier.premium : PlayerTier.free,
        role: seeds[i].role,
        country: seeds[i].country,
        battingStyle: seeds[i].bat,
        bowlingStyle: seeds[i].bowl,
        generatedBio:
            '${seeds[i].name} is a ${seeds[i].role.label.toLowerCase()} starter card built for early Wicket Wars squads.',
        attributes: PlayerAttributes(
          batting: 58 + ((i * 7) % 24),
          bowling: 54 + ((i * 5) % 26),
          fielding: 56 + ((i * 3) % 22),
          stamina: 62 + ((i * 4) % 20),
          consistency: 57 + ((i * 6) % 23),
        ),
      ),
  ];
}

Future<void> ensureStarterData({
  required UserRepository userRepository,
  required SquadRepository squadRepository,
  required String uid,
  required String email,
  String? displayName,
  bool seedSquad = false,
}) async {
  if (uid.isEmpty) return;

  final existingProfile = await userRepository.getProfile(uid);
  final resolvedName =
      displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : existingProfile?.displayName ?? 'Player';

  await userRepository.upsertProfile(
    (existingProfile ??
            starterProfile(uid: uid, displayName: resolvedName, email: email))
        .copyWith(
          displayName: resolvedName,
          email: email.trim().toLowerCase(),
          createdAt: existingProfile?.createdAt ?? DateTime.now().toUtc(),
        ),
  );

  final existingSquad = await squadRepository.getSquad(uid);
  if (existingSquad.isNotEmpty) return;
  if (!seedSquad) return;

  for (final player in starterSquad()) {
    await squadRepository.upsertPlayer(uid, player);
  }
}
