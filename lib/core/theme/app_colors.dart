import 'package:flutter/material.dart';

/// Brand colors extracted from the official BAJREN logo: a cyan-to-purple
/// gradient icon on a near-black rounded background.
///
/// These are the single source of truth for BAJREN's brand palette. Do not
/// introduce new brand colors elsewhere; extend this file instead.
class AppColors {
  AppColors._();

  /// Cyan end of the logo gradient.
  static const cyan = Color(0xFF22D3EE);

  /// Purple/magenta end of the logo gradient.
  static const purple = Color(0xFFA855F7);

  /// Near-black background used behind the logo mark.
  static const nearBlack = Color(0xFF0F0F14);

  /// Slightly lighter dark surface, for cards/sheets in dark mode.
  static const darkSurface = Color(0xFF1A1A22);

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  /// Gradient matching the logo mark, for use on splash/login branding only.
  static const logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, purple],
  );
}
