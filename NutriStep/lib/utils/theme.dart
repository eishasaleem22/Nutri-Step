// utils/theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

final ColorScheme _nutriStepColors = ColorScheme(
  brightness: Brightness.dark,
  primary:       AppColors.accentTeal,
  onPrimary:     Colors.white,
  secondary:     AppColors.accentYellow,
  onSecondary:   Colors.white,
  background:    AppColors.darkBackground,
  onBackground:  AppColors.textLight,
  surface:       AppColors.cardDark,
  onSurface:     AppColors.textLight,
  error:         Colors.redAccent,
  onError:       Colors.white,
);

final ThemeData appTheme = ThemeData.from(colorScheme: _nutriStepColors).copyWith(
  // make sure AppBar etc. fall back to these
  scaffoldBackgroundColor: _nutriStepColors.background,
  cardColor:               _nutriStepColors.surface,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: _nutriStepColors.primary,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.bold),
    titleLarge:    TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium:   TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge:     TextStyle(fontFamily: 'Poppins', fontSize: 16),
    bodyMedium:    TextStyle(fontFamily: 'Poppins', fontSize: 14),
    bodySmall:     TextStyle(fontFamily: 'Poppins', fontSize: 12),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled:      true,
    fillColor:   _nutriStepColors.surface,
    hintStyle:   TextStyle(color: _nutriStepColors.onSurface.withOpacity(0.6)),
    labelStyle:  TextStyle(color: _nutriStepColors.primary),
    prefixIconColor: _nutriStepColors.primary,
    enabledBorder:   OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _nutriStepColors.onSurface.withAlpha(60)),
    ),
    focusedBorder:   OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _nutriStepColors.primary),
    ),
  ),
  // Button themes, DividerTheme, etc. if you want:
  dividerTheme: DividerThemeData(color: _nutriStepColors.onSurface.withAlpha(60)),
);
