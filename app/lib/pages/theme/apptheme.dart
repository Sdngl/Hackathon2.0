import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF0F7B64); // buttons, links
  static const accent = Color(0xFF1DB38A); // ring, highlights
  static const accentLight = Color(0xFFE3F5EF); // ring track, chips
  static const background = Color(0xFFF2F4F3);
  static const textDark = Color(0xFF0F1F1A);
  static const textMuted = Color(0xFF6B7572);
  static const label = Color(0xFF4A5552);
  static const hint = Color(0xFF9AA3A0);
  static const border = Color(0xFFDDE2E0);
  static const sleepBg = Color(0xFFEDE9FE);
  static const sleepText = Color(0xFF7C5CE0);
  static const splashTop = Color(0xFF22B48C);
  static const splashBottom = Color(0xFF0E7B63);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
    );
  }
}