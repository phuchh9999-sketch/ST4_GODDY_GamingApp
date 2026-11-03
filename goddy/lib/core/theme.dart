import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GoddyTheme {
  // Core Neon Color Palette
  static const Color bgDark = Color(0xFF090D16);
  static const Color bgCard = Color(0xFF131B2E);
  static const Color bgElevated = Color(0xFF1C2742);
  
  static const Color neonCyan = Color(0xFF00F2FE);
  static const Color neonBlue = Color(0xFF4FACFE);
  static const Color neonPurple = Color(0xFFB5179E);
  static const Color neonMagenta = Color(0xFFF72585);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonAmber = Color(0xFFFFB703);
  static const Color neonOrange = Color(0xFFFB8500);
  static const Color neonRed = Color(0xFFFF3366);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonCyan, neonBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [neonMagenta, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD166), Color(0xFFFF9E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF141C30), Color(0xFF0E1424)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: neonCyan,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonMagenta,
        surface: bgCard,
        error: neonRed,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark.withValues(alpha: 0.85),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: neonCyan,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: neonCyan),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: neonCyan.withValues(alpha: 0.15), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: neonCyan.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: neonCyan.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: neonCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: neonRed, width: 1.5),
        ),
      ),
    );
  }

  // Glow Box Decoration Helper
  static BoxDecoration glowBox({
    Color borderColor = neonCyan,
    Color bgColor = bgCard,
    double radius = 16,
    double glowOpacity = 0.25,
  }) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: borderColor.withValues(alpha: glowOpacity),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ],
    );
  }
}
