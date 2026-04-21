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
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String).toLocal()
          : null,
      commentaryTail: List<String>.from(map['commentaryTail'] as List? ?? const []),
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
