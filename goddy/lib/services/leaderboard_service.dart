import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/game_result.dart';
import '../models/leaderboard_entry.dart';
import 'storage_service.dart';
import 'api_client.dart';

class LeaderboardService extends ChangeNotifier {
  static const String _keyGameHistory = 'goddy_game_history';

  final List<GameResult> _history = [];
  List<GameResult> get history => List.unmodifiable(_history);

  LeaderboardService() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await StorageService.init();
    final raw = StorageService.getStringList(_keyGameHistory) ?? [];
    _history.clear();
    for (final item in raw) {
      try {
        _history.add(GameResult.fromJson(jsonDecode(item)));
      } catch (e) {
        debugPrint('Error parsing game result: $e');
      }
    }
    notifyListeners();
  }

  // Score formula according to criteria:
  // Base 1000 - (Time in seconds * 3) - (Mistakes * 80) + Streak/Difficulty bonus
  int calculateScore({
    required GameType gameType,
    required int timeSeconds,
    required int mistakes,
    String difficulty = 'Normal',
  }) {
    int base = 1000;
    int diffMultiplier = 1;
    if (difficulty == 'Hard' || difficulty == 'Nightmare' || difficulty == 'Grandmaster') {
      diffMultiplier = 2;
      base = 1500;
    } else if (difficulty == 'Easy') {
      base = 800;
    }

    int timePenalty = timeSeconds * 2;
    int mistakePenalty = mistakes * 60;

    int total = (base - timePenalty - mistakePenalty) * diffMultiplier;
    return total < 50 ? 50 : total; // Minimum 50 score
  }

  Future<void> saveGameResult(GameResult result) async {
    _history.insert(0, result);
    final raw = _history.map((e) => jsonEncode(e.toJson())).toList();
    await StorageService.setStringList(_keyGameHistory, raw);
    notifyListeners();

    // Sync to WebAPI & SQLite
    try {
      final userJson = StorageService.getString('goddy_current_user');
      String userId = result.id;
      String username = 'Player';
      String avatar = '🎮';
      if (userJson != null) {
        try {
          final userData = jsonDecode(userJson);
          userId = userData['id'] ?? result.id;
          username = userData['username'] ?? 'Player';
          avatar = userData['avatar'] ?? '🎮';
        } catch (_) {}
      }

      await ApiClient().post('leaderboard/submit', {
        'userId': userId,
        'username': username,
        'avatar': avatar,
        'gameType': result.gameType.id,
        'score': result.score,
        'timeSeconds': result.timeSeconds,
        'mistakes': result.mistakes,
        'isWin': result.isWin,
        'difficulty': result.difficulty,
      });
    } catch (e) {
      debugPrint('WebAPI leaderboard submit error: $e');
    }
  }

  // Pre-configured rival players with dynamic user integration
  List<LeaderboardEntry> getLeaderboardFor(GameType? gameType, {LeaderboardEntry? currentUserEntry}) {
    List<LeaderboardEntry> entries = [];

    if (gameType == null) {
      // Global Leaderboard
      entries = [
        const LeaderboardEntry(rank: 1, userId: 'rival_1', username: 'ViperCyber', avatar: '⚡', score: 18450, rankTier: RankTier.grandmaster),
        const LeaderboardEntry(rank: 2, userId: 'rival_2', username: 'MatrixPhantom', avatar: '🥷', score: 14200, rankTier: RankTier.master),
        const LeaderboardEntry(rank: 3, userId: 'rival_3', username: 'NeonQueen', avatar: '👑', score: 11800, rankTier: RankTier.master),
        const LeaderboardEntry(rank: 4, userId: 'rival_4', username: 'QuantumGhost', avatar: '👻', score: 9200, rankTier: RankTier.diamond),
        const LeaderboardEntry(rank: 5, userId: 'rival_5', username: 'GoddyRacer', avatar: '🏎️', score: 7400, rankTier: RankTier.diamond),
        const LeaderboardEntry(rank: 6, userId: 'rival_6', username: 'PixelMaster', avatar: '🎯', score: 5800, rankTier: RankTier.platinum),
        const LeaderboardEntry(rank: 7, userId: 'rival_7', username: 'ZeroGravity', avatar: '🚀', score: 4100, rankTier: RankTier.gold),
      ];
    } else {
      switch (gameType) {
        case GameType.rubik:
          entries = [
            const LeaderboardEntry(rank: 1, userId: 'rival_r1', username: 'SpeedCuber_VN', avatar: '🧩', score: 2450, timeSeconds: 19, mistakes: 0, gameType: GameType.rubik),
            const LeaderboardEntry(rank: 2, userId: 'rival_r2', username: 'RubikGod', avatar: '🔥', score: 2180, timeSeconds: 27, mistakes: 1, gameType: GameType.rubik),
            const LeaderboardEntry(rank: 3, userId: 'rival_r3', username: 'NeonTurner', avatar: '⚡', score: 1950, timeSeconds: 38, mistakes: 2, gameType: GameType.rubik),
            const LeaderboardEntry(rank: 4, userId: 'rival_r4', username: 'CubeHero', avatar: '🤖', score: 1720, timeSeconds: 46, mistakes: 1, gameType: GameType.rubik),
            const LeaderboardEntry(rank: 5, userId: 'rival_r5', username: 'TwistMaster', avatar: '🌀', score: 1450, timeSeconds: 58, mistakes: 3, gameType: GameType.rubik),
          ];
          break;
        case GameType.caro:
          entries = [
            const LeaderboardEntry(rank: 1, userId: 'rival_c1', username: 'GrandmasterCaro', avatar: '🧠', score: 3200, timeSeconds: 140, mistakes: 1, gameType: GameType.caro),
            const LeaderboardEntry(rank: 2, userId: 'rival_c2', username: 'TacticalAI_Destroyer', avatar: '⚔️', score: 2890, timeSeconds: 175, mistakes: 2, gameType: GameType.caro),
            const LeaderboardEntry(rank: 3, userId: 'rival_c3', username: 'CaroNinja', avatar: '🥷', score: 2400, timeSeconds: 210, mistakes: 4, gameType: GameType.caro),
            const LeaderboardEntry(rank: 4, userId: 'rival_c4', username: 'FiveInRow', avatar: '⭕', score: 2050, timeSeconds: 240, mistakes: 3, gameType: GameType.caro),
          ];
          break;
        case GameType.sudoku:
          entries = [
            const LeaderboardEntry(rank: 1, userId: 'rival_s1', username: 'HologramBrain', avatar: '🔮', score: 2950, timeSeconds: 98, mistakes: 0, gameType: GameType.sudoku),
            const LeaderboardEntry(rank: 2, userId: 'rival_s2', username: 'MatrixSudoku', avatar: '🔢', score: 2600, timeSeconds: 135, mistakes: 1, gameType: GameType.sudoku),
            const LeaderboardEntry(rank: 3, userId: 'rival_s3', username: 'LogicSolver', avatar: '💡', score: 2210, timeSeconds: 180, mistakes: 1, gameType: GameType.sudoku),
            const LeaderboardEntry(rank: 4, userId: 'rival_s4', username: 'FastMath99', avatar: '📐', score: 1800, timeSeconds: 240, mistakes: 2, gameType: GameType.sudoku),
          ];
          break;
        case GameType.slidePuzzle:
          entries = [
            const LeaderboardEntry(rank: 1, userId: 'rival_p1', username: 'GyroSensoryKing', avatar: '📱', score: 2800, timeSeconds: 24, mistakes: 0, gameType: GameType.slidePuzzle),
            const LeaderboardEntry(rank: 2, userId: 'rival_p2', username: 'TiltSlidePro', avatar: '🎮', score: 2410, timeSeconds: 36, mistakes: 2, gameType: GameType.slidePuzzle),
            const LeaderboardEntry(rank: 3, userId: 'rival_p3', username: 'A_Star_Challenger', avatar: '🚀', score: 2100, timeSeconds: 48, mistakes: 3, gameType: GameType.slidePuzzle),
            const LeaderboardEntry(rank: 4, userId: 'rival_p4', username: 'PuzzleQueen', avatar: '✨', score: 1750, timeSeconds: 65, mistakes: 4, gameType: GameType.slidePuzzle),
          ];
          break;
      }
    }

    if (currentUserEntry != null) {
      entries.add(currentUserEntry);
      entries.sort((a, b) => b.score.compareTo(a.score));
      // Re-assign ranks
      for (int i = 0; i < entries.length; i++) {
        entries[i] = LeaderboardEntry(
          rank: i + 1,
          userId: entries[i].userId,
          username: entries[i].username,
          avatar: entries[i].avatar,
          score: entries[i].score,
          timeSeconds: entries[i].timeSeconds,
          mistakes: entries[i].mistakes,
          gameType: entries[i].gameType,
          rankTier: entries[i].rankTier,
        );
      }
    }

    return entries;
  }
}
