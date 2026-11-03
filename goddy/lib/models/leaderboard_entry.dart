import '../core/constants.dart';

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String avatar;
  final int score;
  final int timeSeconds;
  final int mistakes;
  final GameType? gameType;
  final RankTier rankTier;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.avatar,
    required this.score,
    this.timeSeconds = 0,
    this.mistakes = 0,
    this.gameType,
    this.rankTier = RankTier.bronze,
  });

  String get formattedTime {
    final mins = (timeSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (timeSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'userId': userId,
    'username': username,
    'avatar': avatar,
    'score': score,
    'timeSeconds': timeSeconds,
    'mistakes': mistakes,
    'gameType': gameType?.id,
    'rankTier': rankTier.index,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    rank: json['rank'] as int? ?? 1,
    userId: json['userId'] as String? ?? '',
    username: json['username'] as String? ?? 'Player',
    avatar: json['avatar'] as String? ?? '🎮',
    score: json['score'] as int? ?? 0,
    timeSeconds: json['timeSeconds'] as int? ?? 0,
    mistakes: json['mistakes'] as int? ?? 0,
    gameType: json['gameType'] != null
        ? GameType.values.firstWhere((e) => e.id == json['gameType'], orElse: () => GameType.rubik)
        : null,
    rankTier: RankTier.values[(json['rankTier'] as int? ?? 0).clamp(0, RankTier.values.length - 1)],
  );
}
