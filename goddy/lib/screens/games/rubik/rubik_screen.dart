import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/game_result.dart';
import '../../../services/auth_service.dart';
import '../../../services/leaderboard_service.dart';
import '../../../services/challenge_service.dart';
import '../../../models/challenge_room.dart';
import 'rubik_cube_widget.dart';
import 'rubik_solver_ai.dart';

enum RubikPlayPhase {
  cleanBase, // Khối sạch thuần 1 màu ở 6 mặt ban đầu
  scrambled, // Đã xáo trộn, chờ bấm Bắt đầu
  playing,   // Đang bấm giờ và chơi
  completed, // Đã hoàn thành về thuần 1 màu ở 6 mặt
}

class RubikScreen extends StatefulWidget {
  final int? duelSeed;
  final String? duelRoomCode;
  final Function(int seconds, int moves)? onDuelFinish;

  const RubikScreen({
    super.key,
    this.duelSeed,
    this.duelRoomCode,
    this.onDuelFinish,
  });

  @override
  State<RubikScreen> createState() => _RubikScreenState();
}

class _RubikScreenState extends State<RubikScreen> {
  final GlobalKey<RubikCubeWidgetState> _cubeKey = GlobalKey<RubikCubeWidgetState>();

  RubikPlayPhase _phase = RubikPlayPhase.cleanBase;
  Timer? _stopwatchTimer;
  Timer? _duelSyncTimer;
  int _millisecondsElapsed = 0;
  int _movesCount = 0;

  // AI Solver assistant
  int _currentStepIndex = 0;
  List<SolverStep> _solverSteps = [];

