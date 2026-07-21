import 'package:flutter/material.dart';

/// Raw color palette — the single source of truth for all colors.
///
/// Never reference these directly in widgets; consume them through
/// [ThemeData] / [AppGlassTheme] so light/dark themes stay swappable.
abstract final class AppColors {
  const AppColors._();

  // ── Dark theme (primary experience) ──────────────────────────────
  static const Color bgBase = Color(0xFF0A0A0F); // warm near-black
  static const Color surface = Color(0xFF14141C);
  static const Color surfaceHigh = Color(0xFF1C1C26);

  // Glassmorphism layer
  static const Color glassFill = Color(0x0FFFFFFF); // white @ ~6%
  static const Color glassBorder = Color(0x14FFFFFF); // white @ ~8%

  // Brand
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryBright = Color(0xFF8B7CF6);
  static const Color accent = Color(0xFF00E5A0); // PR / success / mint
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5C5C);

  // Text
  static const Color textHi = Color(0xFFFFFFFF);
  static const Color textMid = Color(0xFFA0A0B0);
  static const Color textLow = Color(0xFF6C6C7A);

  // ── Light theme ──────────────────────────────────────────────────
  static const Color lightBgBase = Color(0xFFF4F4F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFECECF2);
  static const Color lightGlassFill = Color(0x0A000000);
  static const Color lightGlassBorder = Color(0x14000000);
  static const Color lightTextHi = Color(0xFF0A0A0F);
  static const Color lightTextMid = Color(0xFF52525F);
  static const Color lightTextLow = Color(0xFF9A9AA6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryBright],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
