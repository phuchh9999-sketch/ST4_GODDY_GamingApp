import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/game_result.dart';
import '../../../services/auth_service.dart';
import '../../../services/leaderboard_service.dart';
import '../../../services/game_save_service.dart';
import '../../../services/challenge_service.dart';
import '../../../models/challenge_room.dart';
import 'sudoku_generator.dart';
import 'sudoku_solver_ai.dart';

class SudokuScreen extends StatefulWidget {
  final int? duelSeed;
  final String? duelRoomCode;
  final Function(int seconds, int mistakes, int score)? onDuelFinish;

  const SudokuScreen({
    super.key,
    this.duelSeed,
    this.duelRoomCode,
    this.onDuelFinish,
  });

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  String _difficulty = 'Medium'; // Easy, Medium, Hard, Nightmare
  late List<List<int>> _initialBoard;
  late List<List<int>> _currentBoard;
  late List<List<int>> _solution;

  int _selectedRow = 4;
  int _selectedCol = 4;
  int _lives = 3;
  int _mistakes = 0;
  int _comboStreak = 0;
  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _duelSyncTimer;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    if (widget.duelSeed != null) {
      _startNewGame();
    } else {
      final saved = GameSaveService.getSavedSudoku();
      if (saved != null) {
        _resumeSavedGame(saved);
      } else {
        _startNewGame();
      }
    }
    if (widget.duelRoomCode != null) {
      _startDuelSync();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _duelSyncTimer?.cancel();
    super.dispose();
  }

  void _startDuelSync() {
    if (widget.duelRoomCode == null) return;
    _duelSyncTimer?.cancel();
    _duelSyncTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || _isGameOver) return;
      final challenge = context.read<ChallengeService>();
      final room = challenge.currentRoom;
      if (room == null) return;

      final auth = context.read<AuthService>();
      final myUserId = auth.currentUser?.id;

      final isHost = room.hostId == myUserId;
      final opponentFinished = isHost
          ? (room.guestScore > 0 || room.guestResult != null)
          : (room.hostScore > 0 || room.hostResult != null);

