import 'pitch_condition.dart';

/// High-level room lifecycle for 1v1 (see GDD).
enum MatchRoomStatus {
  /// Host created room; waiting for guest.
  waitingGuest,

  /// Both joined; selecting / locking XI.
  selectingXi,

  /// Both XIs locked; simulation running.
  inProgress,

  /// Final scores written.
  completed,
}

/// One Firestore doc per room (`matchRooms/{roomId}`) — expand for ball-by-ball fields later.
class MatchRoom {
  const MatchRoom({
    required this.roomId,
    required this.roomCode,
    required this.status,
    required this.pitch,
    this.hostUid,
    this.guestUid,
    this.hostPlayingXi = const [],
    this.guestPlayingXi = const [],
    this.hostXiLocked = false,
    this.guestXiLocked = false,
    this.hostRuns = 0,
    this.guestRuns = 0,
    this.hostWickets = 0,
    this.guestWickets = 0,
    this.hostLegalBalls = 0,
    this.guestLegalBalls = 0,
    this.inningsNumber = 1,
    this.hostBatFirst,
    this.chaseTarget,
    this.completedAt,
    this.commentaryTail = const [],
  });

  final String roomId;
  final String roomCode;
  final MatchRoomStatus status;
  final PitchCondition pitch;
  final String? hostUid;
  final String? guestUid;
  final List<String> hostPlayingXi;
  final List<String> guestPlayingXi;
  final bool hostXiLocked;
  final bool guestXiLocked;
  final int hostRuns;
  final int guestRuns;
  final int hostWickets;
  final int guestWickets;
  /// Legal balls faced by host (for run rate / result).
  final int hostLegalBalls;
  final int guestLegalBalls;
  /// 1 = first innings, 2 = chase.
  final int inningsNumber;

  /// When non-null, host bats in innings 1. Set when the match engine starts (toss).
  final bool? hostBatFirst;

  /// Runs required for the chasing team to win (innings 2), set after innings 1 ends.
  final int? chaseTarget;

  final DateTime? completedAt;
  final List<String> commentaryTail;

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'roomCode': roomCode,
        'status': status.name,
        'pitch': pitch.name,
        'hostUid': hostUid,
        'guestUid': guestUid,
        'hostPlayingXi': hostPlayingXi,
        'guestPlayingXi': guestPlayingXi,
        'hostXiLocked': hostXiLocked,
        'guestXiLocked': guestXiLocked,
        'hostRuns': hostRuns,
        'guestRuns': guestRuns,
        'hostWickets': hostWickets,
        'guestWickets': guestWickets,
        'hostLegalBalls': hostLegalBalls,
        'guestLegalBalls': guestLegalBalls,
        'inningsNumber': inningsNumber,
        'hostBatFirst': hostBatFirst,
        'chaseTarget': chaseTarget,
        'completedAt': completedAt?.toUtc().toIso8601String(),
        'commentaryTail': commentaryTail,
      };

  factory MatchRoom.fromMap(Map<String, dynamic> map) {
    return MatchRoom(
      roomId: map['roomId'] as String? ?? '',
      roomCode: map['roomCode'] as String? ?? '',
      status: _parseStatus(map['status'] as String?),
      pitch: _parsePitch(map['pitch'] as String?),
      hostUid: map['hostUid'] as String?,
      guestUid: map['guestUid'] as String?,
      hostPlayingXi: List<String>.from(map['hostPlayingXi'] as List? ?? const []),
      guestPlayingXi: List<String>.from(map['guestPlayingXi'] as List? ?? const []),
      hostXiLocked: map['hostXiLocked'] as bool? ?? false,
      guestXiLocked: map['guestXiLocked'] as bool? ?? false,
      hostRuns: (map['hostRuns'] as num?)?.round() ?? 0,
      guestRuns: (map['guestRuns'] as num?)?.round() ?? 0,
      hostWickets: (map['hostWickets'] as num?)?.round() ?? 0,
      guestWickets: (map['guestWickets'] as num?)?.round() ?? 0,
      hostLegalBalls: (map['hostLegalBalls'] as num?)?.round() ?? 0,
      guestLegalBalls: (map['guestLegalBalls'] as num?)?.round() ?? 0,
      inningsNumber: (map['inningsNumber'] as num?)?.round() ?? 1,
      hostBatFirst: map['hostBatFirst'] as bool?,
      chaseTarget: (map['chaseTarget'] as num?)?.round(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String).toLocal()
          : null,
      commentaryTail: List<String>.from(map['commentaryTail'] as List? ?? const []),
    );
  }

  MatchRoom copyWith({
    String? roomId,
    String? roomCode,
    MatchRoomStatus? status,
    PitchCondition? pitch,
    String? hostUid,
    String? guestUid,
    List<String>? hostPlayingXi,
    List<String>? guestPlayingXi,
    bool? hostXiLocked,
    bool? guestXiLocked,
    int? hostRuns,
    int? guestRuns,
    int? hostWickets,
    int? guestWickets,
    int? hostLegalBalls,
    int? guestLegalBalls,
    int? inningsNumber,
    bool? hostBatFirst,
    int? chaseTarget,
    DateTime? completedAt,
    List<String>? commentaryTail,
  }) {
    return MatchRoom(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      status: status ?? this.status,
      pitch: pitch ?? this.pitch,
      hostUid: hostUid ?? this.hostUid,
      guestUid: guestUid ?? this.guestUid,
      hostPlayingXi: hostPlayingXi ?? this.hostPlayingXi,
      guestPlayingXi: guestPlayingXi ?? this.guestPlayingXi,
      hostXiLocked: hostXiLocked ?? this.hostXiLocked,
      guestXiLocked: guestXiLocked ?? this.guestXiLocked,
      hostRuns: hostRuns ?? this.hostRuns,
      guestRuns: guestRuns ?? this.guestRuns,
      hostWickets: hostWickets ?? this.hostWickets,
      guestWickets: guestWickets ?? this.guestWickets,
      hostLegalBalls: hostLegalBalls ?? this.hostLegalBalls,
      guestLegalBalls: guestLegalBalls ?? this.guestLegalBalls,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      hostBatFirst: hostBatFirst ?? this.hostBatFirst,
      chaseTarget: chaseTarget ?? this.chaseTarget,
      completedAt: completedAt ?? this.completedAt,
      commentaryTail: commentaryTail ?? this.commentaryTail,
    );
  }

  static MatchRoomStatus _parseStatus(String? raw) {
    for (final v in MatchRoomStatus.values) {
      if (v.name == raw) return v;
    }
    return MatchRoomStatus.waitingGuest;
  }

  static PitchCondition _parsePitch(String? raw) {
    for (final v in PitchCondition.values) {
      if (v.name == raw) return v;
    }
    return PitchCondition.balanced;
  }
}
