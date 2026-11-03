import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/game_result.dart';
import '../../../services/auth_service.dart';
import '../../../services/leaderboard_service.dart';
import '../../../services/game_save_service.dart';
import '../../../services/challenge_service.dart';
import '../../../models/challenge_room.dart';
import 'puzzle_solver_a_star.dart';

class SlidePuzzleScreen extends StatefulWidget {
  final int? duelSeed;
  final String? duelRoomCode;
  final Function(int seconds, int moves)? onDuelFinish;

  const SlidePuzzleScreen({
    super.key,
    this.duelSeed,
    this.duelRoomCode,
    this.onDuelFinish,
  });

  @override
  State<SlidePuzzleScreen> createState() => _SlidePuzzleScreenState();
}

class _SlidePuzzleScreenState extends State<SlidePuzzleScreen> {
  int _size = 3; // 3x3 or 4x4
  late List<int> _board;

  int _moves = 0;
  int _mistakes = 0;
  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _duelSyncTimer;
  bool _isGameOver = false;

  // Gyroscope / Tilt support
  bool _isGyroEnabled = true;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  DateTime _lastTiltTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.duelSeed != null) {
      _initGame();
    } else {
      final saved = GameSaveService.getSavedPuzzle();
      if (saved != null) {
        _resumeSavedGame(saved);
      } else {
        _initGame();
      }
    }
    _initSensors();
    if (widget.duelRoomCode != null) {
      _startDuelSync();
    }
  }

  void _resumeSavedGame(Map<String, dynamic> saved) {
    _timer?.cancel();
    _board = (saved['board'] as List).map((e) => e as int).toList();
    _size = saved['size'] as int? ?? 3;
    _moves = saved['moves'] as int? ?? 0;
    _mistakes = saved['mistakes'] as int? ?? 0;
    _secondsElapsed = saved['secondsElapsed'] as int? ?? 0;
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
          content: Text('📂 Đã tự động khôi phục tiến độ ván Xếp hình trước đó!'),
          backgroundColor: GoddyTheme.neonCyan,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _autoSave() {
    if (!_isGameOver) {
      GameSaveService.savePuzzleProgress(
        board: _board,
        size: _size,
        moves: _moves,
        mistakes: _mistakes,
        secondsElapsed: _secondsElapsed,
      );
    }
  }

  void _initGame() {
    _timer?.cancel();
    GameSaveService.clearPuzzleSave();
    _board = PuzzleSolverAStar.generateSolvableBoard(_size, widget.duelSeed);
    _moves = 0;
    _mistakes = 0;
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

  @override
  void dispose() {
    _timer?.cancel();
    _sensorSubscription?.cancel();
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
        _sensorSubscription?.cancel();
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
              'Đối thủ [$opponentName] đã xếp hoàn tất dãy số trước bạn với thời gian ${opponentTime}s!\n\nBạn muốn tiếp tục hay quay về sảnh?',
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
              // Tiếp tục: Cho phép người chơi tự trượt xếp nốt câu đố
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

  void _initSensors() {
    try {
      _sensorSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (!_isGyroEnabled || _isGameOver) return;

        final now = DateTime.now();
        if (now.difference(_lastTiltTime).inMilliseconds < 450) return; // Debounce tilt

        const threshold = 3.5;
        // event.x: tilt left/right (positive = tilted left, negative = tilted right)
        // event.y: tilt up/down (positive = tilted down, negative = tilted up)
        if (event.x > threshold) {
          _tiltMove('LEFT'); // Phone tilted left -> tiles slide LEFT
          _lastTiltTime = now;
        } else if (event.x < -threshold) {
          _tiltMove('RIGHT'); // Phone tilted right -> tiles slide RIGHT
          _lastTiltTime = now;
        } else if (event.y > threshold) {
          _tiltMove('DOWN'); // Phone tilted downwards -> tiles slide DOWN
          _lastTiltTime = now;
        } else if (event.y < -threshold) {
          _tiltMove('UP'); // Phone tilted upwards -> tiles slide UP
          _lastTiltTime = now;
        }
      });
    } catch (e) {
      debugPrint('Sensor not supported or simulator: $e');
    }
  }

  void _tiltMove(String direction) {
    final emptyIndex = _board.indexOf(0);
    final emptyR = emptyIndex ~/ _size;
    final emptyC = emptyIndex % _size;

    int? targetIndex;
    if (direction == 'UP' && emptyR < _size - 1) {
      targetIndex = (emptyR + 1) * _size + emptyC;
    } else if (direction == 'DOWN' && emptyR > 0) {
      targetIndex = (emptyR - 1) * _size + emptyC;
    } else if (direction == 'LEFT' && emptyC < _size - 1) {
      targetIndex = emptyR * _size + (emptyC + 1);
    } else if (direction == 'RIGHT' && emptyC > 0) {
      targetIndex = emptyR * _size + (emptyC - 1);
    }

    if (targetIndex != null) {
      _handleTileTap(targetIndex);
    }
  }

  void _handleTileTap(int index) {
    if (_isGameOver) return;

    final emptyIndex = _board.indexOf(0);
    final emptyR = emptyIndex ~/ _size;
    final emptyC = emptyIndex % _size;
    final tileR = index ~/ _size;
    final tileC = index % _size;

    // Check if adjacent
    final isAdjacent = (emptyR == tileR && (emptyC - tileC).abs() == 1) ||
        (emptyC == tileC && (emptyR - tileR).abs() == 1);

    if (isAdjacent) {
      HapticFeedback.selectionClick();
      setState(() {
        _board[emptyIndex] = _board[index];
        _board[index] = 0;
        _moves++;
      });

      if (_checkSolved()) {
        _endGame();
      }
    } else {
      HapticFeedback.lightImpact();
      setState(() => _mistakes++);
    }
  }

  void _handleAiStep() {
    if (_isGameOver) return;
    final bestMoveIndex = PuzzleSolverAStar.findNextBestMove(_board, _size);
    _handleTileTap(bestMoveIndex);
  }

  bool _checkSolved() {
    for (int i = 0; i < _board.length - 1; i++) {
      if (_board[i] != i + 1) return false;
    }
    return _board.last == 0;
  }

  void _endGame() {
    _isGameOver = true;
    _timer?.cancel();
    GameSaveService.clearPuzzleSave();

    final auth = context.read<AuthService>();
    final leaderboard = context.read<LeaderboardService>();

    final score = leaderboard.calculateScore(
      gameType: GameType.slidePuzzle,
      timeSeconds: _secondsElapsed,
      mistakes: _mistakes,
      difficulty: '${_size}x$_size Gyro',
    );

    final result = GameResult(
      id: 'puzzle_${DateTime.now().millisecondsSinceEpoch}',
      gameType: GameType.slidePuzzle,
      score: score,
      timeSeconds: _secondsElapsed,
      mistakes: _mistakes,
      isWin: true,
      difficulty: 'Tilt ${_size}x$_size',
    );

    leaderboard.saveGameResult(result);
    auth.recordGameWin(
      isWin: true,
      expGained: (score * 0.2).toInt(),
      puzzleSecs: _secondsElapsed,
    );

    if (widget.onDuelFinish != null) {
      widget.onDuelFinish!(_secondsElapsed, _moves);
    }

    _showVictoryDialog(score);
  }

  void _showVictoryDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GoddyTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: GoddyTheme.neonCyan, width: 2),
        ),
        title: Center(
          child: Column(
            children: [
              const Icon(Icons.stars, color: GoddyTheme.neonAmber, size: 54),
              const SizedBox(height: 8),
              Text(
                'HOÀN THÀNH XẾP HÌNH!',
                style: GoogleFonts.orbitron(
                  color: GoddyTheme.neonCyan,
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
            _buildStatRow('Số lượt trượt:', '$_moves', GoddyTheme.neonBlue),
            _buildStatRow('Trượt lỗi (Mistakes):', '$_mistakes', GoddyTheme.neonRed),
            _buildStatRow('Chế độ:', '${_size}x$_size Gyro Tilt', GoddyTheme.neonPurple),
            const Divider(color: Colors.white24, height: 24),
            _buildStatRow('Điểm thưởng Rank:', '+$score PTS', GoddyTheme.neonAmber, isBold: true),
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
                setState(() => _initGame());
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
            'Bạn đang trong trận đấu Xếp hình 1v1. Bạn muốn tiếp tục giải, quay về sảnh phòng đấu hay thoát hẳn?',
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
          'Bạn có chắc chắn muốn thoát về trang chọn game không? Bàn cờ hiện tại sẽ được lưu lại.',
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
    final manhattan = PuzzleSolverAStar.calculateManhattan(_board, _size);

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
          'GYRO TILT PUZZLE',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Đổi kích thước 3x3 / 4x4',
            icon: Icon(_size == 3 ? Icons.grid_3x3 : Icons.grid_4x4, color: GoddyTheme.neonAmber),
            onPressed: () {
              setState(() {
                _size = _size == 3 ? 4 : 3;
                _initGame();
              });
            },
          ),
          IconButton(
            tooltip: 'Trộn lại',
            icon: const Icon(Icons.refresh, color: GoddyTheme.neonRed),
            onPressed: () => setState(() => _initGame()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: [
              // HUD Stats Bar
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
                    _buildHudItem(Icons.timer_outlined, '${_secondsElapsed}s', 'THỜI GIAN', GoddyTheme.neonGreen),
                    _buildHudItem(Icons.swap_horiz, '$_moves', 'BƯỚC TRƯỢT', GoddyTheme.neonBlue),
                    _buildHudItem(Icons.error_outline, '$_mistakes', 'LỖI PHẠM', GoddyTheme.neonRed),
                    _buildHudItem(Icons.route, '$manhattan', 'A* KHOẢNG CÁCH', GoddyTheme.neonMagenta),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Gyro Sensor Mode Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GoddyTheme.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.screen_rotation,
                          color: _isGyroEnabled ? GoddyTheme.neonGreen : GoddyTheme.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isGyroEnabled ? 'CẢM BIẾN NGHIÊNG: BẬT' : 'CẢM BIẾN NGHIÊNG: TẮT',
                          style: TextStyle(
                            color: _isGyroEnabled ? GoddyTheme.neonGreen : GoddyTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isGyroEnabled,
                      activeThumbColor: GoddyTheme.neonGreen,
                      onChanged: (val) => setState(() => _isGyroEnabled = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Puzzle Grid Board
              Center(
                child: Container(
                  width: 320,
                  height: 320,
                  padding: const EdgeInsets.all(6),
                  decoration: GoddyTheme.glowBox(
                    borderColor: GoddyTheme.neonCyan,
                    bgColor: const Color(0xFF0C1322),
                    radius: 16,
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _size * _size,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _size,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemBuilder: (context, index) {
                      final val = _board[index];
                      if (val == 0) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                        );
                      }

                      return InkWell(
                        onTap: () => _handleTileTap(index),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: GoddyTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: GoddyTheme.neonCyan.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$val',
                              style: GoogleFonts.orbitron(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: _size == 3 ? 24 : 18,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Simulated Gyro Joystick / D-Pad for emulator or desktop testing
              const Text(
                'Nghiêng điện thoại HOẶC chạm phím D-Pad bên dưới để trượt gạch:',
                style: TextStyle(color: GoddyTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTiltButton(Icons.arrow_back, () => _tiltMove('LEFT')),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      _buildTiltButton(Icons.arrow_upward, () => _tiltMove('UP')),
                      const SizedBox(height: 6),
                      _buildTiltButton(Icons.arrow_downward, () => _tiltMove('DOWN')),
                    ],
                  ),
                  const SizedBox(width: 8),
                  _buildTiltButton(Icons.arrow_forward, () => _tiltMove('RIGHT')),
                ],
              ),

              const SizedBox(height: 14),

              // A* Optimal AI Solver Step Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: GoddyTheme.neonMagenta, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.auto_fix_high, color: GoddyTheme.neonMagenta),
                  label: const Text(
                    'AI A* GỢI Ý BƯỚC ĐI TỐI ƯU',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _handleAiStep,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildHudItem(IconData icon, String value, String title, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.orbitron(color: color, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _buildTiltButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 46,
      height: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF162035),
          foregroundColor: GoddyTheme.neonCyan,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.white12),
          ),
        ),
        onPressed: onPressed,
        child: Icon(icon, size: 20),
      ),
    );
  }
}
