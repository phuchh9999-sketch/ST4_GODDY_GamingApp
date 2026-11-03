import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme.dart';
import 'config/api_config.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/leaderboard_service.dart';
import 'services/challenge_service.dart';
import 'services/chat_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_dashboard_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await StorageService.init();
  await ApiConfig.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LeaderboardService()),
        ChangeNotifierProvider(create: (_) => ChallengeService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
      ],
      child: const GoddyApp(),
    ),
  );
}

class GoddyApp extends StatelessWidget {
  const GoddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goddy Gaming Hub',
      debugShowCheckedModeBanner: false,
      theme: GoddyTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: GoddyTheme.bgDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: GoddyTheme.glowBox(
                  borderColor: GoddyTheme.neonCyan,
                  bgColor: GoddyTheme.bgCard,
                  radius: 20,
                ),
                child: const Center(
                  child: Text('🎮', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'GODDY GAMING',
                style: GoogleFonts.orbitron(
                  color: GoddyTheme.neonCyan,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: GoddyTheme.neonCyan,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const HomeDashboardScreen();
    }

    return const LoginScreen();
  }
}
