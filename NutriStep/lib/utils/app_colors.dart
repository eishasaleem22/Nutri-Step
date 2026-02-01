// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const darkBackground  = Color(0xFF1A1A1A);
  static const cardDark        = Color(0xFF2A2A2A);
  static const accentTeal      = Color(0xFF00C6A7);
  static const accentYellow    = Color(0xFFFFD500);
  static const accentBlue      = Color(0xFF006EFF);
  static const textLight       = Color(0xFFE0E0E0);
  static const textSecondary   = Color(0xFFBBBBBB);
}

class AppGradients {
  static const nutriStep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.accentTeal,
      AppColors.accentYellow,
      AppColors.accentBlue,
    ],
  );
}
