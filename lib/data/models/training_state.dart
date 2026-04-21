/// Custom players only; blocks Playing XI until [completesAt].
class TrainingState {
  const TrainingState({
    required this.startedAt,
    required this.completesAt,
  });

  final DateTime startedAt;
  final DateTime completesAt;

  bool get isComplete => DateTime.now().isAfter(completesAt);

  Map<String, dynamic> toMap() => {
        'startedAt': startedAt.toUtc().toIso8601String(),
        'completesAt': completesAt.toUtc().toIso8601String(),
      };

  factory TrainingState.fromMap(Map<String, dynamic> map) {
    return TrainingState(
      startedAt: DateTime.parse(map['startedAt'] as String).toLocal(),
      completesAt: DateTime.parse(map['completesAt'] as String).toLocal(),
    );
  }
}