      if (room.status == RoomStatus.finished || opponentFinished) {
        _isGameOver = true;
        _timer?.cancel();
        _duelSyncTimer?.cancel();

        final opponentName = isHost ? (room.guestName ?? 'Đối thủ') : room.hostName;
        final opponentTime = isHost ? room.guestTimeSeconds : room.hostTimeSeconds;

        _showDuelFinishedByOpponent(opponentName, opponentTime);
      }
    });
  }

  void _showDuelFinishedByOpponent(String opponentName, int opponentTime) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GoddyTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: GoddyTheme.neonAmber, width: 2),
        ),
        title: Center(
          child: Column(
            children: [
              const Icon(Icons.emoji_events_outlined, color: GoddyTheme.neonAmber, size: 54),
              const SizedBox(height: 8),
              Text(
                'ĐỐI THỦ ĐÃ HOÀN THÀNH!',
                style: GoogleFonts.orbitron(color: GoddyTheme.neonAmber, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Đối thủ [$opponentName] đã hoàn thành Sudoku trước bạn với thời gian ${opponentTime}s!\n\nBạn muốn tiếp tục hay quay về sảnh?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GoddyTheme.neonAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GoddyTheme.neonAmber),
              ),
              child: const Text('Điểm an ủi: +20 PTS', style: TextStyle(color: GoddyTheme.neonAmber, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: GoddyTheme.neonCyan,
              side: const BorderSide(color: GoddyTheme.neonCyan),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // Tiếp tục: Cho phép người chơi tự giải nốt bàn cờ của mình
              _isGameOver = false;
              _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (mounted && !_isGameOver) {
                  setState(() => _secondsElapsed++);
                }
              });
            },
            child: const Text('Tiếp tục'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GoddyTheme.neonCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, 'lobby'); // Quay về sảnh phòng đấu
            },
            child: const Text('Quay về sảnh', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _resumeSavedGame(Map<String, dynamic> saved) {
    _timer?.cancel();
    _difficulty = saved['difficulty'] as String? ?? 'Medium';
    _initialBoard = (saved['initialBoard'] as List)
        .map((r) => (r as List).map((c) => c as int).toList())
        .toList();
    _currentBoard = (saved['currentBoard'] as List)
        .map((r) => (r as List).map((c) => c as int).toList())
        .toList();
    _solution = (saved['solution'] as List)
        .map((r) => (r as List).map((c) => c as int).toList())
        .toList();
    _secondsElapsed = saved['secondsElapsed'] as int? ?? 0;
    _mistakes = saved['mistakes'] as int? ?? 0;
    _lives = saved['lives'] as int? ?? 3;
    _selectedRow = 4;
    _selectedCol = 4;
    _comboStreak = 0;
    _isGameOver = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isGameOver) {
        setState(() => _secondsElapsed++);
        if (_secondsElapsed % 5 == 0) {
          _autoSave();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📂 Đã tự động khôi phục tiến độ ván Sudoku trước đó!'),
          backgroundColor: GoddyTheme.neonCyan,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _autoSave() {
    if (!_isGameOver) {
      GameSaveService.saveSudokuProgress(
        initialBoard: _initialBoard,
        currentBoard: _currentBoard,
        solution: _solution,
        difficulty: _difficulty,
        secondsElapsed: _secondsElapsed,
        mistakes: _mistakes,
        lives: _lives,
      );
    }
  }

  void _startNewGame() {
    _timer?.cancel();
    GameSaveService.clearSudokuSave();
    final data = SudokuGenerator.generate(_difficulty, widget.duelSeed);
    _initialBoard = List.generate(9, (r) => List<int>.from(data.puzzle[r]));
    _currentBoard = List.generate(9, (r) => List<int>.from(data.puzzle[r]));
    _solution = data.solution;

    _selectedRow = 4;
    _selectedCol = 4;
    _lives = 3;
    _mistakes = 0;
    _comboStreak = 0;
    _secondsElapsed = 0;
    _isGameOver = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isGameOver) {
        setState(() => _secondsElapsed++);
        if (_secondsElapsed % 5 == 0) {
          _autoSave();
        }
      }
    });
  }

  void _handleNumberInput(int number) {
    if (_isGameOver) return;
    if (_initialBoard[_selectedRow][_selectedCol] != 0) return; // Clue cell cannot be changed

    final correctNumber = _solution[_selectedRow][_selectedCol];

    if (number == correctNumber) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentBoard[_selectedRow][_selectedCol] = number;
        _comboStreak++;
      });

      // Check win condition
      if (_checkCompleted()) {
        _endGame(isWin: true);
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _lives--;
        _mistakes++;
        _comboStreak = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Số $number không chính xác! Bị trừ 1 Mạng!'),
          backgroundColor: GoddyTheme.neonRed,
          duration: const Duration(milliseconds: 900),
        ),
      );

      if (_lives <= 0) {
        _endGame(isWin: false);
      }
    }
  }

  void _handleErase() {
    if (_isGameOver) return;
    if (_initialBoard[_selectedRow][_selectedCol] == 0) {
      setState(() {
        _currentBoard[_selectedRow][_selectedCol] = 0;
      });
    }
  }

  void _handleAiHint() {
    if (_isGameOver) return;
    final hint = SudokuSolverAi.findNextLogicHint(_currentBoard, _solution);
    if (hint != null) {
      setState(() {
        _selectedRow = hint.row;
        _selectedCol = hint.col;
        _currentBoard[hint.row][hint.col] = hint.number;
        _mistakes++; // Using hint counts as 1 penalty mistake
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: GoddyTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GoddyTheme.neonCyan, width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.psychology, color: GoddyTheme.neonCyan),
              const SizedBox(width: 8),
              Text(
                'AI LOGIC DEDUCTION',
                style: GoogleFonts.orbitron(
                  color: GoddyTheme.neonCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            hint.logicReasonVi,
            style: const TextStyle(color: GoddyTheme.textPrimary, fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: GoddyTheme.neonCyan, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu!'),
            ),
          ],
        ),
      );

      if (_checkCompleted()) {
        _endGame(isWin: true);
      }
    }
  }

  bool _checkCompleted() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_currentBoard[r][c] != _solution[r][c]) {
          return false;
        }
      }
    }
    return true;
  }

  void _endGame({required bool isWin}) {
    _isGameOver = true;
    _timer?.cancel();
    GameSaveService.clearSudokuSave();

    final auth = context.read<AuthService>();
    final leaderboard = context.read<LeaderboardService>();

    final score = isWin
        ? leaderboard.calculateScore(
            gameType: GameType.sudoku,
            timeSeconds: _secondsElapsed,
            mistakes: _mistakes,
            difficulty: _difficulty,
          )
        : 50;

    final result = GameResult(
      id: 'sudoku_${DateTime.now().millisecondsSinceEpoch}',
      gameType: GameType.sudoku,
      score: score,
      timeSeconds: _secondsElapsed,
      mistakes: _mistakes,
      isWin: isWin,
      difficulty: 'Hologram $_difficulty',
    );

    leaderboard.saveGameResult(result);
    auth.recordGameWin(
      isWin: isWin,
      expGained: isWin ? (score * 0.2).toInt() : 25,
      sudokuSecs: _secondsElapsed,
    );

    if (widget.onDuelFinish != null) {
      widget.onDuelFinish!(_secondsElapsed, _mistakes, score);
    }

    _showResultDialog(isWin, score);
  }

  void _showResultDialog(bool isWin, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GoddyTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isWin ? GoddyTheme.neonGreen : GoddyTheme.neonRed, width: 2),
        ),
        title: Center(
          child: Column(
            children: [
              Icon(
                isWin ? Icons.celebration : Icons.sentiment_very_dissatisfied,
                color: isWin ? GoddyTheme.neonAmber : GoddyTheme.neonRed,
                size: 54,
              ),
              const SizedBox(height: 8),
              Text(
                isWin ? 'SUDOKU HOÀN TẤT!' : 'GAME OVER (HẾT MẠNG)',
                style: GoogleFonts.orbitron(
                  color: isWin ? GoddyTheme.neonGreen : GoddyTheme.neonRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Thời gian giải:', '${_secondsElapsed}s', GoddyTheme.neonGreen),
            _buildStatRow('Số lỗi phạm:', '$_mistakes', GoddyTheme.neonRed),
            _buildStatRow('Cấp độ:', _difficulty, GoddyTheme.neonPurple),
            const Divider(color: Colors.white24, height: 24),
            _buildStatRow('Điểm thưởng:', '+$score PTS', GoddyTheme.neonAmber, isBold: true),
          ],
        ),
        actions: [
          if (widget.onDuelFinish != null) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: GoddyTheme.neonCyan,
                side: const BorderSide(color: GoddyTheme.neonCyan),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, 'lobby'); // Quay về sảnh phòng đấu
              },
              child: const Text('Quay về sảnh'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GoddyTheme.neonCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<ChallengeService>().leaveRoom();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Về Trang Chọn Game', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _startNewGame());
              },
              child: const Text('Chơi Ván Mới', style: TextStyle(color: GoddyTheme.neonCyan)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GoddyTheme.neonCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Về Menu', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: GoddyTheme.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: valColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackPress(BuildContext context) async {
    // 1. Nếu ván đấu đã kết thúc:
    if (_isGameOver) {
      if (widget.onDuelFinish != null) {
        // Trong chế độ thách đấu, bấm quay về sẽ trở về sảnh phòng đấu
        Navigator.pop(context, 'lobby');
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      return;
    }

    // 2. Nếu đang trong chế độ thách đấu 1v1:
    if (widget.onDuelFinish != null) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: GoddyTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GoddyTheme.neonCyan, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.exit_to_app, color: GoddyTheme.neonAmber, size: 24),
              const SizedBox(width: 8),
              Text(
                'XÁC NHẬN THOÁT',
                style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'Bạn đang trong trận đấu Sudoku 1v1. Bạn muốn tiếp tục giải, quay về sảnh phòng đấu hay thoát hẳn?',
            style: TextStyle(color: GoddyTheme.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'continue'),
              child: const Text('Tiếp tục chơi', style: TextStyle(color: GoddyTheme.textMuted)),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: GoddyTheme.neonCyan,
                side: const BorderSide(color: GoddyTheme.neonCyan),
              ),
              onPressed: () => Navigator.pop(ctx, 'lobby'),
              child: const Text('Quay về sảnh'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GoddyTheme.neonRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, 'home'),
              child: const Text('Thoát hẳn', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      if (action == 'lobby') {
        Navigator.pop(context, 'lobby');
      } else if (action == 'home') {
        context.read<ChallengeService>().leaveRoom();
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      return;
    }

    // 3. Chế độ Solo chơi đơn bình thường:
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GoddyTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GoddyTheme.neonCyan, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app, color: GoddyTheme.neonAmber, size: 24),
            const SizedBox(width: 8),
            Text(
              'XÁC NHẬN THOÁT',
              style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn thoát về trang chọn game không? Tiến trình ván chơi sẽ được lưu lại.',
          style: TextStyle(color: GoddyTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: GoddyTheme.neonCyan,
              side: const BorderSide(color: GoddyTheme.neonCyan),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tiếp tục chơi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GoddyTheme.neonRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thoát về trang chọn game', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackPress(context);
        }
      },
      child: Scaffold(
        backgroundColor: GoddyTheme.bgDark,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Quay về trang chọn game',
            onPressed: () => _handleBackPress(context),
          ),
        title: Text(
          'SUDOKU HOLOGRAM',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Chọn cấp độ',
            icon: const Icon(Icons.tune, color: GoddyTheme.neonCyan),
            onSelected: (val) {
              setState(() {
                _difficulty = val;
                _startNewGame();
              });
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'Easy', child: Text('Dễ (Easy)')),
              const PopupMenuItem(value: 'Medium', child: Text('Vừa (Medium)')),
              const PopupMenuItem(value: 'Hard', child: Text('Khó (Hard)')),
              const PopupMenuItem(value: 'Nightmare', child: Text('Ác mộng (Nightmare)')),
            ],
          ),
          IconButton(
            tooltip: 'Ván mới',
            icon: const Icon(Icons.refresh, color: GoddyTheme.neonRed),
            onPressed: () => setState(() => _startNewGame()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: [
              // HUD Lives & Stats Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: GoddyTheme.glowBox(
                  borderColor: GoddyTheme.neonCyan,
                  bgColor: GoddyTheme.bgCard,
                  radius: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Lives Indicator
                    Row(
                      children: List.generate(3, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            i < _lives ? Icons.favorite : Icons.favorite_border,
                            color: GoddyTheme.neonRed,
                            size: 20,
                          ),
                        );
                      }),
                    ),

                    // Timer
                    Text(
                      '⏱️ ${_secondsElapsed}s',
                      style: GoogleFonts.orbitron(
                        color: GoddyTheme.neonGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    // Combo Streak
                    Text(
                      '🔥 x$_comboStreak',
                      style: GoogleFonts.orbitron(
                        color: GoddyTheme.neonAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Sudoku Hologram 9x9 Matrix Grid
              Center(
                child: Container(
                  width: 340,
                  height: 340,
                  padding: const EdgeInsets.all(4),
                  decoration: GoddyTheme.glowBox(
                    borderColor: GoddyTheme.neonCyan,
                    bgColor: const Color(0xFF0C1322),
                    radius: 16,
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 81,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 9,
                      crossAxisSpacing: 1.5,
                      mainAxisSpacing: 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final r = index ~/ 9;
                      final c = index % 9;
                      return _buildSudokuCell(r, c);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action Toolbar: AI Hint, Erase, Undo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: GoddyTheme.neonCyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.lightbulb_outline, color: GoddyTheme.neonCyan, size: 18),
                    label: const Text('Gợi Ý AI Logic', style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: _handleAiHint,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: GoddyTheme.neonRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.backspace_outlined, color: GoddyTheme.neonRed, size: 18),
                    label: const Text('Xóa Ô', style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: _handleErase,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Numpad 1-9
              _buildNumpad(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSudokuCell(int r, int c) {
    final val = _currentBoard[r][c];
    final isInitial = _initialBoard[r][c] != 0;
    final isSelected = r == _selectedRow && c == _selectedCol;

    // Holographic Spectrum highlighting
    final selectedVal = _currentBoard[_selectedRow][_selectedCol];
    final isInRowOrCol = r == _selectedRow || c == _selectedCol;
    final isIn3x3Box = (r ~/ 3 == _selectedRow ~/ 3) && (c ~/ 3 == _selectedCol ~/ 3);
    final isSameNumber = selectedVal != 0 && val == selectedVal;

    Color cellBg = const Color(0xFF141C30);
    if (isSelected) {
      cellBg = GoddyTheme.neonCyan.withValues(alpha: 0.4);
    } else if (isSameNumber) {
      cellBg = GoddyTheme.neonPurple.withValues(alpha: 0.35);
    } else if (isInRowOrCol || isIn3x3Box) {
      cellBg = const Color(0xFF1B2844);
    }

    // Border highlights for 3x3 blocks
    final bool isRightBlockEdge = (c + 1) % 3 == 0 && c != 8;
    final bool isBottomBlockEdge = (r + 1) % 3 == 0 && r != 8;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRow = r;
          _selectedCol = c;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(3),
          border: Border(
            right: BorderSide(
              color: isRightBlockEdge ? GoddyTheme.neonCyan.withValues(alpha: 0.6) : Colors.white10,
              width: isRightBlockEdge ? 1.5 : 0.5,
            ),
            bottom: BorderSide(
              color: isBottomBlockEdge ? GoddyTheme.neonCyan.withValues(alpha: 0.6) : Colors.white10,
              width: isBottomBlockEdge ? 1.5 : 0.5,
            ),
          ),
        ),
        child: Center(
          child: val != 0
              ? Text(
                  '$val',
                  style: GoogleFonts.orbitron(
                    color: isInitial ? Colors.white : GoddyTheme.neonCyan,
                    fontWeight: isInitial ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(9, (idx) {
        final num = idx + 1;
        return SizedBox(
          width: 58,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2640),
              foregroundColor: GoddyTheme.neonCyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: GoddyTheme.neonCyan.withValues(alpha: 0.3)),
              ),
              padding: EdgeInsets.zero,
            ),
            onPressed: () => _handleNumberInput(num),
            child: Text(
              '$num',
              style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }),
    );
  }
}
