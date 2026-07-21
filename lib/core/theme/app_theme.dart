import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'glass_theme.dart';

/// Assembles the Material 3 [ThemeData] for light & dark, wiring in the
/// design tokens and the [AppGlassTheme] extension.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scaffold: AppColors.bgBase,
        surface: AppColors.surface,
        textHi: AppColors.textHi,
        textMid: AppColors.textMid,
        glass: AppGlassTheme.dark,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scaffold: AppColors.lightBgBase,
        surface: AppColors.lightSurface,
        textHi: AppColors.lightTextHi,
        textMid: AppColors.lightTextMid,
        glass: AppGlassTheme.light,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color textHi,
    required Color textMid,
    required AppGlassTheme glass,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: surface,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme(textHi, textMid),
      splashFactory: InkSparkle.splashFactory,
      extensions: [glass],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme(textHi, textMid).headlineMedium,
      ),
      dividerTheme: DividerThemeData(
        color: glass.border,
        thickness: 1,
        space: AppSpacing.lg,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    );
  }
}
