import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/challenge_service.dart';
import '../games/rubik/rubik_screen.dart';
import '../games/caro/caro_screen.dart';
import '../games/sudoku/sudoku_screen.dart';
import '../games/slide_puzzle/slide_puzzle_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../challenge/challenge_screen.dart';
import '../challenge/duel_room_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentTab = 0;

  void _switchTab(int index) {
    setState(() => _currentTab = index);
  }

  late final List<Widget> _screens = [
    _GamesHubTab(onNavigateTab: _switchTab),
    const LeaderboardScreen(),
    const ChallengeScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoddyTheme.bgDark,
      body: IndexedStack(
        index: _currentTab,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: GoddyTheme.bgCard,
          border: Border(
            top: BorderSide(color: GoddyTheme.neonCyan.withValues(alpha: 0.15), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) => setState(() => _currentTab = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: GoddyTheme.neonCyan,
          unselectedItemColor: GoddyTheme.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports_outlined),
              activeIcon: Icon(Icons.sports_esports),
              label: 'Trò Chơi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Xếp Hạng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flash_on_outlined),
              activeIcon: Icon(Icons.flash_on),
              label: 'Thách Đấu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Cộng Đồng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ Sơ',
            ),
          ],
        ),
      ),
    );
  }
}

class _GamesHubTab extends StatelessWidget {
  final Function(int) onNavigateTab;

  const _GamesHubTab({required this.onNavigateTab});

