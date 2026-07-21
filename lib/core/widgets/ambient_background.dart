import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ambient dark backdrop with two soft brand-tinted glows.
///
/// Gives the glass surfaces something to refract, which is what sells the
/// glassmorphism look. Cheap: two radial gradients, no blur passes.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.bgBase : AppColors.lightBgBase;

    return DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _Glow(
              color: AppColors.primary.withOpacity(isDark ? 0.28 : 0.14),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -100,
            child: _Glow(
              color: AppColors.accent.withOpacity(isDark ? 0.16 : 0.10),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}
