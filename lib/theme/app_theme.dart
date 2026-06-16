import 'package:flutter/material.dart';

/// Brand colors taken from the Eye-Money Figma design.
class AppColors {
  static const green = Color(0xFF12B21A); // brand green
  static const ink = Color(0xFF1E1E1E); // primary text
  static const white = Color(0xFFFFFFFF);
  static const pill = Color(0xFFEEEEEE); // date separators
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        primary: AppColors.green,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
    );
  }
}
