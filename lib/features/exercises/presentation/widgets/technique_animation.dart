import 'package:flutter/material.dart';

import '../../domain/entities/exercise_enums.dart';
import '../../domain/entities/movement_pattern.dart';
import 'technique/front_figure_painter.dart';
import 'technique/keyframes.dart';
import 'technique/side_figure_painter.dart';

/// Vector coach avatar that performs one rep of [pattern], driven by
/// [progress] (0 = start pose, 1 = end pose). Picks the profile or the
/// front view per pattern, draws the bench / bar / sled the movement needs
/// and pulses an accent glow on the working muscles ([glow], 0..1).
class AnimatedTechniqueFigure extends StatelessWidget {
  const AnimatedTechniqueFigure({
    super.key,
    required this.progress,
    required this.pattern,
    required this.equipment,
    this.glow = 0,
  });

  final double progress;
  final MovementPattern pattern;
  final Equipment equipment;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final spec = PatternSpec.of(pattern);
    return CustomPaint(
      painter: spec.isFront
          ? FrontFigurePainter(
              t: progress,
              pattern: pattern,
              equipment: equipment,
              glow: glow,
            )
          : SideFigurePainter(
              t: progress,
              pattern: pattern,
              equipment: equipment,
              glow: glow,
            ),
      size: Size.infinite,
    );
  }
}
