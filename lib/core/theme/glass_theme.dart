import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Glassmorphism tokens exposed via [ThemeExtension] so every surface reads
/// the same blur / fill / border and both light & dark themes stay in sync.
@immutable
class AppGlassTheme extends ThemeExtension<AppGlassTheme> {
  const AppGlassTheme({
    required this.fill,
    required this.border,
    required this.blurSigma,
    required this.accent,
    required this.textHi,
    required this.textMid,
    required this.textLow,
  });

  final Color fill;
  final Color border;
  final double blurSigma;
  final Color accent;
  final Color textHi;
  final Color textMid;
  final Color textLow;

  static const AppGlassTheme dark = AppGlassTheme(
    fill: AppColors.glassFill,
    border: AppColors.glassBorder,
    blurSigma: 20,
    accent: AppColors.accent,
    textHi: AppColors.textHi,
    textMid: AppColors.textMid,
    textLow: AppColors.textLow,
  );

  static const AppGlassTheme light = AppGlassTheme(
    fill: AppColors.lightGlassFill,
    border: AppColors.lightGlassBorder,
    blurSigma: 18,
    accent: AppColors.accent,
    textHi: AppColors.lightTextHi,
    textMid: AppColors.lightTextMid,
    textLow: AppColors.lightTextLow,
  );

  @override
  AppGlassTheme copyWith({
    Color? fill,
    Color? border,
    double? blurSigma,
    Color? accent,
    Color? textHi,
    Color? textMid,
    Color? textLow,
  }) {
    return AppGlassTheme(
      fill: fill ?? this.fill,
      border: border ?? this.border,
      blurSigma: blurSigma ?? this.blurSigma,
      accent: accent ?? this.accent,
      textHi: textHi ?? this.textHi,
      textMid: textMid ?? this.textMid,
      textLow: textLow ?? this.textLow,
    );
  }

  @override
  AppGlassTheme lerp(ThemeExtension<AppGlassTheme>? other, double t) {
    if (other is! AppGlassTheme) return this;
    return AppGlassTheme(
      fill: Color.lerp(fill, other.fill, t)!,
      border: Color.lerp(border, other.border, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t),
      accent: Color.lerp(accent, other.accent, t)!,
      textHi: Color.lerp(textHi, other.textHi, t)!,
      textMid: Color.lerp(textMid, other.textMid, t)!,
      textLow: Color.lerp(textLow, other.textLow, t)!,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Ergonomic access: `context.glass`.
extension GlassThemeX on BuildContext {
  AppGlassTheme get glass =>
      Theme.of(this).extension<AppGlassTheme>() ?? AppGlassTheme.dark;
}
