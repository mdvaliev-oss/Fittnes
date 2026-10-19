import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/exercise_enums.dart';
import '../../../domain/entities/movement_pattern.dart';
import 'figure_style.dart';
import 'keyframes.dart';
import 'rig.dart';

class _Joints {
  const _Joints({
    required this.head,
    required this.neck,
    required this.shoulderL,
    required this.shoulderR,
    required this.hipL,
    required this.hipR,
    required this.hipC,
    required this.elbowL,
    required this.elbowR,
    required this.handL,
    required this.handR,
    required this.kneeL,
    required this.kneeR,
    required this.ankleL,
    required this.ankleR,
  });

  final Offset head, neck, shoulderL, shoulderR, hipL, hipR, hipC;
  final Offset elbowL, elbowR, handL, handR, kneeL, kneeR, ankleL, ankleR;
}

/// Symmetric front-facing avatar for patterns that read best head-on
/// (squat, lateral raise, pull-up, shrug …).
class FrontFigurePainter extends CustomPainter {
  FrontFigurePainter({
    required this.t,
    required this.pattern,
    required this.equipment,
    required this.glow,
  });

  final double t;
  final MovementPattern pattern;
  final Equipment equipment;
  final double glow;

  static const double _hipHalf = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 100;
    final style = FigureStyle(
      scale,
      Offset(size.width / 2 - 50 * scale, 0),
    );
    final spec = PatternSpec.of(pattern);
    final now = _resolve(
      FrontPose.lerp(spec.frontStart!, spec.frontEnd!, Rig.ease(t)),
    );
    final a = _resolve(spec.frontStart!);
    final b = _resolve(spec.frontEnd!);

    style.fixture(canvas, size, spec.fixture);
    style.motionGuide(
      canvas,
      spec.focusHand ? a.handR : a.hipC,
      spec.focusHand ? b.handR : b.hipC,
    );

    final e = spec.emphasis;
    final armGlow = e == Emphasis.arms || e == Emphasis.shoulders ? glow : 0.0;
    final legGlow = e == Emphasis.legs ? glow : 0.0;
    final torsoGlow =
        e == Emphasis.torso || e == Emphasis.back || e == Emphasis.chest
            ? glow
            : 0.0;

    // Legs behind the torso.
    for (final leg in [
      [now.hipL, now.kneeL, now.ankleL],
      [now.hipR, now.kneeR, now.ankleR],
    ]) {
      style.limb(canvas, leg, width: 7, glow: true, glowAlpha: legGlow * 0.5);
      final ankle = leg.last;
      style.limb(
        canvas,
        [ankle + const Offset(-3, 0), ankle + const Offset(4, 0)],
        width: 5,
      );
    }

    _torso(canvas, style, now, torsoGlow);
    style.head(canvas, now.head);

    for (final arm in [
      [now.shoulderL, now.elbowL, now.handL],
      [now.shoulderR, now.elbowR, now.handR],
    ]) {
      style.limb(canvas, arm, glow: true, glowAlpha: armGlow * 0.5);
    }
    style.handDot(canvas, now.handL);
    style.handDot(canvas, now.handR);

