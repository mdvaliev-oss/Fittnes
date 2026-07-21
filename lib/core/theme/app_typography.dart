import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographic scale built on Inter (an SF-adjacent, highly legible grotesque).
///
/// Numeric styles use tabular figures so weights/reps/timers don't jitter.
abstract final class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Color hi, Color mid) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
        color: hi,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.3,
        color: hi,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: hi,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: hi,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: hi,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: mid,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: hi,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: mid,
      ),
    );
  }

  /// Large tabular-figure style for stats, timers and set weights.
  static TextStyle numeric(Color color, {double size = 28}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -0.5,
      );
}
