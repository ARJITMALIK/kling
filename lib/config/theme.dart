import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core
  static const Color bgPrimary = Color(0xFF0A0A1A);
  static const Color bgSecondary = Color(0xFF12122A);
  static const Color bgCard = Color(0x0DFFFFFF); // 5% white
  static const Color bgCardHover = Color(0x1AFFFFFF); // 10% white

  // Accents
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentPurple = Color(0xFFC084FC);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color accentRed = Color(0xFFFF4466);
  static const Color accentOrange = Color(0xFFFF8C42);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF); // 60% white
  static const Color textMuted = Color(0x4DFFFFFF); // 30% white

  // Gradients
  static const LinearGradient gradientLove = LinearGradient(
    colors: [accentPink, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientFire = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF3366)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientBlue = LinearGradient(
    colors: [accentBlue, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientBg = LinearGradient(
    colors: [bgPrimary, bgSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Game-specific
  static const Color bubColor = Color(0xFFFF6B9D);
  static const Color arenaGreen = Color(0xFF4A7C59);
  static const Color arenaBrown = Color(0xFF8B6914);
  static const Color towerBlue = Color(0xFF4A90D9);
  static const Color towerRed = Color(0xFFD94A4A);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPink,
        secondary: AppColors.accentPurple,
        surface: AppColors.bgSecondary,
        error: AppColors.accentRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        selectedItemColor: AppColors.accentPink,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentPink, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
