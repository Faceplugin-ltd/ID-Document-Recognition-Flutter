import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0F1419);
  static const card = Color(0xFF5B2D8E);
  static const accent = Color(0xFF3DD68C);
  static const accentDim = Color(0x403DD68C);
  static const text = Color(0xFFFFFFFF);
  static const muted = Color(0xFF9AA4B2);
  static const statusInfo = Color(0xFF1E3A5F);
  static const statusOk = Color(0xFF14532D);
  static const statusWarn = Color(0xFF78350F);
  static const statusError = Color(0xFF7F1D1D);
  static const surface = Color(0xFF1A222D);
  static const border = Color(0xFF2A3441);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
    );
  }
}
