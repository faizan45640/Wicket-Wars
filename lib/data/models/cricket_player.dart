import '../training_rules.dart';
import 'player_attributes.dart';
import 'player_role.dart';
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
    this.role,
    this.country,
    this.battingStyle,
    this.bowlingStyle,
    this.generatedBio,
    this.avatarUrl,

    /// Local PNG in `assets/` for card art (FIFA-style; transparent background recommended).
    this.cardImageAsset,
    this.training,

    /// Max overall this free card can be trained to. Null until first derived.
    this.potentialOverall,

    /// Set when this row was created from `players_catalog/{id}`.
    this.catalogPlayerId,
  });

  final String id;
  final String displayName;
  final bool isRealPlayer;
  final PlayerTier playerTier;
  final String? catalogPlayerId;
  final PlayerRole? role;
  final String? country;
  final String? battingStyle;
  final String? bowlingStyle;
  final String? generatedBio;
  final String? avatarUrl;
  final String? cardImageAsset;
  final PlayerAttributes attributes;

  /// Null when not in training.
  final TrainingState? training;

  /// Max overall this free card can be trained to (potential cap). Null until
  /// first derived from [id]; persisted once the player trains.
  final int? potentialOverall;

  bool get isTraining => training != null && !training!.isComplete;
  bool get availableForXi => !isTraining;

  /// Training (energy + coins) — allowed only for free custom cards.
  bool get canTrainAndUpgrade => !isRealPlayer && playerTier == PlayerTier.free;

  /// Overall this player can be trained up to. Fixed cards return their current
  /// overall; free cards use the stored value or a stable derived ceiling.
  int get effectivePotential {
    if (!canTrainAndUpgrade) return attributes.overall;
    final stored = potentialOverall;
    if (stored != null) return stored < attributes.overall ? attributes.overall : stored;
    final pot = attributes.overall + potentialHeadroomFromId(id);
    return pot > kFreePotentialCeiling ? kFreePotentialCeiling : pot;
  }

  PlayerRole get effectiveRole =>
      role ??
      PlayerRole.infer(
        batting: attributes.batting,
        bowling: attributes.bowling,
      );

  String get imageUrl => avatarUrl?.trim() ?? '';

  String get roleLabel => effectiveRole.label;

  String get countryLabel {
    final value = country?.trim() ?? '';
    return value.isEmpty ? 'Unknown' : value;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'isRealPlayer': isRealPlayer,
    'playerTier': playerTier.firestoreValue,
    if (catalogPlayerId != null) 'catalogPlayerId': catalogPlayerId,
    'role': effectiveRole.firestoreValue,
    if (country != null) 'country': country,
    if (battingStyle != null) 'battingStyle': battingStyle,
    if (bowlingStyle != null) 'bowlingStyle': bowlingStyle,
    if (generatedBio != null) 'generatedBio': generatedBio,
    'avatarUrl': avatarUrl,
    'cardImageAsset': cardImageAsset,
    'attributes': attributes.toMap(),
    'training': training?.toMap(),
    if (canTrainAndUpgrade) 'potentialOverall': effectivePotential,
  };

  factory CricketPlayer.fromMap(Map<String, dynamic> map) {
    final isReal = map['isRealPlayer'] as bool? ?? false;
    final attributes = PlayerAttributes.fromMap(
      Map<String, dynamic>.from(map['attributes'] as Map? ?? {}),
    );
    return CricketPlayer(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Unknown',
      isRealPlayer: isReal,
      playerTier: PlayerTier.fromFirestore(
        map['playerTier'],
        isRealPlayer: isReal,
      ),
      catalogPlayerId: map['catalogPlayerId'] as String?,
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
      training:
          map['training'] != null
              ? TrainingState.fromMap(
                Map<String, dynamic>.from(map['training'] as Map),
              )
              : null,
      potentialOverall: (map['potentialOverall'] as num?)?.round(),
    );
  }

  CricketPlayer copyWith({
    String? id,
    String? displayName,
    bool? isRealPlayer,
    PlayerTier? playerTier,
    String? catalogPlayerId,
    PlayerRole? role,
    String? country,
    String? battingStyle,
    String? bowlingStyle,
    String? generatedBio,
    String? avatarUrl,
    String? cardImageAsset,
    PlayerAttributes? attributes,
    TrainingState? training,
    int? potentialOverall,
    bool clearTraining = false,
  }) {
    return CricketPlayer(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isRealPlayer: isRealPlayer ?? this.isRealPlayer,
      playerTier: playerTier ?? this.playerTier,
      catalogPlayerId: catalogPlayerId ?? this.catalogPlayerId,
      role: role ?? this.role,
      country: country ?? this.country,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      generatedBio: generatedBio ?? this.generatedBio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cardImageAsset: cardImageAsset ?? this.cardImageAsset,
      attributes: attributes ?? this.attributes,
      training: clearTraining ? null : (training ?? this.training),
      potentialOverall: potentialOverall ?? this.potentialOverall,
    );
  }
}
