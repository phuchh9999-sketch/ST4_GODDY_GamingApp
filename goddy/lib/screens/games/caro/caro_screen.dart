import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/game_result.dart';
import '../../../models/challenge_room.dart';
import '../../../services/auth_service.dart';
import '../../../services/leaderboard_service.dart';
import '../../../services/challenge_service.dart';
import '../../../services/game_save_service.dart';
import 'caro_ai_engine.dart';

class CaroScreen extends StatefulWidget {
  final String? duelRoomCode;
  final bool isHost;
  final void Function(bool isWin, int seconds, int score)? onDuelFinish;

  const CaroScreen({
    super.key,
    this.duelRoomCode,
    this.isHost = true,
    this.onDuelFinish,
  });

  @override
  State<CaroScreen> createState() => _CaroScreenState();
}

class _CaroScreenState extends State<CaroScreen> {
  static const int boardSize = 11;
  late List<List<int>> _board;

  bool _isPlayerTurn = true;
  bool _isGameOver = false;
  String _difficulty = 'Medium'; // Easy, Medium, Grandmaster
  int _movesCount = 0;
  int _mistakes = 0;
  int _totalSeconds = 0;
  Timer? _gameTimer;

  // 15-second turn countdown
  int _turnSeconds = 15;
  Timer? _turnTimer;

  // Cyber Skills
  int _quantumSwapCharges = 1;
  int _empFreezeCharges = 1;
  bool _isSwapSelectingFirst = false;
  CaroMove? _swapSelectedMove;
  bool _isEmpSelecting = false;

  // Real-Time 1v1 Multiplayer Duel
  bool get _isDuelMode => widget.duelRoomCode != null;
  int get _myPlayerMark => widget.isHost ? CaroAiEngine.playerX : CaroAiEngine.playerO;
  int get _opponentMark => widget.isHost ? CaroAiEngine.playerO : CaroAiEngine.playerX;
  Timer? _duelSyncTimer;
  String _lastProcessedMoveJson = '';

