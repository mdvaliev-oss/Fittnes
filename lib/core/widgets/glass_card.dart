import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/glass_theme.dart';
import 'pressable_scale.dart';

/// The signature glassmorphism surface used across the whole app.
///
/// Reads blur / fill / border from [AppGlassTheme] so it adapts to the active
/// theme automatically. Optionally tappable with a subtle press-scale.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius,
    this.onTap,
    this.gradientBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  /// When true, draws a faint brand-tinted border for emphasis (hero cards).
  final bool gradientBorder;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.card);

    final card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: glass.fill,
            borderRadius: radius,
            border: Border.all(
              color: gradientBorder
                  ? glass.accent.withValues(alpha: 0.35)
                  : glass.border,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) return card;
    return PressableScale(onTap: onTap, scale: 0.97, child: card);
  }
}
