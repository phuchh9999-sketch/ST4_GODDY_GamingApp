import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/challenge_service.dart';
import 'duel_room_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _pinController = TextEditingController();
  GameType _selectedGame = GameType.caro;
  final String _selectedDifficulty = 'Normal';
  bool _isJoining = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeService>().fetchActiveRooms();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateRoom() async {
    final auth = context.read<AuthService>();
    final challenge = context.read<ChallengeService>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập trước khi tạo phòng!')),
      );
      return;
    }

    setState(() => _isCreating = true);
    final room = await challenge.createRoomAsync(
      host: user,
      gameType: _selectedGame,
      difficulty: _selectedDifficulty,
    );
    if (!mounted) return;
    setState(() => _isCreating = false);

    if (room != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DuelRoomScreen(roomCode: room.roomCode)),
      );
    } else {
      _showServerConfigDialog(
        errorMessage: '⚠️ Không thể khởi tạo phòng trên máy chủ WebAPI!\nHãy đảm bảo máy chính đang chạy "dotnet run" và điện thoại kết nối cùng mạng Wi-Fi.',
      );
    }
  }

  Future<void> _handleJoinRoom([String? customCode]) async {
    final code = (customCode ?? _pinController.text).trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập hoặc quét mã PIN phòng 6 ký tự!')),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final challenge = context.read<ChallengeService>();
    final user = auth.currentUser;

    if (user == null) return;

    setState(() => _isJoining = true);

    try {
      final success = await challenge.joinRoom(roomCode: code, guest: user);
      if (!mounted) return;
      setState(() => _isJoining = false);

      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DuelRoomScreen(roomCode: code)),
        );
      } else {
        final err = challenge.lastJoinError ?? 'Phòng thách đấu không tồn tại hoặc đã đầy!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $err'),
            backgroundColor: GoddyTheme.neonRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _showServerConfigDialog({String? errorMessage}) {
    final serverController = TextEditingController(text: ApiConfig.baseUrl);
    bool testing = false;
    String? testResult;
    Color testColor = Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: GoddyTheme.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: GoddyTheme.neonCyan, width: 1.5),
            ),
            title: Row(
              children: [
                const Icon(Icons.dns, color: GoddyTheme.neonCyan),
                const SizedBox(width: 8),
                Text(
                  'CẤU HÌNH MÁY CHỦ WEBAPI',
                  style: GoogleFonts.orbitron(color: GoddyTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                      ),
                    ),
                  ],
                  const Text(
                    'Nhập địa chỉ IP máy tính đang chạy WebAPI (.NET 9):',
                    style: TextStyle(color: GoddyTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: serverController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'WebAPI Base URL',
                      labelStyle: const TextStyle(color: GoddyTheme.neonCyan, fontSize: 12),
                      hintText: 'http://192.168.50.80:5271/api/',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => serverController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chọn nhanh địa chỉ gợi ý:',
                    style: TextStyle(color: GoddyTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        backgroundColor: const Color(0xFF1E293B),
                        label: const Text('Wi-Fi: 192.168.50.80', style: TextStyle(fontSize: 10, color: GoddyTheme.neonGreen)),
                        onPressed: () => serverController.text = 'http://192.168.50.80:5271/api/',
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF1E293B),
                        label: const Text('Giả lập (10.0.2.2)', style: TextStyle(fontSize: 10, color: GoddyTheme.neonCyan)),
                        onPressed: () => serverController.text = 'http://10.0.2.2:5271/api/',
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF1E293B),
                        label: const Text('Localhost (5271)', style: TextStyle(fontSize: 10, color: GoddyTheme.neonAmber)),
                        onPressed: () => serverController.text = 'http://localhost:5271/api/',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (testResult != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: testColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: testColor),
                      ),
                      child: Text(
                        testResult!,
                        style: TextStyle(color: testColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GoddyTheme.neonCyan,
                        side: const BorderSide(color: GoddyTheme.neonCyan),
                      ),
                      icon: testing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: GoddyTheme.neonCyan))
                          : const Icon(Icons.network_check, size: 16),
                      label: Text(testing ? 'Đang kiểm tra...' : 'Kiểm tra kết nối tới Server', style: const TextStyle(fontSize: 11)),
                      onPressed: testing ? null : () async {
                        setDialogState(() {
                          testing = true;
                          testResult = null;
                        });
                        final testUrl = serverController.text.trim();
                        await ApiConfig.setCustomBaseUrl(testUrl);
                        try {
                          final res = await ApiClient().get('health');
                          if (res != null && res.statusCode == 200) {
                            setDialogState(() {
                              testing = false;
                              testResult = '✅ Kết nối thành công tới WebAPI & SQLite!';
                              testColor = GoddyTheme.neonGreen;
                            });
                          } else {
                            setDialogState(() {
                              testing = false;
                              testResult = '⚠️ Máy chủ phản hồi mã: ${res?.statusCode}';
                              testColor = GoddyTheme.neonAmber;
                            });
                          }
                        } catch (e) {
                          setDialogState(() {
                            testing = false;
                            testResult = '❌ Không thể kết nối: $e';
                            testColor = GoddyTheme.neonRed;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GoddyTheme.neonCyan,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final newUrl = serverController.text.trim();
                  await ApiConfig.setCustomBaseUrl(newUrl);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('🌐 Đã lưu máy chủ: ${ApiConfig.baseUrl}'),
                        backgroundColor: GoddyTheme.neonGreen,
                      ),
                    );
                  }
                },
                child: const Text('Lưu cấu hình', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQrScannerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GoddyTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: GoddyTheme.neonCyan, width: 1.5),
      ),
      builder: (ctx) {
        final challenge = context.watch<ChallengeService>();
        final openRooms = challenge.recentRoomCodes;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, color: GoddyTheme.neonCyan, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'QUÉT MÃ QR PHÒNG ĐẤU',
                    style: GoogleFonts.orbitron(color: GoddyTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Hướng camera về mã QR trên máy chủ phòng hoặc dán mã PIN',
                textAlign: TextAlign.center,
                style: TextStyle(color: GoddyTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 16),

              // Cyberpunk Viewfinder Frame
              Container(
                width: 220,
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GoddyTheme.neonCyan, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: GoddyTheme.neonCyan.withValues(alpha: 0.25), blurRadius: 15),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.qr_code_2, size: 90, color: Colors.white24),
                    // Animated scanning beam
                    Positioned(
                      top: 45,
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          boxShadow: const [BoxShadow(color: GoddyTheme.neonCyan, blurRadius: 8)],
                          color: GoddyTheme.neonCyan,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: GoddyTheme.bgDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GoddyTheme.neonCyan.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'SCANNER READY • ĐANG QUÉT',
                          style: TextStyle(color: GoddyTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action: Paste from Clipboard
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoddyTheme.neonCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text('DÁN MÃ TỪ BỘ NHỚ TẠM (CLIPBOARD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    final text = data?.text?.trim().toUpperCase() ?? '';
                    if (!mounted) return;
                    if (text.isNotEmpty) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      _pinController.text = text;
                      _handleJoinRoom(text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bộ nhớ tạm trống! Hãy sao chép mã phòng từ chủ phòng trước.')),
                      );
                    }
                  },
                ),
              ),

              if (openRooms.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PHÒNG VỪA MỞ TRÊN HỆ THỐNG:',
                    style: GoogleFonts.orbitron(color: GoddyTheme.neonAmber, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: openRooms.map((code) => ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: GoddyTheme.neonAmber),
                    avatar: const Icon(Icons.bolt, size: 14, color: GoddyTheme.neonAmber),
                    label: Text(code, style: const TextStyle(color: GoddyTheme.neonAmber, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pinController.text = code;
                      _handleJoinRoom(code);
                    },
                  )).toList(),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoddyTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'THÁCH ĐẤU ĐỐI KHÁNG',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet, color: GoddyTheme.neonCyan),
            tooltip: 'Cài đặt IP WebAPI',
            onPressed: () => _showServerConfigDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Duel Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: GoddyTheme.glowBox(
                borderColor: GoddyTheme.neonMagenta,
                bgColor: GoddyTheme.bgCard,
                radius: 18,
                glowOpacity: 0.2,
              ),
              child: Row(
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 44)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐẤU TRƯỜNG 1v1 REAL-TIME',
                          style: GoogleFonts.orbitron(
                            color: GoddyTheme.neonMagenta,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Cùng giải một đề bài / thế cờ để so tài thời gian và độ chính xác!',
                          style: TextStyle(color: GoddyTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Server Connection Status Chip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dns, size: 14, color: GoddyTheme.neonGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Máy chủ: ${ApiConfig.baseUrl}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showServerConfigDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GoddyTheme.neonCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: GoddyTheme.neonCyan, width: 0.8),
                      ),
                      child: const Text(
                        'Đổi IP',
                        style: TextStyle(color: GoddyTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 1: Create Room
            Text(
              'TẠO PHÒNG THÁCH ĐẤU MỚI',
              style: GoogleFonts.orbitron(color: GoddyTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

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
                  const Text('Chọn game so tài:', style: TextStyle(color: GoddyTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<GameType>(
                    initialValue: _selectedGame,
                    dropdownColor: GoddyTheme.bgCard,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    items: GameType.values.map((g) {
                      return DropdownMenuItem(
                        value: g,
                        child: Text(g.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGame = val);
                    },
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoddyTheme.neonMagenta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isCreating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add_circle_outline),
                      label: Text(
                        _isCreating ? 'ĐANG TẠO PHÒNG TRÊN MÁY CHỦ...' : 'TẠO PHÒNG & LẤY MÃ QR / PIN',
                        style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _isCreating ? null : _handleCreateRoom,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Join Room with PIN or QR
            Text(
              'THAM GIA PHÒNG ĐẤU ĐÃ CÓ',
              style: GoogleFonts.orbitron(color: GoddyTheme.neonAmber, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GoddyTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  // Prominent QR Scanner Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: GoddyTheme.neonCyan,
                        side: const BorderSide(color: GoddyTheme.neonCyan, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, color: GoddyTheme.neonCyan, size: 22),
                      label: Text(
                        'QUÉT MÃ QR PHÒNG ĐẤU',
                        style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      onPressed: _showQrScannerModal,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('HOẶC NHẬP PIN', style: TextStyle(color: GoddyTheme.textMuted, fontSize: 11)),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _pinController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.orbitron(
                      color: GoddyTheme.neonCyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'NHẬP MÃ PIN (VD: KGJAND)',
                      hintStyle: const TextStyle(letterSpacing: 1, fontSize: 13),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: GoddyTheme.neonCyan),
                        tooltip: 'Quét mã QR',
                        onPressed: _showQrScannerModal,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoddyTheme.neonCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isJoining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        _isJoining ? 'ĐANG KẾT NỐI VÀO PHÒNG...' : 'VÀO PHÒNG TRANH TÀI',
                        style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _isJoining ? null : () => _handleJoinRoom(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
