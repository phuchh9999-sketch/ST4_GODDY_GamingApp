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

  final Map<String, List<LeaderboardEntry>> _remoteEntries = {};
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  LeaderboardService() {
    _loadHistory();
    fetchRemoteLeaderboard();
  }

  Future<void> fetchRemoteLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Tong Hop (Global theo EXP / tat ca diem nguoi dung)
      final resGlobal = await ApiClient().get('leaderboard');
      if (resGlobal != null && resGlobal.statusCode == 200) {
        final list = jsonDecode(utf8.decode(resGlobal.bodyBytes)) as List<dynamic>;
        _remoteEntries['global'] = list
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // 2. Fetch theo tung tro choi thuc te
      for (final gt in GameType.values) {
        final res = await ApiClient().get('leaderboard?gameType=${gt.id}');
        if (res != null && res.statusCode == 200) {
          final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
          _remoteEntries[gt.id] = list
              .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching remote leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  // Lay bang xep hang thuc te tu CSDL WebAPI & SQLite
  List<LeaderboardEntry> getLeaderboardFor(GameType? gameType, {LeaderboardEntry? currentUserEntry}) {
    List<LeaderboardEntry> entries = [];
    final key = gameType?.id ?? 'global';

    // 1. Uu tien tuyet doi lay du lieu nguoi choi thuc te tu CSDL
    if (_remoteEntries.containsKey(key) && _remoteEntries[key]!.isNotEmpty) {
      entries = List<LeaderboardEntry>.from(_remoteEntries[key]!);
    } else {
      // Du lieu du phong neu chua ket noi mang
      if (gameType == null) {
        entries = [
          const LeaderboardEntry(rank: 1, userId: 'rival_1', username: 'ViperCyber', avatar: '⚡', score: 18450, rankTier: RankTier.grandmaster),
          const LeaderboardEntry(rank: 2, userId: 'rival_2', username: 'MatrixPhantom', avatar: '🥷', score: 14200, rankTier: RankTier.master),
          const LeaderboardEntry(rank: 3, userId: 'rival_3', username: 'NeonQueen', avatar: '👑', score: 11800, rankTier: RankTier.master),
        ];
      } else {
        switch (gameType) {
          case GameType.rubik:
            entries = [
              const LeaderboardEntry(rank: 1, userId: 'rival_r1', username: 'SpeedCuber_VN', avatar: '🧩', score: 2450, timeSeconds: 19, mistakes: 0, gameType: GameType.rubik),
              const LeaderboardEntry(rank: 2, userId: 'rival_r2', username: 'RubikGod', avatar: '🔥', score: 2180, timeSeconds: 27, mistakes: 1, gameType: GameType.rubik),
            ];
            break;
          case GameType.caro:
            entries = [
              const LeaderboardEntry(rank: 1, userId: 'rival_c1', username: 'GrandmasterCaro', avatar: '🧠', score: 3200, timeSeconds: 140, mistakes: 1, gameType: GameType.caro),
            ];
            break;
          case GameType.sudoku:
            entries = [
              const LeaderboardEntry(rank: 1, userId: 'rival_s1', username: 'HologramBrain', avatar: '🔮', score: 2950, timeSeconds: 98, mistakes: 0, gameType: GameType.sudoku),
            ];
            break;
          case GameType.slidePuzzle:
            entries = [
              const LeaderboardEntry(rank: 1, userId: 'rival_p1', username: 'GyroSensoryKing', avatar: '📱', score: 2800, timeSeconds: 24, mistakes: 0, gameType: GameType.slidePuzzle),
            ];
            break;
        }
      }
    }

    if (currentUserEntry != null) {
      final exists = entries.any((e) => 
          (e.userId.isNotEmpty && e.userId == currentUserEntry.userId) || 
          e.username.toLowerCase() == currentUserEntry.username.replaceAll(' (Bạn)', '').toLowerCase());
      
      if (!exists) {
        entries.add(currentUserEntry);
      }
      entries.sort((a, b) => b.score.compareTo(a.score));
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
