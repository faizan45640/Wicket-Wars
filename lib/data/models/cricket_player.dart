import 'player_attributes.dart';
import 'player_tier.dart';
import 'training_state.dart';

/// Squad card — `users/{uid}/players/{id}`.
///
/// Stats are **locked** when [isRealPlayer] (licensed / roster anchor) or [playerTier] is
/// [PlayerTier.premium]. Only unlocked custom [PlayerTier.free] cards can train or coin-upgrade.
class CricketPlayer {
  const CricketPlayer({
    required this.id,
    required this.displayName,
    required this.isRealPlayer,
    required this.playerTier,
    required this.attributes,
    this.avatarUrl,
    /// Local PNG in `assets/` for card art (FIFA-style; transparent background recommended).
    this.cardImageAsset,
    this.training,
    /// Set when this row was created from `players_catalog/{id}`.
    this.catalogPlayerId,
  });

  final String id;
  final String displayName;
  final bool isRealPlayer;
  final PlayerTier playerTier;
  final String? catalogPlayerId;
  final String? avatarUrl;
  final String? cardImageAsset;
  final PlayerAttributes attributes;

  /// Null when not in training.
  final TrainingState? training;

  bool get isTraining => training != null && !training!.isComplete;
  bool get availableForXi => !isTraining;

  /// Timed training + coin “upgrade weakest stat” — allowed only for free custom cards.
  bool get canTrainAndUpgrade => !isRealPlayer && playerTier == PlayerTier.free;

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'isRealPlayer': isRealPlayer,
        'playerTier': playerTier.firestoreValue,
        if (catalogPlayerId != null) 'catalogPlayerId': catalogPlayerId,
        'avatarUrl': avatarUrl,
        'cardImageAsset': cardImageAsset,
        'attributes': attributes.toMap(),
        'training': training?.toMap(),
      };

  factory CricketPlayer.fromMap(Map<String, dynamic> map) {
    final isReal = map['isRealPlayer'] as bool? ?? false;
    return CricketPlayer(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Unknown',
      isRealPlayer: isReal,
      playerTier: PlayerTier.fromFirestore(map['playerTier'], isRealPlayer: isReal),
      catalogPlayerId: map['catalogPlayerId'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      cardImageAsset: map['cardImageAsset'] as String?,
      attributes: PlayerAttributes.fromMap(
        Map<String, dynamic>.from(map['attributes'] as Map? ?? {}),
      ),
      training: map['training'] != null
          ? TrainingState.fromMap(Map<String, dynamic>.from(map['training'] as Map))
          : null,
    );
  }

  CricketPlayer copyWith({
    String? id,
    String? displayName,
    bool? isRealPlayer,
    PlayerTier? playerTier,
    String? catalogPlayerId,
    String? avatarUrl,
    String? cardImageAsset,
    PlayerAttributes? attributes,
    TrainingState? training,
    bool clearTraining = false,
  }) {
    return CricketPlayer(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isRealPlayer: isRealPlayer ?? this.isRealPlayer,
      playerTier: playerTier ?? this.playerTier,
      catalogPlayerId: catalogPlayerId ?? this.catalogPlayerId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cardImageAsset: cardImageAsset ?? this.cardImageAsset,
      attributes: attributes ?? this.attributes,
      training: clearTraining ? null : (training ?? this.training),
    );
  }
}
