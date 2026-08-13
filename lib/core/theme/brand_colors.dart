import 'package:flutter/material.dart';

/// BAJREN brand palette, matching the app-wide AppTheme
/// (cyan #22D3EE, purple #A855F7, near-black background #0F0F14).
/// Kept as simple static constants here so the auth screens stay
/// self-contained and don't assume a specific AppTheme API surface.
class BrandColors {
  BrandColors._();

  static const Color cyan = Color(0xFF22D3EE);
  static const Color purple = Color(0xFFA855F7);
  static const Color background = Color(0xFF0F0F14);
  static const Color surface = Color(0xFF17171F);
  static const Color surfaceBorder = Color(0xFF2A2A35);
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF9A9AA5);
  static const Color error = Color(0xFFEF4444);
  static const Color gold = Color(0xFFF5B942);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyan, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