  @override
  void initState() {
    super.initState();
    if (_isDuelMode) {
      _initBoard();
      _isPlayerTurn = widget.isHost; // Host đánh trước
      _startGameTimer();
      if (_isPlayerTurn) {
        _startTurnTimer();
      }
      _startDuelSync();
    } else {
      final saved = GameSaveService.getSavedCaro();
      if (saved != null) {
        _resumeSavedGame(saved);
      } else {
        _initBoard();
        _startGameTimer();
        _startTurnTimer();
      }
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _turnTimer?.cancel();
    _duelSyncTimer?.cancel();
    super.dispose();
  }

  void _startDuelSync() {
    _duelSyncTimer?.cancel();
    _duelSyncTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted || _isGameOver) return;
      final challenge = context.read<ChallengeService>();
      final room = challenge.currentRoom;
      if (room == null) return;

      if (room.status == RoomStatus.finished && !_isGameOver) {
        final auth = context.read<AuthService>();
        final myUserId = auth.currentUser?.id;
        final isMeWin = room.winnerId == myUserId;
        _endGame(isPlayerWin: isMeWin);
        return;
      }

      if (room.lastMoveJson.isEmpty) return;

      if (room.lastMoveJson != _lastProcessedMoveJson) {
        _lastProcessedMoveJson = room.lastMoveJson;
        try {
          final moveMap = jsonDecode(room.lastMoveJson) as Map<String, dynamic>;
          final player = moveMap['Player'] as int? ?? moveMap['player'] as int? ?? 1;
          final row = moveMap['Row'] as int? ?? moveMap['row'] as int? ?? 0;
          final col = moveMap['Col'] as int? ?? moveMap['col'] as int? ?? 0;
          final skill = moveMap['Skill'] as String? ?? moveMap['skill'] as String?;

          // Nếu là nước đi từ tài khoản đối thủ
          if (player == _opponentMark) {
            setState(() {
              if (skill == 'emp') {
                _board[row][col] = CaroAiEngine.frozen;
              } else if (skill == 'swap') {
                final r1 = moveMap['SwapR1'] as int? ?? moveMap['swapR1'] as int? ?? 0;
                final c1 = moveMap['SwapC1'] as int? ?? moveMap['swapC1'] as int? ?? 0;
                final r2 = moveMap['SwapR2'] as int? ?? moveMap['swapR2'] as int? ?? 0;
                final c2 = moveMap['SwapC2'] as int? ?? moveMap['swapC2'] as int? ?? 0;
                _board[r1][c1] = _opponentMark;
                _board[r2][c2] = _myPlayerMark;
              } else {
                _board[row][col] = _opponentMark;
                _movesCount++;
              }
            });

            // Kiểm tra xem đối thủ có tạo thành công 5 quân liên tiếp không
            if (CaroAiEngine.checkWin(_board, boardSize, row, col, _opponentMark)) {
              _endGame(isPlayerWin: false);
            } else {
              setState(() {
                _isPlayerTurn = true;
                _turnSeconds = 15;
              });
              _startTurnTimer();
            }
          }
        } catch (e) {
          debugPrint('Error parsing Caro duel move: $e');
        }
      }

      if (room.status == RoomStatus.finished && !_isGameOver) {
        final auth = context.read<AuthService>();
        final myId = auth.currentUser?.id;
        final iWon = room.winnerId == myId;
        _endGame(isPlayerWin: iWon);
      }
    });
  }

  void _resumeSavedGame(Map<String, dynamic> saved) {
    _difficulty = saved['difficulty'] as String? ?? 'Medium';
    _board = (saved['board'] as List)
        .map((r) => (r as List).map((c) => c as int).toList())
        .toList();
    _movesCount = saved['movesCount'] as int? ?? 0;
    _mistakes = saved['mistakes'] as int? ?? 0;
    _totalSeconds = saved['totalSeconds'] as int? ?? 0;
    _quantumSwapCharges = saved['quantumSwapCharges'] as int? ?? 1;
    _empFreezeCharges = saved['empFreezeCharges'] as int? ?? 1;
    _isPlayerTurn = true;
    _isGameOver = false;
    _turnSeconds = 15;
    _isSwapSelectingFirst = false;
    _swapSelectedMove = null;
    _isEmpSelecting = false;

    _startGameTimer();
    _startTurnTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📂 Đã tự động khôi phục bàn cờ Caro trước đó!'),
          backgroundColor: GoddyTheme.neonCyan,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _autoSave() {
    if (!_isGameOver && !_isDuelMode) {
      GameSaveService.saveCaroProgress(
        board: _board,
        difficulty: _difficulty,
        movesCount: _movesCount,
        mistakes: _mistakes,
        totalSeconds: _totalSeconds,
        quantumSwapCharges: _quantumSwapCharges,
        empFreezeCharges: _empFreezeCharges,
      );
    }
  }

  void _initBoard() {
    if (!_isDuelMode) {
      GameSaveService.clearCaroSave();
    }
    _board = List.generate(boardSize, (_) => List.filled(boardSize, CaroAiEngine.empty));
    _isPlayerTurn = _isDuelMode ? widget.isHost : true;
    _isGameOver = false;
    _movesCount = 0;
    _mistakes = 0;
    _totalSeconds = 0;
    _turnSeconds = 15;
    _quantumSwapCharges = 1;
    _empFreezeCharges = 1;
    _isSwapSelectingFirst = false;
    _swapSelectedMove = null;
    _isEmpSelecting = false;
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isGameOver) {
        setState(() => _totalSeconds++);
        if (_totalSeconds % 5 == 0) {
          _autoSave();
        }
      }
    });
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnSeconds = 15;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isGameOver && _isPlayerTurn) {
        if (_turnSeconds > 0) {
          setState(() => _turnSeconds--);
        } else {
          setState(() {
            _mistakes++;
            _turnSeconds = 15;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Quá 15 giây! Bị tính 1 Lỗi phạm (Mistake)!'),
              backgroundColor: GoddyTheme.neonRed,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  void _handleCellTap(int r, int c) {
    if (_isGameOver) return;

    if (_isDuelMode && !_isPlayerTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Chưa đến lượt của bạn! Đang chờ đối thủ đánh...'),
          duration: Duration(milliseconds: 700),
          backgroundColor: GoddyTheme.neonMagenta,
        ),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final challenge = context.read<ChallengeService>();
    final myUserId = auth.currentUser?.id ?? 'user';

    // EMP Freeze
    if (_isEmpSelecting) {
      if (_board[r][c] == CaroAiEngine.empty) {
        setState(() {
          _board[r][c] = CaroAiEngine.frozen;
          _empFreezeCharges--;
          _isEmpSelecting = false;
        });

        if (_isDuelMode) {
          challenge.sendCaroMove(
            roomCode: widget.duelRoomCode!,
            userId: myUserId,
            row: r,
            col: c,
            player: _myPlayerMark,
            skill: 'emp',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚡ Đã kích hoạt EMP Freeze khóa ô!')),
        );
      }
      return;
    }

    // Quantum Swap
    if (_isSwapSelectingFirst) {
      if (_board[r][c] == _myPlayerMark) {
        _swapSelectedMove = CaroMove(r, c);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chọn tiếp 1 quân của đối thủ để hoán đổi!')),
        );
      } else if (_swapSelectedMove != null && _board[r][c] == _opponentMark) {
        final r1 = _swapSelectedMove!.r;
        final c1 = _swapSelectedMove!.c;

        setState(() {
          _board[r1][c1] = _opponentMark;
          _board[r][c] = _myPlayerMark;
          _quantumSwapCharges--;
          _isSwapSelectingFirst = false;
          _swapSelectedMove = null;
        });

        if (_isDuelMode) {
          challenge.sendCaroMove(
            roomCode: widget.duelRoomCode!,
            userId: myUserId,
            row: r,
            col: c,
            player: _myPlayerMark,
            skill: 'swap',
            swapR1: r1,
            swapC1: c1,
            swapR2: r,
            swapC2: c,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌀 Đã Hoán Đổi Lượng Tử thành công!')),
        );
        _checkPostMove(r, c, _myPlayerMark);
      }
      return;
    }

    // Normal move
    if (_board[r][c] != CaroAiEngine.empty) return;

    setState(() {
      _board[r][c] = _myPlayerMark;
      _movesCount++;
      _turnSeconds = 15;
    });

    if (_isDuelMode) {
      setState(() => _isPlayerTurn = false);
      _turnTimer?.cancel();
      challenge.sendCaroMove(
        roomCode: widget.duelRoomCode!,
        userId: myUserId,
        row: r,
        col: c,
        player: _myPlayerMark,
      );
    }

    _checkPostMove(r, c, _myPlayerMark);
  }

  void _checkPostMove(int r, int c, int player) {
    if (CaroAiEngine.checkWin(_board, boardSize, r, c, player)) {
      _endGame(isPlayerWin: player == _myPlayerMark);
      return;
    }

    if (_isDuelMode) {
      // Trong chế độ thách đấu 1v1 online, chờ lượt người chơi thật bên kia, không gọi AI
      return;
    }

    // AI's Turn cho chế độ chơi đơn
    if (player == CaroAiEngine.playerX) {
      setState(() => _isPlayerTurn = false);
      _turnTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted || _isGameOver) return;
        final aiMove = CaroAiEngine.findBestMove(
          board: _board,
          size: boardSize,
          difficulty: _difficulty,
        );
        setState(() {
          _board[aiMove.r][aiMove.c] = CaroAiEngine.playerO;
          _isPlayerTurn = true;
          _startTurnTimer();
        });

        if (CaroAiEngine.checkWin(_board, boardSize, aiMove.r, aiMove.c, CaroAiEngine.playerO)) {
          _endGame(isPlayerWin: false);
        }
      });
    }
  }

  void _endGame({required bool isPlayerWin}) {
    if (_isGameOver) return;
    _isGameOver = true;
    _gameTimer?.cancel();
    _turnTimer?.cancel();
    _duelSyncTimer?.cancel();
    if (!_isDuelMode) {
      GameSaveService.clearCaroSave();
    }

    final auth = context.read<AuthService>();
    final leaderboard = context.read<LeaderboardService>();

    final score = isPlayerWin
        ? (_isDuelMode
            ? 2500
            : leaderboard.calculateScore(
                gameType: GameType.caro,
                timeSeconds: _totalSeconds,
                mistakes: _mistakes,
                difficulty: _difficulty,
              ))
        : (_isDuelMode ? 200 : 50);

    if (!_isDuelMode) {
      final result = GameResult(
        id: 'caro_${DateTime.now().millisecondsSinceEpoch}',
        gameType: GameType.caro,
        score: score,
        timeSeconds: _totalSeconds,
        mistakes: _mistakes,
        isWin: isPlayerWin,
        difficulty: 'Quantum $_difficulty',
      );
      leaderboard.saveGameResult(result);
      auth.recordGameWin(
        isWin: isPlayerWin,
        expGained: isPlayerWin ? (score * 0.2).toInt() : 30,
        caroScore: score,
      );
    } else {
      widget.onDuelFinish?.call(isPlayerWin, _totalSeconds, score);
    }

    _showGameOverDialog(isPlayerWin, score);
  }

  void _showGameOverDialog(bool isWin, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GoddyTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isWin ? GoddyTheme.neonGreen : GoddyTheme.neonRed,
            width: 2,
          ),
        ),
        title: Center(
          child: Column(
            children: [
              Icon(
                isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: isWin ? GoddyTheme.neonAmber : GoddyTheme.neonRed,
                size: 54,
              ),
              const SizedBox(height: 8),
              Text(
                isWin
                    ? (_isDuelMode ? '🏆 BẠN ĐÃ CHIẾN THẮNG 1v1!' : 'BẠN ĐÃ THẮNG VÁN ĐẤU!')
                    : (_isDuelMode ? 'ĐỐI THỦ ĐÃ HOÀN THÀNH!' : 'AI ĐÃ CHIẾN THẮNG!'),
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: isWin ? GoddyTheme.neonGreen : GoddyTheme.neonAmber,
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
            if (_isDuelMode && !isWin) ...[
              const Text(
                'Đối thủ đã hoàn thành ván cờ (thắng 5 quân liên tiếp)!\n\nBạn muốn tiếp tục hay quay về sảnh?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 10),
            ],
            _buildStatRow('Thời gian:', '${_totalSeconds}s', GoddyTheme.neonGreen),
            _buildStatRow('Số nước đi:', '$_movesCount', GoddyTheme.neonBlue),
            _buildStatRow('Lỗi quá giờ:', '$_mistakes', GoddyTheme.neonRed),
            _buildStatRow('Chế độ:', _isDuelMode ? 'Thách Đấu 1v1' : _difficulty, GoddyTheme.neonPurple),
            const Divider(color: Colors.white24, height: 24),
            _buildStatRow('Điểm thưởng:', '+$score PTS', GoddyTheme.neonAmber, isBold: true),
          ],
        ),
        actions: [
          if (!_isDuelMode) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _initBoard();
                  _startGameTimer();
                  _startTurnTimer();
                });
              },
              child: const Text('Đấu Ván Mới', style: TextStyle(color: GoddyTheme.neonCyan)),
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
          ] else ...[
            if (!isWin)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: GoddyTheme.neonCyan,
                  side: const BorderSide(color: GoddyTheme.neonCyan),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Tiếp tục: Giữ nguyên bàn cờ để xem lại thế trận
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
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<ChallengeService>().leaveRoom();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Thoát game', style: TextStyle(color: GoddyTheme.textMuted, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleBackPress(BuildContext context) async {
    // 1. Nếu ván đấu đã kết thúc:
    if (_isGameOver) {
      if (_isDuelMode) {
        // Trong chế độ thách đấu, bấm quay về sẽ trở về sảnh phòng đấu
        Navigator.pop(context, 'lobby');
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      return;
    }

    // 2. Nếu đang trong chế độ thách đấu 1v1:
    if (_isDuelMode) {
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
            'Bạn đang trong trận đấu Caro 1v1. Bạn muốn tiếp tục đánh, quay về sảnh phòng đấu hay thoát hẳn?',
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
          'Bạn có chắc chắn muốn thoát về trang chọn game không? Ván cờ hiện tại sẽ được lưu lại.',
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

  @override
  Widget build(BuildContext context) {
    final challenge = context.watch<ChallengeService>();
    final room = challenge.currentRoom;

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
            onPressed: () => _handleBackPress(context),
          ),
          title: Text(
            _isDuelMode ? 'CARO 1v1 TRANH TÀI' : 'QUANTUM CARO',
            style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
          ),
        actions: [
          if (!_isDuelMode) ...[
            PopupMenuButton<String>(
              tooltip: 'Chọn cấp độ AI',
              icon: const Icon(Icons.tune, color: GoddyTheme.neonCyan),
              onSelected: (val) {
                setState(() {
                  _difficulty = val;
                  _initBoard();
                  _startGameTimer();
                  _startTurnTimer();
                });
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'Easy', child: Text('Tập sự (Dễ)')),
                const PopupMenuItem(value: 'Medium', child: Text('Chiến thuật gia (Vừa)')),
                const PopupMenuItem(value: 'Grandmaster', child: Text('Đại kiện tướng AI (Khó)')),
              ],
            ),
            IconButton(
              tooltip: 'Làm mới bàn cờ',
              icon: const Icon(Icons.refresh, color: GoddyTheme.neonRed),
              onPressed: () {
                setState(() {
                  _initBoard();
                  _startGameTimer();
                  _startTurnTimer();
                });
              },
            ),
          ] else ...[
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GoddyTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GoddyTheme.neonGreen),
              ),
              child: Text(
                'PHÒNG: ${widget.duelRoomCode}',
                style: const TextStyle(color: GoddyTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: [
              // HUD Duel Players Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: GoddyTheme.glowBox(
                  borderColor: _isPlayerTurn ? GoddyTheme.neonCyan : GoddyTheme.neonMagenta,
                  bgColor: GoddyTheme.bgCard,
                  radius: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Player X
                    Row(
                      children: [
                        Text(_isDuelMode ? (widget.isHost ? (room?.hostAvatar ?? '⚡') : (room?.guestAvatar ?? '🥷')) : '⚡', style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDuelMode
                                  ? (widget.isHost ? 'BẠN (X)' : (room?.hostName ?? 'Chủ Phòng (X)'))
                                  : 'BẠN (X)',
                              style: const TextStyle(color: GoddyTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              _isDuelMode
                                  ? (widget.isHost ? (_isPlayerTurn ? '👉 Lượt của bạn!' : 'Chờ đối thủ...') : (!_isPlayerTurn ? '👉 Lượt của bạn!' : 'Chờ đối thủ...'))
                                  : (_isPlayerTurn ? 'Đang ra chiêu...' : 'Chờ đối thủ'),
                              style: TextStyle(
                                color: (_isDuelMode && widget.isHost == _isPlayerTurn) ? GoddyTheme.neonGreen : GoddyTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Turn Countdown Ring
                    Column(
                      children: [
                        Text(
                          '${_turnSeconds}s',
                          style: GoogleFonts.orbitron(
                            color: _turnSeconds <= 5 ? GoddyTheme.neonRed : GoddyTheme.neonAmber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('LƯỢT ĐI', style: TextStyle(color: GoddyTheme.textMuted, fontSize: 10)),
                      ],
                    ),

                    // Player O
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _isDuelMode
                                  ? (!widget.isHost ? 'BẠN (O)' : (room?.guestName ?? 'Đối thủ (O)'))
                                  : 'AI (O)',
                              style: const TextStyle(color: GoddyTheme.neonMagenta, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              _isDuelMode
                                  ? (!widget.isHost ? (_isPlayerTurn ? '👉 Lượt của bạn!' : 'Chờ đối thủ...') : (!_isPlayerTurn ? '👉 Đối thủ đang đi...' : 'Đang chờ bạn...'))
                                  : (! _isPlayerTurn ? 'Đang suy nghĩ...' : 'Phòng thủ'),
                              style: TextStyle(
                                color: (_isDuelMode && !widget.isHost == _isPlayerTurn) ? GoddyTheme.neonGreen : GoddyTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(_isDuelMode ? (!widget.isHost ? (room?.guestAvatar ?? '🥷') : (room?.hostAvatar ?? '⚡')) : '🤖', style: const TextStyle(fontSize: 22)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Cyber Tactical Skills Panel
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _quantumSwapCharges > 0 ? GoddyTheme.neonPurple : Colors.white12,
                        ),
                        backgroundColor: _isSwapSelectingFirst ? GoddyTheme.neonPurple.withValues(alpha: 0.3) : Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.swap_horiz, size: 18, color: GoddyTheme.neonPurple),
                      label: Text(
                        'Quantum Swap ($_quantumSwapCharges)',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _quantumSwapCharges > 0 && _isPlayerTurn
                          ? () {
                              setState(() {
                                _isSwapSelectingFirst = !_isSwapSelectingFirst;
                                _isEmpSelecting = false;
                              });
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _empFreezeCharges > 0 ? GoddyTheme.neonAmber : Colors.white12,
                        ),
                        backgroundColor: _isEmpSelecting ? GoddyTheme.neonAmber.withValues(alpha: 0.3) : Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.ac_unit, size: 18, color: GoddyTheme.neonAmber),
                      label: Text(
                        'EMP Freeze ($_empFreezeCharges)',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _empFreezeCharges > 0 && _isPlayerTurn
                          ? () {
                              setState(() {
                                _isEmpSelecting = !_isEmpSelecting;
                                _isSwapSelectingFirst = false;
                              });
                            }
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Caro Interactive Grid Board
              Center(
                child: Container(
                  width: 340,
                  height: 340,
                  padding: const EdgeInsets.all(6),
                  decoration: GoddyTheme.glowBox(
                    borderColor: GoddyTheme.neonCyan,
                    bgColor: const Color(0xFF0C1322),
                    radius: 16,
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: boardSize * boardSize,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: boardSize,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) {
                      final r = index ~/ boardSize;
                      final c = index % boardSize;
                      final val = _board[r][c];

                      return InkWell(
                        onTap: () => _handleCellTap(r, c),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF162035),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Center(
                            child: _buildCellContent(val),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Mistakes and Total Time Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('⏱️ Tổng thời gian: ${_totalSeconds}s', style: const TextStyle(color: GoddyTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('⚠️ Lỗi vi phạm: $_mistakes', style: const TextStyle(color: GoddyTheme.neonRed, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('🎯 Nước đi: $_movesCount', style: const TextStyle(color: GoddyTheme.neonBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildCellContent(int val) {
    if (val == CaroAiEngine.playerX) {
      return Text(
        'X',
        style: GoogleFonts.orbitron(
          color: GoddyTheme.neonCyan,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: [
            Shadow(color: GoddyTheme.neonCyan.withValues(alpha: 0.8), blurRadius: 8),
          ],
        ),
      );
    } else if (val == CaroAiEngine.playerO) {
      return Text(
        'O',
        style: GoogleFonts.orbitron(
          color: GoddyTheme.neonMagenta,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: [
            Shadow(color: GoddyTheme.neonMagenta.withValues(alpha: 0.8), blurRadius: 8),
          ],
        ),
      );
    } else if (val == CaroAiEngine.frozen) {
      return const Icon(Icons.lock, size: 14, color: GoddyTheme.neonAmber);
    }
    return const SizedBox();
  }
}
