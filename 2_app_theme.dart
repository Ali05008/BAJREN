import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized BAJREN theme. Replaces the ad-hoc ThemeData that used to
/// live inline in main.dart, so brand colors are defined in exactly one
/// place (app_colors.dart) and reused consistently across the app.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.cyan,
      secondary: AppColors.purple,
      brightness: brightness,
      surface: isDark ? AppColors.nearBlack : Colors.white,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.nearBlack : colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.nearBlack : Colors.white,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.nearBlack : Colors.white,
        selectedItemColor: AppColors.cyan,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
