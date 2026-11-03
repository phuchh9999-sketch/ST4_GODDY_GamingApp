import '../core/constants.dart';

enum RoomStatus {
  waiting,
  ready,
  playing,
  finished,
}

class PlayerDuelResult {
  final String userId;
  final String username;
  final int timeSeconds;
  final int mistakes;
  final int score;
  final bool isCompleted;

  const PlayerDuelResult({
    required this.userId,
    required this.username,
    required this.timeSeconds,
    required this.mistakes,
    required this.score,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'timeSeconds': timeSeconds,
    'mistakes': mistakes,
    'score': score,
    'isCompleted': isCompleted,
  };

  factory PlayerDuelResult.fromJson(Map<String, dynamic> json) => PlayerDuelResult(
    userId: (json['userId'] ?? json['UserId']) as String? ?? '',
    username: (json['username'] ?? json['Username']) as String? ?? '',
    timeSeconds: (json['timeSeconds'] ?? json['TimeSeconds']) as int? ?? 0,
    mistakes: (json['mistakes'] ?? json['Mistakes']) as int? ?? 0,
    score: (json['score'] ?? json['Score']) as int? ?? 0,
    isCompleted: (json['isCompleted'] ?? json['IsCompleted']) as bool? ?? false,
  );
}

class ChallengeRoom {
  final String roomCode;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final String? guestId;
  final String? guestName;
  final String? guestAvatar;
  final GameType gameType;
  final String difficulty;
  final int seed;
  final RoomStatus status;
  final bool hostReady;
  final bool guestReady;
  final int hostScore;
  final int hostTimeSeconds;
  final int guestScore;
  final int guestTimeSeconds;
  final String lastMoveJson;
  final int currentTurn; // 1: Host, 2: Guest
  final PlayerDuelResult? hostResult;
  final PlayerDuelResult? guestResult;
  final String? winnerId;

  const ChallengeRoom({
    required this.roomCode,
    required this.hostId,
    required this.hostName,
    required this.hostAvatar,
    this.guestId,
    this.guestName,
    this.guestAvatar,
    required this.gameType,
    this.difficulty = 'Normal',
    required this.seed,
    this.status = RoomStatus.waiting,
    this.hostReady = false,
    this.guestReady = false,
    this.hostScore = 0,
    this.hostTimeSeconds = 0,
    this.guestScore = 0,
    this.guestTimeSeconds = 0,
    this.lastMoveJson = '',
    this.currentTurn = 1,
    this.hostResult,
    this.guestResult,
    this.winnerId,
  });

  bool get isFull => guestId != null;
  bool get bothReady => hostReady && guestReady && guestId != null;

