import 'cricket_player.dart';
import 'player_attributes.dart';
import 'player_tier.dart';

/// Template row in `players_catalog/{id}` (read-only for clients).
///
/// Use [toSquadPlayer] when copying into `users/{uid}/players/{newId}` after unlock / admin grant.
class CatalogPlayer {
  const CatalogPlayer({
    required this.id,
    required this.displayName,
    required this.isRealPlayer,
    required this.playerTier,
    required this.attributes,
    this.avatarUrl,
    this.cardImageAsset,
  });

  final String id;
  final String displayName;
  final bool isRealPlayer;
  final PlayerTier playerTier;
  final String? avatarUrl;
  final String? cardImageAsset;
  final PlayerAttributes attributes;

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'isRealPlayer': isRealPlayer,
        'playerTier': playerTier.firestoreValue,
        'avatarUrl': avatarUrl,
        'cardImageAsset': cardImageAsset,
        'attributes': attributes.toMap(),
      };

  factory CatalogPlayer.fromMap(Map<String, dynamic> map) {
    final isReal = map['isRealPlayer'] as bool? ?? false;
    return CatalogPlayer(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Unknown',
      isRealPlayer: isReal,
      playerTier: PlayerTier.fromFirestore(map['playerTier'], isRealPlayer: isReal),
      avatarUrl: map['avatarUrl'] as String?,
      cardImageAsset: map['cardImageAsset'] as String?,
      attributes: PlayerAttributes.fromMap(
        Map<String, dynamic>.from(map['attributes'] as Map? ?? {}),
      ),
    );
  }

  /// Row under `users/{uid}/players/{squadPlayerId}`; [catalogPlayerId] is this template's id.
  CricketPlayer toSquadPlayer({required String squadPlayerId}) {
    return CricketPlayer(
      id: squadPlayerId,
      displayName: displayName,
      isRealPlayer: isRealPlayer,
      playerTier: playerTier,
      catalogPlayerId: id,
      avatarUrl: avatarUrl,
      cardImageAsset: cardImageAsset,
      attributes: attributes,
    );
  }
}
