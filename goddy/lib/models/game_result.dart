import '../core/constants.dart';

class GameResult {
  final String id;
  final GameType gameType;
  final int score;
  final int timeSeconds;
  final int mistakes;
  final bool isWin;
  final String difficulty;
  final DateTime timestamp;

  GameResult({
    required this.id,
    required this.gameType,
    required this.score,
    required this.timeSeconds,
    required this.mistakes,
    required this.isWin,
    this.difficulty = 'Normal',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'gameType': gameType.id,
    'score': score,
    'timeSeconds': timeSeconds,
    'mistakes': mistakes,
    'isWin': isWin,
    'difficulty': difficulty,
    'timestamp': timestamp.toIso8601String(),
  };

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
    id: json['id'] as String? ?? '',
    gameType: GameType.values.firstWhere(
      (e) => e.id == json['gameType'],
      orElse: () => GameType.rubik,
    ),
    score: json['score'] as int? ?? 0,
    timeSeconds: json['timeSeconds'] as int? ?? 0,
    mistakes: json['mistakes'] as int? ?? 0,
    isWin: json['isWin'] as bool? ?? false,
    difficulty: json['difficulty'] as String? ?? 'Normal',
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );

  String get formattedTime {
    final mins = (timeSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (timeSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
