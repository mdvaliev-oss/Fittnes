import 'package:flutter/material.dart';

/// Typographic scale built on Inter (an SF-adjacent, highly legible grotesque).
///
/// Inter ships in `assets/fonts` (OFL) — no runtime download, so the UI looks
/// the same offline and on phones that can't reach Google.
/// Numeric styles use tabular figures so weights/reps/timers don't jitter.
abstract final class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Inter';

  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
    List<FontFeature>? fontFeatures,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
        fontFeatures: fontFeatures,
      );

  static TextTheme textTheme(Color hi, Color mid) {
    final base = Typography.material2021()
        .white
        .apply(fontFamily: fontFamily, bodyColor: hi, displayColor: hi);
    return base.copyWith(
      displayLarge: inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
        color: hi,
      ),
      headlineLarge: inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.3,
        color: hi,
      ),
      headlineMedium: inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: hi,
      ),
      titleLarge: inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: hi,
      ),
      bodyLarge: inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: hi,
      ),
      bodyMedium: inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: mid,
      ),
      labelLarge: inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: hi,
      ),
      labelSmall: inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: mid,
      ),
    );
  }

  /// Large tabular-figure style for stats, timers and set weights.
  static TextStyle numeric(Color color, {double size = 28}) => inter(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -0.5,
      );
}