    _implement(canvas, size, style, now);
  }

  _Joints _resolve(FrontPose p) {
    final shoulderL = Offset(50 - p.shoulderHalf, p.shoulderY);
    final shoulderR = Offset(50 + p.shoulderHalf, p.shoulderY);
    final neck = Offset(50, p.shoulderY - 1);
    final head = Offset(50, p.headY ?? p.shoulderY - 13);
    final hipL = Offset(50 - _hipHalf, p.hipY);
    final hipR = Offset(50 + _hipHalf, p.hipY);

    const reachArm = Rig.upperArm + Rig.foreArm;
    final handL = Rig.clampReach(shoulderL, p.handL, reachArm);
    final handR = Rig.clampReach(shoulderR, p.handR, reachArm);
    // Mirror the bend so both elbows go outwards (or inwards) symmetrically.
    final elbowL = Rig.solveJoint(
      shoulderL,
      handL,
      Rig.upperArm,
      Rig.foreArm,
      -p.elbowOut,
    );
    final elbowR = Rig.solveJoint(
      shoulderR,
      handR,
      Rig.upperArm,
      Rig.foreArm,
      p.elbowOut,
    );

    const reachLeg = Rig.thigh + Rig.shin;
    final ankleL = Rig.clampReach(hipL, p.ankleL, reachLeg);
    final ankleR = Rig.clampReach(hipR, p.ankleR, reachLeg);
    // Standing legs point down, so a clockwise bend is *inward* for the
    // right leg — mirror the sign relative to the elbows.
    final kneeL = Rig.solveJoint(hipL, ankleL, Rig.thigh, Rig.shin, p.kneeOut);
    final kneeR = Rig.solveJoint(hipR, ankleR, Rig.thigh, Rig.shin, -p.kneeOut);

    return _Joints(
      head: head,
      neck: neck,
      shoulderL: shoulderL,
      shoulderR: shoulderR,
      hipL: hipL,
      hipR: hipR,
      hipC: Offset(50, p.hipY),
      elbowL: elbowL,
      elbowR: elbowR,
      handL: handL,
      handR: handR,
      kneeL: kneeL,
      kneeR: kneeR,
      ankleL: ankleL,
      ankleR: ankleR,
    );
  }

  void _torso(Canvas canvas, FigureStyle style, _Joints j, double glowAlpha) {
    final path = Path()
      ..moveTo(style.m(j.shoulderL).dx, style.m(j.shoulderL).dy)
      ..lineTo(style.m(j.shoulderR).dx, style.m(j.shoulderR).dy)
      ..lineTo(style.m(j.hipR).dx, style.m(j.hipR).dy)
      ..lineTo(style.m(j.hipL).dx, style.m(j.hipL).dy)
      ..close();
    final rect = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..color = (glowAlpha > 0 ? AppColors.accent : AppColors.primary)
            .withValues(alpha: 0.25 + glowAlpha * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryBright],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(rect),
    );
    canvas.drawLine(
      style.m(j.neck),
      style.m(j.head),
      Paint()
        ..color = AppColors.primaryBright
        ..strokeWidth = style.s(5)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _implement(Canvas canvas, Size size, FigureStyle style, _Joints j) {
    final barbell = equipment == Equipment.barbell ||
        equipment == Equipment.smithMachine ||
        equipment == Equipment.ezBar;
    final dumbbell =
        equipment == Equipment.dumbbell || equipment == Equipment.kettlebell;

    switch (pattern) {
      case MovementPattern.squat:
        if (barbell) {
          style.barbellFront(canvas, j.handL, j.handR);
        } else if (dumbbell) {
          style.dumbbell(
            canvas,
            Offset((j.handL.dx + j.handR.dx) / 2, j.handL.dy + 2),
            vertical: true,
          );
        }
      case MovementPattern.verticalPull:
        if (equipment == Equipment.cable) {
          for (final h in [j.handL, j.handR]) {
            style.cable(canvas, size, h, const Offset(0, -1));
          }
        }
      case MovementPattern.shrug || MovementPattern.uprightRow:
        if (barbell) {
          style.barbellFront(canvas, j.handL, j.handR);
        } else if (dumbbell) {
          style.dumbbell(canvas, j.handL);
          style.dumbbell(canvas, j.handR);
        }
      case MovementPattern.lateralRaise || MovementPattern.fly:
        if (dumbbell) {
          style.dumbbell(canvas, j.handL);
          style.dumbbell(canvas, j.handR);
        } else if (equipment == Equipment.cable ||
            equipment == Equipment.bands) {
          final dir = pattern == MovementPattern.fly
              ? const Offset(1, 0)
              : const Offset(0, 1);
          style.cable(canvas, size, j.handL, -dir);
          style.cable(canvas, size, j.handR, dir);
        }
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(FrontFigurePainter old) =>
      old.t != t ||
      old.pattern != pattern ||
      old.equipment != equipment ||
      old.glow != glow;
}
