import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF0F1B35);
  static const Color teal = Color(0xFF00C9B1);
  static const Color amber = Color(0xFFFFB347);
  static const Color background = Color(0xFFEEF2F8);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color passGreen = Color(0xFF3B6D11);
  static const Color passBg = Color(0xFFEAF3DE);
  static const Color failRed = Color(0xFFA32D2D);
  static const Color failBg = Color(0xFFFCEBEB);
  static const Color pendingBg = Color(0xFFFAEEDA);
  static const Color pendingText = Color(0xFF854F0B);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
  );
}