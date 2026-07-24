import 'package:flutter/material.dart';

/// IronCoach brand palette. Dark-first, high-contrast, accessible (WCAG AA
/// against their intended backgrounds).
abstract final class AppColors {
  // Brand
  static const Color emberOrange = Color(0xFFFF6B35);
  static const Color voltGreen = Color(0xFF39FF6A);
  static const Color electricBlue = Color(0xFF3D8BFF);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0B0D10);
  static const Color darkSurface = Color(0xFF15181D);
  static const Color darkSurfaceElevated = Color(0xFF1D2128);
  static const Color darkBorder = Color(0xFF2A2F38);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0F1F4);
  static const Color lightBorder = Color(0xFFE1E4E9);

  // Text
  static const Color darkTextPrimary = Color(0xFFF5F6F8);
  static const Color darkTextSecondary = Color(0xFFA6ADBB);
  static const Color lightTextPrimary = Color(0xFF14161A);
  static const Color lightTextSecondary = Color(0xFF5B616E);

  // Semantic
  static const Color success = Color(0xFF39D98A);
  static const Color warning = Color(0xFFFFB84D);
  static const Color error = Color(0xFFFF5563);
  static const Color info = electricBlue;

  // Macro colors (nutrition rings/charts)
  static const Color protein = Color(0xFFFF6B35);
  static const Color carbs = Color(0xFF3D8BFF);
  static const Color fat = Color(0xFFFFC93D);
  static const Color water = Color(0xFF39C8FF);

  // Gamification
  static const Color xpGold = Color(0xFFFFC93D);
  static const Color streakFlame = Color(0xFFFF6B35);
}
