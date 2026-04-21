import 'player_attributes.dart';
import 'training_state.dart';

/// Real (fixed) or custom (trainable) squad member — `users/{uid}/players/{id}`.
class CricketPlayer {
  const CricketPlayer({
    required this.id,
    required this.displayName,
    required this.isRealPlayer,
    required this.attributes,
    this.avatarUrl,
    this.training,
  });

  final String id;
  final String displayName;
  final bool isRealPlayer;
  final String? avatarUrl;
  final PlayerAttributes attributes;

  /// Null when not in training.
  final TrainingState? training;

  bool get isTraining => training != null && !training!.isComplete;
  bool get availableForXi => !isTraining;

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'isRealPlayer': isRealPlayer,
        'avatarUrl': avatarUrl,
        'attributes': attributes.toMap(),
        'training': training?.toMap(),
      };

  factory CricketPlayer.fromMap(Map<String, dynamic> map) {
    return CricketPlayer(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Unknown',
      isRealPlayer: map['isRealPlayer'] as bool? ?? false,
      avatarUrl: map['avatarUrl'] as String?,
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
    String? avatarUrl,
    PlayerAttributes? attributes,
    TrainingState? training,
    bool clearTraining = false,
  }) {
    return CricketPlayer(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isRealPlayer: isRealPlayer ?? this.isRealPlayer,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      attributes: attributes ?? this.attributes,
      training: clearTraining ? null : (training ?? this.training),
    );
  }
}
