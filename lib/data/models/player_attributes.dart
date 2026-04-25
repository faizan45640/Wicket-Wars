/// Six core attributes from the design doc (0–100 scale in placeholders).
class PlayerAttributes {
  const PlayerAttributes({
    required this.batting,
    required this.bowling,
    required this.fielding,
    required this.stamina,
    required this.consistency,
  })  : assert(batting >= 0 && batting <= 100),
        assert(bowling >= 0 && bowling <= 100),
        assert(fielding >= 0 && fielding <= 100),
        assert(stamina >= 0 && stamina <= 100),
        assert(consistency >= 0 && consistency <= 100);

  final int batting;
  final int bowling;
  final int fielding;
  final int stamina;
  final int consistency;

  /// Weighted composite for UI / sorting (tunable).
  int get overall =>
      ((batting * 3 + bowling * 3 + fielding + stamina + consistency) / 9).round();

  Map<String, dynamic> toMap() => {
        'batting': batting,
        'bowling': bowling,
        'fielding': fielding,
        'stamina': stamina,
        'consistency': consistency,
        'overall': overall,
      };

  factory PlayerAttributes.fromMap(Map<String, dynamic> map) {
    return PlayerAttributes(
      batting: (map['batting'] as num?)?.round() ?? 0,
      bowling: (map['bowling'] as num?)?.round() ?? 0,
      fielding: (map['fielding'] as num?)?.round() ?? 0,
      stamina: (map['stamina'] as num?)?.round() ?? 0,
      consistency: (map['consistency'] as num?)?.round() ?? 0,
    );
  }

  static int _clamp100(int v) => v < 0 ? 0 : (v > 100 ? 100 : v);

  PlayerAttributes copyWith({
    int? batting,
    int? bowling,
    int? fielding,
    int? stamina,
    int? consistency,
  }) {
    return PlayerAttributes(
      batting: _clamp100(batting ?? this.batting),
      bowling: _clamp100(bowling ?? this.bowling),
      fielding: _clamp100(fielding ?? this.fielding),
      stamina: _clamp100(stamina ?? this.stamina),
      consistency: _clamp100(consistency ?? this.consistency),
    );
  }
}
