import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography scale built on Material 3's [TextTheme], using
/// Inter for body/UI text and Sora for display/headline text.
abstract final class AppTextStyles {
  static TextTheme textTheme(Color baseColor) {
    final body = GoogleFonts.interTextTheme();
    final display = GoogleFonts.soraTextTheme();

    return body
        .copyWith(
          displayLarge: display.displayLarge,
          displayMedium: display.displayMedium,
          displaySmall: display.displaySmall,
          headlineLarge: display.headlineLarge,
          headlineMedium: display.headlineMedium,
          headlineSmall: display.headlineSmall,
          titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(
          bodyColor: baseColor,
          displayColor: baseColor,
        );
  }
}
