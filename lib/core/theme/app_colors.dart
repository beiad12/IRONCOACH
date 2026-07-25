import 'package:flutter/material.dart';

/// IronCoach brand palette — dark, premium AI fitness coaching. Sourced
/// from the Claude Design handoff (`IronCoach.dc.html`)'s design-system
/// token board: Electric Blue + Emerald on near-black, high-contrast text
/// at fixed opacity tiers rather than distinct named colors.
abstract final class AppColors {
  // Brand
  static const Color electricBlue = Color(0xFF4EA8FF);
  static const Color electricBlueLight = Color(0xFF6EBBFF);
  static const Color electricBlueDeep = Color(0xFF3E93F0);
  static const Color emerald = Color(0xFF00D084);
  static const Color emeraldLight = Color(0xFF22DFA0);
  static const Color emeraldDeep = Color(0xFF00B473);

  // Dark theme surfaces (primary, default theme)
  static const Color darkBackground = Color(0xFF0B0B0B);
  static const Color darkSurface = Color(0xFF16171A);
  static const Color darkSurfaceElevatedTop = Color(0xFF1C1D21);
  static const Color darkSurfaceElevatedBottom = Color(0xFF141518);
  static const Color darkInputSurface = Color(0xFF151619);
  static const Color darkTrack = Color(0xFF111214);
  static const Color darkActivePill = Color(0xFF232428);
  static const Color darkBorder = Color(0x14FFFFFF); // rgba(255,255,255,.08)

  // Light theme surfaces (secondary — the design is dark-only, so these are
  // derived sensibly rather than specified)
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0F1F4);
  static const Color lightBorder = Color(0xFFE1E4E9);

  // Text — dark theme uses white at fixed opacity tiers throughout the
  // design rather than separate named colors.
  static const Color darkTextPrimary = Color(0xFFF5F6F7);
  static Color darkText(double opacity) => darkTextPrimary.withValues(alpha: opacity);
  static const Color darkTextSecondary = Color(0x80F5F6F7); // ~50%
  static const Color darkTextTertiary = Color(0x66F5F6F7); // ~40%
  static const Color lightTextPrimary = Color(0xFF14161A);
  static const Color lightTextSecondary = Color(0xFF5B616E);

  // Semantic
  static const Color success = emerald;
  static const Color warning = Color(0xFFFFB84D);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = electricBlue;

  // On-gradient text (dark-on-bright, used on primary/success buttons)
  static const Color onPrimaryGradient = Color(0xFF04101F);
  static const Color onSuccessGradient = Color(0xFF04140D);

  // Macro colors (nutrition rings/charts)
  static const Color protein = electricBlue;
  static const Color carbs = emerald;
  static const Color fat = Color(0xFFFFC93D);
  static const Color water = Color(0xFF39C8FF);

  // Gamification
  static const Color xpGold = Color(0xFFFFC93D);
  static const Color streakFlame = Color(0xFFFF8A3D);

  // Gradients
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlueLight, electricBlueDeep],
  );

  static const LinearGradient successButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emeraldLight, emeraldDeep],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkSurfaceElevatedTop, darkSurfaceElevatedBottom],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF191C22), Color(0xFF152030)],
  );

  static const LinearGradient premiumCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x294EA8FF), Color(0x2100D084)],
  );

  static const LinearGradient brandIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlue, emerald],
  );
}
