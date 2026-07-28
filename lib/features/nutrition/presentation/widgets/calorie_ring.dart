import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../domain/nutrition_math.dart';

/// A circular calorie gauge: track + progress arc with the remaining kcal in
/// the centre. Turns amber→danger tinted when the target is exceeded.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.consumed,
    required this.target,
    this.size = 190,
  });

  final double consumed;
  final double target;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final fraction = progressFraction(consumed, target);
    final remaining = remainingKcal(consumed, target);
    final over = remaining < 0;
    final arcColor = over ? AppColors.warning : AppColors.accent;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: fraction,
          arcColor: arcColor,
          trackColor: glass.border,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                over ? 'превышено' : 'осталось',
                style: TextStyle(fontSize: 12, color: glass.textMid),
              ),
              const SizedBox(height: 2),
              Text(
                remaining.abs().round().toString(),
                style: AppTypography.numeric(glass.textHi, size: 40),
              ),
              Text(
                '${consumed.round()} / ${target.round()} ккал',
                style: TextStyle(fontSize: 12.5, color: glass.textMid),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.arcColor,
    required this.trackColor,
  });

  final double fraction;
  final Color arcColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = trackColor,
    );

    if (fraction <= 0) return;
    final sweep = 2 * math.pi * fraction;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: [arcColor.withValues(alpha: 0.55), arcColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.arcColor != arcColor;
}
