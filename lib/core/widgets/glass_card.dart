import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/glass_theme.dart';

/// The signature glassmorphism surface used across the whole app.
///
/// Reads blur / fill / border from [AppGlassTheme] so it adapts to the active
/// theme automatically. Optionally tappable with a subtle press-scale.
class GlassCard extends StatefulWidget {
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
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.card);

    final card = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: AppMotion.fast,
      curve: Curves.easeOut,
      child: ClipRRect(
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
                color: widget.gradientBorder
                    ? glass.accent.withValues(alpha: 0.35)
                    : glass.border,
              ),
            ),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}
