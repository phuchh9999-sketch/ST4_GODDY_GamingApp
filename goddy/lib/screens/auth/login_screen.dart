import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'player@goddy.io');
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showConfigServerDialog() {
    final serverController = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              'CẤU HÌNH WEBAPI HOST',
              style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập địa chỉ WebAPI Backend (Hỗ trợ Conveyor Free / 4G / DevTunnel):',
                style: TextStyle(fontSize: 12, color: GoddyTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: serverController,
                style: const TextStyle(color: GoddyTheme.neonCyan, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'https://xxxx.conveyor.cloud/api/ hoặc DevTunnel',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: GoddyTheme.neonCyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gợi ý cấu hình kết nối nhanh:',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildQuickHostChip('Conveyor Cloud (Free)', 'https://conveyor.cloud/api/', serverController),
                  _buildQuickHostChip('Conveyor LAN (:45455)', 'http://192.168.1.6:45455/api/', serverController),
                  _buildQuickHostChip('Emulator (10.0.2.2)', 'http://10.0.2.2:5271/api/', serverController),
                  _buildQuickHostChip('Localhost:5271', 'http://localhost:5271/api/', serverController),
                  _buildQuickHostChip('DevTunnel / Ngrok', 'https://', serverController),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GoddyTheme.neonCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final newUrl = serverController.text.trim();
              await ApiConfig.setCustomBaseUrl(newUrl);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🌐 Đã lưu WebAPI Host: ${ApiConfig.baseUrl}'),
                  backgroundColor: GoddyTheme.neonGreen,
                ),
              );
            },
            child: const Text('Lưu & Kết Nối', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHostChip(String label, String url, TextEditingController controller) {
    return ActionChip(
      backgroundColor: const Color(0xFF1E293B),
      side: const BorderSide(color: Colors.white24),
      label: Text(label, style: const TextStyle(fontSize: 10, color: GoddyTheme.neonCyan)),
      onPressed: () => controller.text = url,
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthService>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        setState(() => _errorMessage = 'Email hoặc mật khẩu không đúng!');
      }
    }
  }

  Future<void> _handleQuickDemoLogin() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    await auth.demoQuickLogin();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoddyTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dns, color: GoddyTheme.neonCyan),
            tooltip: 'Cấu hình WebAPI Host (Khác mạng / Tunnel)',
            onPressed: _showConfigServerDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cyber Goddy Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: GoddyTheme.glowBox(
                    borderColor: GoddyTheme.neonCyan,
                    bgColor: GoddyTheme.bgCard,
                    radius: 24,
                  ),
                  child: const Center(
                    child: Text('🎮', style: TextStyle(fontSize: 40)),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'GODDY GAMING',
                  style: GoogleFonts.orbitron(
                    color: GoddyTheme.neonCyan,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: GoddyTheme.neonCyan.withValues(alpha: 0.6), blurRadius: 12),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Cổng Trò Chơi Trí Tuệ & Thách Đấu Đối Kháng',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GoddyTheme.textSecondary, fontSize: 13),
                ),

                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: GoddyTheme.neonRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GoddyTheme.neonRed),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: GoddyTheme.neonRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                // Email field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email game thủ',
                    prefixIcon: Icon(Icons.email_outlined, color: GoddyTheme.neonCyan),
                  ),
                ),

                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock_outline, color: GoddyTheme.neonCyan),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GoddyTheme.neonCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 8,
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            'ĐĂNG NHẬP VÀO GAME',
                            style: GoogleFonts.orbitron(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                // Quick Demo Login Button (Ideal for examiner to test immediately)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: GoddyTheme.neonMagenta, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.bolt, color: GoddyTheme.neonMagenta),
                    label: const Text(
                      'Đăng Nhập Nhanh Tân Thủ (Demo 1-Chạm)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _isLoading ? null : _handleQuickDemoLogin,
                  ),
                ),

                const SizedBox(height: 24),

                // Navigate to Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản game thủ?', style: TextStyle(color: GoddyTheme.textSecondary)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(color: GoddyTheme.neonCyan, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