  ChallengeRoom copyWith({
    String? roomCode,
    String? hostId,
    String? hostName,
    String? hostAvatar,
    String? guestId,
    String? guestName,
    String? guestAvatar,
    GameType? gameType,
    String? difficulty,
    int? seed,
    RoomStatus? status,
    bool? hostReady,
    bool? guestReady,
    int? hostScore,
    int? hostTimeSeconds,
    int? guestScore,
    int? guestTimeSeconds,
    String? lastMoveJson,
    int? currentTurn,
    PlayerDuelResult? hostResult,
    PlayerDuelResult? guestResult,
    String? winnerId,
  }) {
    return ChallengeRoom(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      guestAvatar: guestAvatar ?? this.guestAvatar,
      gameType: gameType ?? this.gameType,
      difficulty: difficulty ?? this.difficulty,
      seed: seed ?? this.seed,
      status: status ?? this.status,
      hostReady: hostReady ?? this.hostReady,
      guestReady: guestReady ?? this.guestReady,
      hostScore: hostScore ?? this.hostScore,
      hostTimeSeconds: hostTimeSeconds ?? this.hostTimeSeconds,
      guestScore: guestScore ?? this.guestScore,
      guestTimeSeconds: guestTimeSeconds ?? this.guestTimeSeconds,
      lastMoveJson: lastMoveJson ?? this.lastMoveJson,
      currentTurn: currentTurn ?? this.currentTurn,
      hostResult: hostResult ?? this.hostResult,
      guestResult: guestResult ?? this.guestResult,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  Map<String, dynamic> toJson() => {
    'roomCode': roomCode,
    'hostId': hostId,
    'hostName': hostName,
    'hostAvatar': hostAvatar,
    'guestId': guestId,
    'guestName': guestName,
    'guestAvatar': guestAvatar,
    'gameType': gameType.name,
    'difficulty': difficulty,
    'seed': seed,
    'status': status.name,
    'hostReady': hostReady,
    'guestReady': guestReady,
    'hostScore': hostScore,
    'hostTimeSeconds': hostTimeSeconds,
    'guestScore': guestScore,
    'guestTimeSeconds': guestTimeSeconds,
    'lastMoveJson': lastMoveJson,
    'currentTurn': currentTurn,
    'hostResult': hostResult?.toJson(),
    'guestResult': guestResult?.toJson(),
    'winnerId': winnerId,
  };

  factory ChallengeRoom.fromJson(Map<String, dynamic> json) {
    final rawGameType = (json['gameType'] ?? json['GameType'] ?? 'caro').toString().toLowerCase();
    final rawStatus = (json['status'] ?? json['Status'] ?? 'waiting').toString().toLowerCase();

    return ChallengeRoom(
      roomCode: (json['roomCode'] ?? json['RoomCode']) as String? ?? '',
      hostId: (json['hostId'] ?? json['HostId']) as String? ?? '',
      hostName: (json['hostName'] ?? json['HostName']) as String? ?? '',
      hostAvatar: (json['hostAvatar'] ?? json['HostAvatar']) as String? ?? '⚡',
      guestId: (json['guestId'] ?? json['GuestId']) as String?,
      guestName: (json['guestName'] ?? json['GuestName']) as String?,
      guestAvatar: (json['guestAvatar'] ?? json['GuestAvatar']) as String?,
      gameType: GameType.values.firstWhere(
        (e) => e.name.toLowerCase() == rawGameType,
        orElse: () => GameType.caro,
      ),
      difficulty: (json['difficulty'] ?? json['Difficulty']) as String? ?? 'Normal',
      seed: (json['seed'] ?? json['Seed']) as int? ?? 4242,
      status: RoomStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == rawStatus,
        orElse: () => RoomStatus.waiting,
      ),
      hostReady: (json['hostReady'] ?? json['HostReady']) as bool? ?? false,
      guestReady: (json['guestReady'] ?? json['GuestReady']) as bool? ?? false,
      hostScore: (json['hostScore'] ?? json['HostScore']) as int? ?? 0,
      hostTimeSeconds: (json['hostTimeSeconds'] ?? json['HostTimeSeconds']) as int? ?? 0,
      guestScore: (json['guestScore'] ?? json['GuestScore']) as int? ?? 0,
      guestTimeSeconds: (json['guestTimeSeconds'] ?? json['GuestTimeSeconds']) as int? ?? 0,
      lastMoveJson: (json['lastMoveJson'] ?? json['LastMoveJson']) as String? ?? '',
      currentTurn: (json['currentTurn'] ?? json['CurrentTurn']) as int? ?? 1,
      hostResult: (json['hostResult'] ?? json['HostResult']) != null
          ? PlayerDuelResult.fromJson((json['hostResult'] ?? json['HostResult']) as Map<String, dynamic>)
          : null,
      guestResult: (json['guestResult'] ?? json['GuestResult']) != null
          ? PlayerDuelResult.fromJson((json['guestResult'] ?? json['GuestResult']) as Map<String, dynamic>)
          : null,
      winnerId: (json['winnerId'] ?? json['WinnerId']) as String?,
    );
  }
}