  void _showAccountManagerSheet(BuildContext context, AuthService auth) {
    final user = auth.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: GoddyTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: GoddyTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(user?.avatar ?? '🎮', style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? 'Gamer',
                        style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GoddyTheme.neonCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GoddyTheme.neonCyan),
                  ),
                  child: Text(
                    user?.rankTier.nameVi ?? 'Đồng',
                    style: const TextStyle(color: GoddyTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.badge, color: GoddyTheme.neonCyan),
              title: const Text('Xem Hồ Sơ Chi Tiết & Kỷ Lục', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
              onTap: () {
                Navigator.pop(ctx);
                onNavigateTab(4); // Switch to Profile tab
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: GoddyTheme.neonRed),
              title: const Text('Đăng Xuất / Đổi Tài Khoản Khác', style: TextStyle(color: GoddyTheme.neonRed, fontSize: 13, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
              onTap: () {
                Navigator.pop(ctx);
                auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGameModeSelectionSheet({
    required BuildContext context,
    required GameType gameType,
    required String icon,
    required String title,
    required String description,
    required Color accentColor,
    required Widget soloScreen,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GoddyTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final auth = context.read<AuthService>();
        final challenge = context.read<ChallengeService>();
        final user = auth.currentUser;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor),
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Chọn chế độ chơi hoặc xem bảng xếp hạng:',
                          style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Option 1: 1 Người Chơi (Solo)
              _buildModeOptionTile(
                icon: Icons.person,
                iconColor: GoddyTheme.neonCyan,
                title: '1 NGƯỜI CHƠI (CHƠI ĐƠN)',
                subtitle: 'Tự giải đố, rèn luyện kỹ năng, bấm giờ chính xác và lưu kỷ lục vào tài khoản',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => soloScreen));
                },
              ),

              const SizedBox(height: 10),

              // Option 2: 2 Người Chơi (Thách Đấu / Duel)
              _buildModeOptionTile(
                icon: Icons.people_alt,
                iconColor: GoddyTheme.neonMagenta,
                title: '2 NGƯỜI CHƠI (THÁCH ĐẤU ĐỐI KHÁNG)',
                subtitle: 'Mời bạn bè, mã PIN/QR, cả 2 bấm SẴN SÀNG để bắt đầu, điểm bắt đầu ở 0',
                badgeText: '1v1 DUEL',
                onTap: () {
                  Navigator.pop(ctx);
                  if (user != null) {
                    final room = challenge.createRoom(host: user, gameType: gameType);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DuelRoomScreen(roomCode: room.roomCode)),
                    );
                  }
                },
              ),

              const SizedBox(height: 10),

              // Option 3: Xem Bảng Xếp Hạng Game Này
              _buildModeOptionTile(
                icon: Icons.emoji_events,
                iconColor: GoddyTheme.neonAmber,
                title: 'XEM BẢNG XẾP HẠNG GAME NÀY',
                subtitle: 'Xem danh sách các cao thủ có thành tích nhanh nhất và điểm cao nhất',
                onTap: () {
                  Navigator.pop(ctx);
                  onNavigateTab(1); // Switch to Leaderboard tab
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(color: iconColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: iconColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Gamer Banner (Tap to manage Account)
            InkWell(
              onTap: () => _showAccountManagerSheet(context, auth),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: GoddyTheme.glowBox(
                  borderColor: GoddyTheme.neonCyan,
                  bgColor: GoddyTheme.bgCard,
                  radius: 18,
                  glowOpacity: 0.15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: GoddyTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(user?.avatar ?? '🎮', style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.username ?? 'Goddy Gamer',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_drop_down, color: GoddyTheme.neonCyan, size: 20),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: GoddyTheme.neonCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: GoddyTheme.neonCyan, width: 0.8),
                                ),
                                child: Text(
                                  user?.rankTier.nameVi ?? 'Đồng',
                                  style: const TextStyle(color: GoddyTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${user?.exp ?? 0} EXP',
                                style: const TextStyle(color: GoddyTheme.neonAmber, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GoddyTheme.neonCyan.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: GoddyTheme.neonCyan.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.manage_accounts, color: GoddyTheme.neonCyan, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CHỌN TRÒ CHƠI',
                  style: GoogleFonts.orbitron(
                    color: GoddyTheme.neonCyan,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GoddyTheme.neonMagenta.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('1P SOLO / 2P ĐỐI KHÁNG', style: TextStyle(color: GoddyTheme.neonMagenta, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Game 1: Rubik 3D Solver
            _buildGameCard(
              context: context,
              icon: '🧩',
              title: 'RUBIK 3D AI SOLVER',
              subtitle: 'Xoay 3D 360° + AI Hướng dẫn giải từng bước • Chọn 1P Solo hoặc 2P Thách Đấu',
              tag: '1P SOLO • 2P THÁCH ĐẤU',
              tagColor: GoddyTheme.neonCyan,
              accentColor: GoddyTheme.neonCyan,
              onTap: () {
                _showGameModeSelectionSheet(
                  context: context,
                  gameType: GameType.rubik,
                  icon: '🧩',
                  title: 'RUBIK 3D SPEEDCUBE',
                  description: 'Giả lập Rubik 3D chân thực, xoay tự do và thách đấu tính giờ',
                  accentColor: GoddyTheme.neonCyan,
                  soloScreen: const RubikScreen(),
                );
              },
            ),

            const SizedBox(height: 12),

            // Game 2: Quantum Caro
            _buildGameCard(
              context: context,
              icon: '⭕',
              title: 'QUANTUM CARO',
              subtitle: 'Cờ Caro đấu AI Minimax + Kỹ năng Hoán Đổi Cờ & Khóa Ô • Chọn 1P Solo hoặc 2P Thách Đấu',
              tag: '1P SOLO • 2P THÁCH ĐẤU',
              tagColor: GoddyTheme.neonMagenta,
              accentColor: GoddyTheme.neonMagenta,
              onTap: () {
                _showGameModeSelectionSheet(
                  context: context,
                  gameType: GameType.caro,
                  icon: '⭕',
                  title: 'QUANTUM CARO',
                  description: 'Cờ Caro siêu chiến thuật với thẻ kỹ năng và đấu đối kháng',
                  accentColor: GoddyTheme.neonMagenta,
                  soloScreen: const CaroScreen(),
                );
              },
            ),

            const SizedBox(height: 12),

            // Game 3: Sudoku Hologram
            _buildGameCard(
              context: context,
              icon: '🔢',
              title: 'SUDOKU HOLOGRAM',
              subtitle: 'Ma trận 9x9 + Phổ màu quang học xung đột + AI suy luận • Chọn 1P Solo hoặc 2P Thách Đấu',
              tag: '1P SOLO • 2P THÁCH ĐẤU',
              tagColor: GoddyTheme.neonPurple,
              accentColor: GoddyTheme.neonPurple,
              onTap: () {
                _showGameModeSelectionSheet(
                  context: context,
                  gameType: GameType.sudoku,
                  icon: '🔢',
                  title: 'SUDOKU HOLOGRAM',
                  description: 'Ma trận Sudoku 9x9 quang học và thách đấu tốc độ',
                  accentColor: GoddyTheme.neonPurple,
                  soloScreen: const SudokuScreen(),
                );
              },
            ),

            const SizedBox(height: 12),

            // Game 4: Gyro Tilt Slide Puzzle
            _buildGameCard(
              context: context,
              icon: '📱',
              title: 'GYRO TILT PUZZLE',
              subtitle: 'Xếp hình trượt số Cảm biến Nghiêng máy + Bộ giải A* • Chọn 1P Solo hoặc 2P Thách Đấu',
              tag: '1P SOLO • 2P THÁCH ĐẤU',
              tagColor: GoddyTheme.neonGreen,
              accentColor: GoddyTheme.neonGreen,
              onTap: () {
                _showGameModeSelectionSheet(
                  context: context,
                  gameType: GameType.slidePuzzle,
                  icon: '📱',
                  title: 'GYRO TILT PUZZLE',
                  description: 'Trượt ô số cảm biến con quay hồi chuyển và thách đấu bạn bè',
                  accentColor: GoddyTheme.neonGreen,
                  soloScreen: const SlidePuzzleScreen(),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: GoddyTheme.glowBox(
          borderColor: accentColor,
          bgColor: GoddyTheme.bgCard,
          radius: 16,
          glowOpacity: 0.1,
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: GoddyTheme.textSecondary, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: accentColor),
          ],
        ),
      ),
    );
  }
}