  @override
  void initState() {
    super.initState();
    _solverSteps = RubikSolverAi.generateSolutionSteps([]);
    if (widget.onDuelFinish != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleScramble();
        _startStopwatch();
      });
    }
    if (widget.duelRoomCode != null) {
      _startDuelSync();
    }
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _duelSyncTimer?.cancel();
    super.dispose();
  }

  void _startDuelSync() {
    if (widget.duelRoomCode == null) return;
    _duelSyncTimer?.cancel();
    _duelSyncTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || _phase == RubikPlayPhase.completed) return;
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
        _phase = RubikPlayPhase.completed;
        _stopwatchTimer?.cancel();
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
              'Đối thủ [$opponentName] đã xoay xong Rubik 3D trước bạn với thời gian ${opponentTime}s!\n\nBạn muốn tiếp tục hay quay về sảnh?',
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
              // Tiếp tục: Để người chơi tự giải nốt khối Rubik của mình
              _resumeStopwatch();
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

  void _resumeStopwatch() {
    _stopwatchTimer?.cancel();
    _phase = RubikPlayPhase.playing;
    _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _phase == RubikPlayPhase.playing) {
        setState(() {
          _millisecondsElapsed += 100;
        });
      }
    });
  }

  void _startStopwatch() {
    _stopwatchTimer?.cancel();
    _millisecondsElapsed = 0;
    _movesCount = 0;
    _phase = RubikPlayPhase.playing;

    _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _phase == RubikPlayPhase.playing) {
        setState(() {
          _millisecondsElapsed += 100;
        });
      }
    });
  }

  void _stopStopwatch() {
    _stopwatchTimer?.cancel();
  }

  void _handleScramble() {
    _stopStopwatch();
    _cubeKey.currentState?.scramble();
    setState(() {
      _phase = RubikPlayPhase.scrambled;
      _millisecondsElapsed = 0;
      _movesCount = 0;
      _currentStepIndex = 0;
      _solverSteps = RubikSolverAi.generateSolutionSteps(RubikSolverAi.generateScramble());
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎲 Khối Rubik đã được xáo trộn logic ngẫu nhiên! Hãy nhấn Bắt Đầu để tính giờ!'),
        backgroundColor: GoddyTheme.neonAmber,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleResetToCleanBase() {
    _stopStopwatch();
    _cubeKey.currentState?.resetCube();
    setState(() {
      _phase = RubikPlayPhase.cleanBase;
      _millisecondsElapsed = 0;
      _movesCount = 0;
      _currentStepIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Đã đặt lại khối Rubik về trạng thái gốc thuần 1 màu ở 6 mặt!'),
        backgroundColor: GoddyTheme.neonCyan,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onMoveExecuted() {
    setState(() {
      _movesCount++;
    });

    // Check if player solved the cube back to pure base state
    if (_phase == RubikPlayPhase.playing) {
      final isSolved = _cubeKey.currentState?.isSolved() ?? false;
      if (isSolved) {
        _handleVictory();
      }
    }
  }

  void _handleVictory() {
    _stopStopwatch();
    setState(() {
      _phase = RubikPlayPhase.completed;
    });

    final totalSeconds = (_millisecondsElapsed / 1000).ceil();
    final auth = context.read<AuthService>();
    final leaderboard = context.read<LeaderboardService>();

    // Calculate score based strictly on seconds (less seconds = higher score & rank)
    final score = (2000 - totalSeconds * 12).clamp(100, 5000);

    final result = GameResult(
      id: 'rubik_${DateTime.now().millisecondsSinceEpoch}',
      gameType: GameType.rubik,
      score: score,
      timeSeconds: totalSeconds,
      mistakes: 0,
      isWin: true,
      difficulty: '3D Simulation Speedcube',
    );

    leaderboard.saveGameResult(result);
    auth.recordGameWin(
      isWin: true,
      expGained: (score * 0.15).toInt(),
      rubikSecs: totalSeconds,
    );

    widget.onDuelFinish?.call(totalSeconds, _movesCount);

    _showVictoryDialog(totalSeconds, score);
  }

  void _showVictoryDialog(int seconds, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GoddyTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: GoddyTheme.neonGreen, width: 2),
        ),
        title: Center(
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: GoddyTheme.neonAmber, size: 54),
              const SizedBox(height: 8),
              Text(
                'CHIẾN THẮNG VINH QUANG!',
                style: GoogleFonts.orbitron(
                  color: GoddyTheme.neonGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Khối Rubik đã về lại thuần 1 màu ở cả 6 mặt!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Thời gian giải:', '${seconds}s', GoddyTheme.neonGreen, isBold: true),
            _buildStatRow('Số lượt xoay:', '$_movesCount', GoddyTheme.neonBlue),
            const Divider(color: Colors.white24, height: 20),
            _buildStatRow('Điểm Rank đạt được:', '+$score PTS', GoddyTheme.neonAmber, isBold: true),
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
                _handleResetToCleanBase();
              },
              child: const Text('Bắt Đầu Lại', style: TextStyle(color: GoddyTheme.neonCyan)),
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
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    final totalSecs = _millisecondsElapsed ~/ 1000;
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    final tenths = (_millisecondsElapsed % 1000) ~/ 100;
    return '$mins:$secs.$tenths';
  }

  Future<void> _handleBackPress(BuildContext context) async {
    // 1. Nếu ván đấu đã kết thúc:
    if (_phase != RubikPlayPhase.playing) {
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
            'Bạn đang trong trận đấu Rubik 1v1. Bạn muốn tiếp tục xoay, quay về sảnh phòng đấu hay thoát hẳn?',
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
          'Bạn có chắc chắn muốn thoát về trang chọn game không? Đồng hồ bấm giờ sẽ dừng lại.',
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
          widget.onDuelFinish != null ? '⚔️ RUBIK 3D THÁCH ĐẤU' : 'GIẢ LẬP RUBIK 3D',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Sơ đồ 6 mặt (Cube Net)',
            icon: const Icon(Icons.grid_view_rounded, color: GoddyTheme.neonCyan),
            onPressed: _showSixFacesNetSheet,
          ),
          IconButton(
            tooltip: 'AI gợi ý giải',
            icon: const Icon(Icons.smart_toy_outlined, color: GoddyTheme.neonMagenta),
            onPressed: _showAiAssistantSheet,
          ),
          IconButton(
            tooltip: 'Đặt lại khối thuần màu',
            icon: const Icon(Icons.refresh, color: GoddyTheme.neonRed),
            onPressed: _handleResetToCleanBase,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              children: [
                // 1. Compact Top HUD Bar (Time, Moves, Scramble/Start Action Button)
                _buildCompactHud(),

                const SizedBox(height: 4),

                // 2. 3D Rubik Interactive Cube View (Size 210px)
                RubikCubeWidget(
                  key: _cubeKey,
                  size: 210.0,
                  onMoveExecuted: _onMoveExecuted,
                ),

                // 3. Quick Utility Bar (Vuốt 360°, Góc Chuẩn, 6 Mặt, Gợi Ý AI)
                _buildQuickUtilityBar(),

                const SizedBox(height: 4),

                // 4. Dual-Pad Gaming Controller Deck (Left: Hàng Ngang, Right: Cột Dọc & Mặt Trước)
                _buildDualPadController(),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildCompactHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: GoddyTheme.glowBox(
        borderColor: _phase == RubikPlayPhase.playing ? GoddyTheme.neonGreen : GoddyTheme.neonCyan,
        bgColor: GoddyTheme.bgCard,
        radius: 12,
      ),
      child: Row(
        children: [
          // Stopwatch Timer
          const Icon(Icons.timer_outlined, size: 16, color: GoddyTheme.neonAmber),
          const SizedBox(width: 4),
          Text(
            _formattedTime,
            style: GoogleFonts.orbitron(
              color: _phase == RubikPlayPhase.playing ? GoddyTheme.neonGreen : GoddyTheme.neonAmber,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 12),

          // Moves Count
          const Icon(Icons.bolt, size: 16, color: GoddyTheme.neonBlue),
          const SizedBox(width: 3),
          Text(
            '$_movesCount',
            style: GoogleFonts.orbitron(
              color: GoddyTheme.neonBlue,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Compact Action Button
          _buildCompactActionButton(),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton() {
    if (_phase == RubikPlayPhase.cleanBase) {
      return SizedBox(
        height: 30,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: GoddyTheme.neonAmber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.shuffle, size: 14),
          label: Text(
            'Xáo Trộn',
            style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          onPressed: _handleScramble,
        ),
      );
    } else if (_phase == RubikPlayPhase.scrambled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GoddyTheme.neonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.play_arrow, size: 16),
              label: Text(
                'Bắt Đầu',
                style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              onPressed: _startStopwatch,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 30,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: GoddyTheme.neonRed, width: 0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _handleResetToCleanBase,
              child: const Text('Lại', style: TextStyle(color: GoddyTheme.neonRed, fontSize: 11)),
            ),
          ),
        ],
      );
    } else {
      // Playing or completed
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: GoddyTheme.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GoddyTheme.neonGreen, width: 0.9),
            ),
            child: Text(
              '⏱️ ĐANG GIẢI',
              style: GoogleFonts.orbitron(
                color: GoddyTheme.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 9.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 30,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: GoddyTheme.neonRed, width: 0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _handleResetToCleanBase,
              child: const Text('Lại', style: TextStyle(color: GoddyTheme.neonRed, fontSize: 11)),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildQuickUtilityBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.touch_app_outlined, size: 13, color: GoddyTheme.textMuted),
            SizedBox(width: 3),
            Text(
              'Vuốt xoay 360°',
              style: TextStyle(color: GoddyTheme.textMuted, fontSize: 10.5),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.refresh, size: 13, color: GoddyTheme.neonCyan),
              label: const Text('Góc Chuẩn', style: TextStyle(color: GoddyTheme.neonCyan, fontSize: 10.5)),
              onPressed: () => _cubeKey.currentState?.resetCameraView(),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 13, color: GoddyTheme.neonCyan),
              label: const Text('6 Mặt', style: TextStyle(color: GoddyTheme.neonCyan, fontSize: 10.5)),
              onPressed: _showSixFacesNetSheet,
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.smart_toy_outlined, size: 13, color: GoddyTheme.neonMagenta),
              label: const Text('Gợi Ý AI', style: TextStyle(color: GoddyTheme.neonMagenta, fontSize: 10.5)),
              onPressed: _showAiAssistantSheet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDualPadController() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: GoddyTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pad: Hàng Ngang (3 rows)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: GoddyTheme.neonCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '↔️ HÀNG NGANG',
                    style: GoogleFonts.orbitron(
                      color: GoddyTheme.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _buildPadRow(
                  label: 'Trên',
                  icon1: Icons.arrow_back_rounded,
                  text1: 'Trái',
                  move1: "U'",
                  icon2: Icons.arrow_forward_rounded,
                  text2: 'Phải',
                  move2: 'U',
                  accentColor: GoddyTheme.neonCyan,
                ),
                const SizedBox(height: 5),
                _buildPadRow(
                  label: 'Giữa',
                  icon1: Icons.arrow_back_rounded,
                  text1: 'Trái',
                  move1: 'E',
                  icon2: Icons.arrow_forward_rounded,
                  text2: 'Phải',
                  move2: "E'",
                  accentColor: GoddyTheme.neonCyan,
                ),
                const SizedBox(height: 5),
                _buildPadRow(
                  label: 'Dưới',
                  icon1: Icons.arrow_back_rounded,
                  text1: 'Trái',
                  move1: 'D',
                  icon2: Icons.arrow_forward_rounded,
                  text2: 'Phải',
                  move2: "D'",
                  accentColor: GoddyTheme.neonCyan,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right Pad: Cột Dọc & Mặt Trước (4 rows)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: GoddyTheme.neonBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '↕️ CỘT DỌC & TRƯỚC',
                    style: GoogleFonts.orbitron(
                      color: GoddyTheme.neonBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _buildPadRow(
                  label: 'Trái',
                  icon1: Icons.arrow_upward_rounded,
                  text1: 'Lên',
                  move1: "L'",
                  icon2: Icons.arrow_downward_rounded,
                  text2: 'Xuống',
                  move2: 'L',
                  accentColor: GoddyTheme.neonBlue,
                ),
                const SizedBox(height: 5),
                _buildPadRow(
                  label: 'Giữa',
                  icon1: Icons.arrow_upward_rounded,
                  text1: 'Lên',
                  move1: "M'",
                  icon2: Icons.arrow_downward_rounded,
                  text2: 'Xuống',
                  move2: 'M',
                  accentColor: GoddyTheme.neonBlue,
                ),
                const SizedBox(height: 5),
                _buildPadRow(
                  label: 'Phải',
                  icon1: Icons.arrow_upward_rounded,
                  text1: 'Lên',
                  move1: 'R',
                  icon2: Icons.arrow_downward_rounded,
                  text2: 'Xuống',
                  move2: "R'",
                  accentColor: GoddyTheme.neonBlue,
                ),
                const SizedBox(height: 5),
                _buildPadRow(
                  label: 'Trước',
                  icon1: Icons.rotate_right_rounded,
                  text1: 'Thuận',
                  move1: 'F',
                  icon2: Icons.rotate_left_rounded,
                  text2: 'Nghịch',
                  move2: "F'",
                  accentColor: GoddyTheme.neonAmber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPadRow({
    required String label,
    required IconData icon1,
    required String text1,
    required String move1,
    required IconData icon2,
    required String text2,
    required String move2,
    required Color accentColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildMiniPadButton(
            icon: icon1,
            text: text1,
            move: move1,
            accentColor: accentColor,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildMiniPadButton(
            icon: icon2,
            text: text2,
            move: move2,
            accentColor: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPadButton({
    required IconData icon,
    required String text,
    required String move,
    required Color accentColor,
  }) {
    return SizedBox(
      height: 29,
      child: Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _cubeKey.currentState?.executeMove(move),
          splashColor: accentColor.withValues(alpha: 0.35),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 0.9),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accentColor, size: 12),
                const SizedBox(width: 2.5),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSixFacesNetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: GoddyTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: GoddyTheme.neonCyan, width: 1.5),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              _buildSixFacesNet(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoddyTheme.neonCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('ĐÓNG & TIẾP TỤC CHƠI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  void _showAiAssistantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GoddyTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: GoddyTheme.neonMagenta, width: 1.5),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final hasMoreSteps = _currentStepIndex < _solverSteps.length;
            final currentStep = hasMoreSteps ? _solverSteps[_currentStepIndex] : null;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.smart_toy_outlined, color: GoddyTheme.neonMagenta, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'AI HƯỚNG DẪN GIẢI TỪNG BƯỚC',
                        style: GoogleFonts.orbitron(
                          color: GoddyTheme.neonMagenta,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GoddyTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GoddyTheme.neonMagenta.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStep != null ? currentStep.stageName : '🎉 Đã hoàn tất tất cả hướng dẫn!',
                          style: const TextStyle(color: GoddyTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentStep != null ? currentStep.descriptionVi : 'Khối Rubik đã sẵn sàng được giải.',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (hasMoreSteps) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GoddyTheme.neonMagenta,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Thực hiện bước này', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              if (_currentStepIndex < _solverSteps.length) {
                                final step = _solverSteps[_currentStepIndex];
                                if (step.algorithm.isNotEmpty) {
                                  _cubeKey.currentState?.executeMove(step.algorithm[0]);
                                }
                                setState(() {
                                  _currentStepIndex++;
                                });
                                setSheetState(() {});
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Đóng', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSixFacesNet() {
    final faces = _cubeKey.currentState?.faces ?? [
      List.filled(9, RubikCubeWidgetState.cWhite),
      List.filled(9, RubikCubeWidgetState.cYellow),
      List.filled(9, RubikCubeWidgetState.cGreen),
      List.filled(9, RubikCubeWidgetState.cBlue),
      List.filled(9, RubikCubeWidgetState.cRed),
      List.filled(9, RubikCubeWidgetState.cOrange),
    ];

    Widget buildMiniFace(int faceIndex, String label) {
      final faceColors = faces[faceIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 1.5,
                  mainAxisSpacing: 1.5,
                ),
                itemCount: 9,
                itemBuilder: (context, idx) {
                  return Container(
                    decoration: BoxDecoration(
                      color: faceColors[idx],
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: GoddyTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GoddyTheme.neonCyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.grid_view_rounded, size: 14, color: GoddyTheme.neonCyan),
              const SizedBox(width: 6),
              Text(
                'SƠ ĐỒ TRẢI PHẲNG ĐỦ 6 MẶT (CUBE NET):',
                style: GoogleFonts.orbitron(
                  color: GoddyTheme.neonCyan,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 1: Up (White)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 38),
              buildMiniFace(0, 'U - Trắng'),
              const SizedBox(width: 38 * 2),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: Left (Orange), Front (Green), Right (Red), Back (Blue)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildMiniFace(5, 'L - Cam'),
              const SizedBox(width: 6),
              buildMiniFace(2, 'F - Xanh Lá'),
              const SizedBox(width: 6),
              buildMiniFace(4, 'R - Đỏ'),
              const SizedBox(width: 6),
              buildMiniFace(3, 'B - Xanh Dương'),
            ],
          ),
          const SizedBox(height: 4),
          // Row 3: Down (Yellow)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 38),
              buildMiniFace(1, 'D - Vàng'),
              const SizedBox(width: 38 * 2),
            ],
          ),
        ],
      ),
    );
  }
}
