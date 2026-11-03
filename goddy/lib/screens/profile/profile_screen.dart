import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showAvatarPicker(BuildContext context, AuthService auth) {
    final avatars = ['🤖', '⚡', '🥷', '👑', '👻', '👾', '🚀', '🏎️', '🎯'];
    showModalBottomSheet(
      context: context,
      backgroundColor: GoddyTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHỌN AVATAR MỚI',
              style: GoogleFonts.orbitron(color: GoddyTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: avatars.map((av) {
                return InkWell(
                  onTap: () {
                    auth.updateProfile(avatar: av);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(child: Text(av, style: const TextStyle(fontSize: 28))),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(backgroundColor: GoddyTheme.bgDark);
    }

    final tier = user.rankTier;
    final exp = user.exp;

    return Scaffold(
      backgroundColor: GoddyTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'HỒ SƠ GAME THỦ',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: GoddyTheme.neonRed),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Gamer Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: GoddyTheme.glowBox(
                borderColor: GoddyTheme.neonCyan,
                bgColor: GoddyTheme.bgCard,
                radius: 20,
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: GoddyTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Text(user.avatar, style: const TextStyle(fontSize: 42)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () => _showAvatarPicker(context, auth),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: GoddyTheme.neonMagenta,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.username,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: GoddyTheme.neonCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GoddyTheme.neonCyan),
                    ),
                    child: Text(
                      'Hạng: ${tier.nameVi.toUpperCase()}',
                      style: const TextStyle(color: GoddyTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // EXP Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cấp Bậc Rank EXP:', style: TextStyle(color: GoddyTheme.textSecondary, fontSize: 11)),
                      Text('$exp EXP', style: const TextStyle(color: GoddyTheme.neonAmber, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (exp % 3000) / 3000,
                    backgroundColor: Colors.white12,
                    color: GoddyTheme.neonCyan,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Career Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('SỐ TRẬN ĐÃ ĐẤU', '${user.gamesPlayed}', Icons.sports_esports, GoddyTheme.neonBlue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard('SỐ TRẬN THẮNG', '${user.winsCount}', Icons.emoji_events, GoddyTheme.neonGreen),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard('TỶ LỆ THẮNG', '${user.winRate.toStringAsFixed(0)}%', Icons.insights, GoddyTheme.neonAmber),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Game Best Records
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GoddyTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KỶ LỤC CÁ NHÂN TỐT NHẤT',
                    style: GoogleFonts.orbitron(color: GoddyTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildRecordRow('🧩 Rubik 3D Solver:', user.rubikBestSeconds > 0 ? '${user.rubikBestSeconds} giây' : 'Chưa đấu'),
                  _buildRecordRow('⭕ Quantum Caro:', user.caroBestScore > 0 ? '${user.caroBestScore} điểm' : 'Chưa đấu'),
                  _buildRecordRow('🔢 Sudoku Hologram:', user.sudokuBestSeconds > 0 ? '${user.sudokuBestSeconds} giây' : 'Chưa đấu'),
                  _buildRecordRow('📱 Gyro Tilt Puzzle:', user.puzzleBestSeconds > 0 ? '${user.puzzleBestSeconds} giây' : 'Chưa đấu'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Badges
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GoddyTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HUY HIỆU DANH HIỆU',
                    style: GoogleFonts.orbitron(color: GoddyTheme.neonMagenta, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.badges.map((b) {
                      return Chip(
                        backgroundColor: GoddyTheme.neonPurple.withValues(alpha: 0.2),
                        side: const BorderSide(color: GoddyTheme.neonMagenta, width: 0.8),
                        label: Text(
                          '🎖️ $b',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: GoddyTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            val,
            style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: GoddyTheme.textSecondary, fontSize: 13)),
          Text(val, style: const TextStyle(color: GoddyTheme.neonAmber, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
