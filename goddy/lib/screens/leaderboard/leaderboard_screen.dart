import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/leaderboard_entry.dart';
import '../../services/auth_service.dart';
import '../../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardService>().fetchRemoteLeaderboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoddyTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'BẢNG XẾP HẠNG HUYỀN THOẠI',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Cập nhật bảng xếp hạng',
            icon: const Icon(Icons.refresh, color: GoddyTheme.neonCyan),
            onPressed: () => context.read<LeaderboardService>().fetchRemoteLeaderboard(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: GoddyTheme.neonCyan,
          unselectedLabelColor: GoddyTheme.textMuted,
          indicatorColor: GoddyTheme.neonCyan,
          tabs: const [
            Tab(text: '🏆 TỔNG HỢP'),
            Tab(text: '🧩 RUBIK 3D'),
            Tab(text: '⭕ CARO'),
            Tab(text: '🔢 SUDOKU'),
            Tab(text: '📱 GYRO PUZZLE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LeaderboardTabContent(gameType: null),
          _LeaderboardTabContent(gameType: GameType.rubik),
          _LeaderboardTabContent(gameType: GameType.caro),
          _LeaderboardTabContent(gameType: GameType.sudoku),
          _LeaderboardTabContent(gameType: GameType.slidePuzzle),
        ],
      ),
    );
  }
}

class _LeaderboardTabContent extends StatelessWidget {
  final GameType? gameType;

  const _LeaderboardTabContent({this.gameType});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final leaderboard = context.watch<LeaderboardService>();
    final user = auth.currentUser;

    LeaderboardEntry? userEntry;
    if (user != null) {
      int myScore = user.exp;
      int mySecs = 0;
      if (gameType == GameType.rubik) {
        mySecs = user.rubikBestSeconds;
        myScore = user.rubikBestSeconds > 0 ? (1000 - user.rubikBestSeconds * 5).clamp(100, 3000) : 0;
      } else if (gameType == GameType.caro) {
        myScore = user.caroBestScore;
      } else if (gameType == GameType.sudoku) {
        mySecs = user.sudokuBestSeconds;
        myScore = user.sudokuBestSeconds > 0 ? (1200 - user.sudokuBestSeconds * 3).clamp(100, 3000) : 0;
      } else if (gameType == GameType.slidePuzzle) {
        mySecs = user.puzzleBestSeconds;
        myScore = user.puzzleBestSeconds > 0 ? (900 - user.puzzleBestSeconds * 8).clamp(100, 3000) : 0;
      }

      if (myScore > 0) {
        userEntry = LeaderboardEntry(
          rank: 99,
          userId: user.id,
          username: '${user.username} (Bạn)',
          avatar: user.avatar,
          score: myScore,
          timeSeconds: mySecs,
          rankTier: user.rankTier,
          gameType: gameType,
        );
      }
    }

    final entries = leaderboard.getLeaderboardFor(gameType, currentUserEntry: userEntry);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Top 3 Podium
        if (entries.length >= 3) _buildPodium(entries.take(3).toList()),

        const SizedBox(height: 16),

        // List of all entries
        ...entries.map((entry) {
          final isMe = entry.username.contains('(Bạn)');
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? GoddyTheme.neonCyan.withValues(alpha: 0.15) : GoddyTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMe ? GoddyTheme.neonCyan : Colors.white12,
                width: isMe ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                _buildRankBadge(entry.rank),
                const SizedBox(width: 12),
                Text(entry.avatar, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.username,
                        style: TextStyle(
                          color: isMe ? GoddyTheme.neonCyan : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (entry.timeSeconds > 0)
                        Text(
                          'Kỷ lục: ${entry.timeSeconds}s • ${entry.mistakes} lỗi',
                          style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.score} PTS',
                      style: GoogleFonts.orbitron(
                        color: GoddyTheme.neonAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      entry.rankTier.nameVi,
                      style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bg = const Color(0xFF1E293B);
    Color fg = Colors.white70;

    if (rank == 1) {
      bg = const Color(0xFFFFD166);
      fg = Colors.black;
    } else if (rank == 2) {
      bg = const Color(0xFFE2E8F0);
      fg = Colors.black;
    } else if (rank == 3) {
      bg = const Color(0xFFFB8500);
      fg = Colors.white;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: GoddyTheme.glowBox(
        borderColor: GoddyTheme.neonAmber,
        bgColor: const Color(0xFF131828),
        radius: 18,
        glowOpacity: 0.15,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rank 2 (Silver)
          _buildPodiumSpot(top3[1], 2, const Color(0xFFE2E8F0), 75),
          // Rank 1 (Gold)
          _buildPodiumSpot(top3[0], 1, const Color(0xFFFFD166), 105),
          // Rank 3 (Bronze)
          _buildPodiumSpot(top3[2], 3, const Color(0xFFFB8500), 65),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(LeaderboardEntry entry, int rank, Color color, double height) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry.avatar, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          entry.username,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${entry.score} pts',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Container(
          width: 75,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.orbitron(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
