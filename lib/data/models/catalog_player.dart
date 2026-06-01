import 'cricket_player.dart';
import 'player_attributes.dart';
import 'player_role.dart';
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
    this.role,
    this.country,
    this.battingStyle,
    this.bowlingStyle,
    this.generatedBio,
    this.avatarUrl,
    this.cardImageAsset,
  });

  final String id;
  final String displayName;
  final bool isRealPlayer;
  final PlayerTier playerTier;
  final PlayerRole? role;
  final String? country;
  final String? battingStyle;
  final String? bowlingStyle;
  final String? generatedBio;
  final String? avatarUrl;
  final String? cardImageAsset;
  final PlayerAttributes attributes;

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'isRealPlayer': isRealPlayer,
    'playerTier': playerTier.firestoreValue,
    'role': effectiveRole.firestoreValue,
    if (country != null) 'country': country,
    if (battingStyle != null) 'battingStyle': battingStyle,
    if (bowlingStyle != null) 'bowlingStyle': bowlingStyle,
    if (generatedBio != null) 'generatedBio': generatedBio,
    'avatarUrl': avatarUrl,
    'cardImageAsset': cardImageAsset,
    'attributes': attributes.toMap(),
  };

  PlayerRole get effectiveRole =>
      role ??
      PlayerRole.infer(
        batting: attributes.batting,
        bowling: attributes.bowling,
      );

  factory CatalogPlayer.fromMap(Map<String, dynamic> map) {
    final isReal = map['isRealPlayer'] as bool? ?? false;
    final attributes = PlayerAttributes.fromMap(
      Map<String, dynamic>.from(map['attributes'] as Map? ?? {}),
    );
    return CatalogPlayer(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Unknown',
      isRealPlayer: isReal,
      playerTier: PlayerTier.fromFirestore(
        map['playerTier'],
        isRealPlayer: isReal,
      ),
      role: PlayerRole.fromFirestore(
        map['role'],
        batting: attributes.batting,
        bowling: attributes.bowling,
      ),
      country: map['country'] as String?,
      battingStyle: map['battingStyle'] as String?,
      bowlingStyle: map['bowlingStyle'] as String?,
      generatedBio: map['generatedBio'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      cardImageAsset: map['cardImageAsset'] as String?,
      attributes: attributes,
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
      role: role,
      country: country,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
      generatedBio: generatedBio,
      avatarUrl: avatarUrl,
      cardImageAsset: cardImageAsset,
      attributes: attributes,
    );
  }
}
