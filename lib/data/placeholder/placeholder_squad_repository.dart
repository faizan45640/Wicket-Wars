import 'dart:math';

import '../models/cricket_player.dart';
import '../models/player_attributes.dart';
import '../models/player_role.dart';
import '../models/player_tier.dart';
import '../models/starter_pack_opening.dart';
import '../repositories/squad_repository.dart';
import 'in_memory_store.dart';

class PlaceholderSquadRepository implements SquadRepository {
  final InMemoryStore _store = InMemoryStore.instance;
  final Random _random = Random();

  PlaceholderSquadRepository() {
    _store.ensureInitialized();
  }

  @override
  Future<List<CricketPlayer>> getSquad(String uid) async {
    if (uid.isEmpty) return [];
    if (uid == InMemoryStore.demoUid) {
      return _store.demoPlayersById.values.toList();
    }
    final m = _store.extraSquadsByUid[uid];
    if (m == null || m.isEmpty) return [];
    return m.values.toList();
  }

  @override
  Future<CricketPlayer> generatePlayer({
    required String uid,
    String? prompt,
  }) async {
    final roles = PlayerRole.values;
    final role = roles[_random.nextInt(roles.length)];
    final player = CricketPlayer(
      id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
      displayName: _fallbackName(prompt),
      isRealPlayer: false,
      playerTier: PlayerTier.free,
      role: role,
      country: 'Academy',
      battingStyle:
          role == PlayerRole.wicketKeeper ? 'Left-hand bat' : 'Right-hand bat',
      bowlingStyle:
          role == PlayerRole.wicketKeeper
              ? 'Wicket keeper'
              : 'Right-arm medium',
      generatedBio:
          prompt?.trim().isNotEmpty == true
              ? 'A club scout pick inspired by: ${prompt!.trim()}'
              : 'A promising Wicket Wars academy prospect.',
      attributes: PlayerAttributes(
        batting: 52 + _random.nextInt(24),
        bowling: 48 + _random.nextInt(24),
        fielding: 50 + _random.nextInt(22),
        stamina: 52 + _random.nextInt(22),
        consistency: 50 + _random.nextInt(22),
      ),
    );
    await upsertPlayer(uid, player);
    return player;
  }

  @override
  Future<StarterPackOpening> openStarterPack({required String uid}) async {
    final premium = CricketPlayer(
      id: 'premium_babar_azam',
      displayName: 'Babar Azam',
      isRealPlayer: true,
      playerTier: PlayerTier.premium,
      role: PlayerRole.batter,
      country: 'Pakistan',
      battingStyle: 'Right-hand bat',
      bowlingStyle: 'Part-time off spin',
      generatedBio: 'Premium catalog pull: elite top-order run machine.',
      attributes: const PlayerAttributes(
        batting: 88,
        bowling: 36,
        fielding: 76,
        stamina: 82,
        consistency: 88,
      ),
    );
    final players = <CricketPlayer>[premium];
    for (var i = 0; i < 14; i++) {
      players.add(await generatePlayer(uid: uid, prompt: 'starter pack'));
    }
    for (final p in players) {
      await upsertPlayer(uid, p);
    }
    _store.extraProfilesByUid[uid] = (_store.extraProfilesByUid[uid] ??
            _store.demoProfile.copyWith(uid: uid))
        .copyWith(starterPackOpened: true);
    return StarterPackOpening(
      players: players,
      generationSource: 'fallback',
      alreadyOpened: false,
    );
  }

  @override
  Future<void> upsertPlayer(String uid, CricketPlayer player) async {
    if (uid.isEmpty) return;
    if (uid == InMemoryStore.demoUid) {
      _store.demoPlayersById[player.id] = player;
      return;
    }
    _store.extraSquadsByUid.putIfAbsent(uid, () => {})[player.id] = player;
  }

  @override
  Future<void> deletePlayer(String uid, String playerId) async {
    if (uid == InMemoryStore.demoUid) {
      _store.demoPlayersById.remove(playerId);
      return;
    }
    _store.extraSquadsByUid[uid]?.remove(playerId);
  }

  @override
  Stream<List<CricketPlayer>> watchSquad(String uid) async* {
    yield await getSquad(uid);
  }

  String _fallbackName(String? prompt) {
    final cleaned = prompt?.trim();
    if (cleaned != null && cleaned.isNotEmpty) {
      final first = cleaned.split(RegExp(r'\s+')).take(2).join(' ');
      return '$first Prospect';
    }
    const names = ['Ayaan Volt', 'Rahil Storm', 'Zayan Crest', 'Nilan Edge'];
    return names[_random.nextInt(names.length)];
  }
}
