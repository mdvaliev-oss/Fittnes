import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/entities/exercise_enums.dart';
import '../../../domain/entities/movement_pattern.dart';
import 'figure_style.dart';
import 'keyframes.dart';
import 'rig.dart';

/// Resolved side-view joints.
class _Joints {
  const _Joints({
    required this.hip,
    required this.shoulder,
    required this.head,
    required this.elbow,
    required this.hand,
    required this.knee,
    required this.ankle,
    required this.heel,
    required this.toe,
    required this.farElbow,
    required this.farHand,
    required this.farKnee,
    required this.farAnkle,
    required this.farHeel,
    required this.farToe,
  });

  final Offset hip, shoulder, head, elbow, hand, knee, ankle, heel, toe;
  final Offset farElbow, farHand, farKnee, farAnkle, farHeel, farToe;
}

/// Profile avatar performing one rep of [pattern]; [t] = 0 start pose,
/// 1 end pose. [glow] (0..1) drives the accent pulse on the working region.
class SideFigurePainter extends CustomPainter {
  SideFigurePainter({
    required this.t,
    required this.pattern,
    required this.equipment,
    required this.glow,
  });

  final double t;
  final MovementPattern pattern;
  final Equipment equipment;
  final double glow;

  PatternSpec get _spec => PatternSpec.of(pattern);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 100;
    final style = FigureStyle(
      scale,
      Offset(size.width / 2 - 50 * scale, 0),
    );
    final spec = _spec;
    final now =
        _resolve(SidePose.lerp(spec.sideStart!, spec.sideEnd!, Rig.ease(t)));
    final a = _resolve(spec.sideStart!);
    final b = _resolve(spec.sideEnd!);

    style.fixture(
      canvas,
      size,
      spec.fixture,
      anchor: _fixtureAnchor(spec, now),
    );
    style.motionGuide(
      canvas,
      spec.focusHand ? a.hand : a.hip,
      spec.focusHand ? b.hand : b.hip,
    );

    final e = spec.emphasis;
    final armGlow = e == Emphasis.arms || e == Emphasis.shoulders ? glow : 0.0;
    final legGlow = e == Emphasis.legs ? glow : 0.0;
    final torsoGlow =
        e == Emphasis.torso || e == Emphasis.back || e == Emphasis.chest
            ? glow
            : 0.0;

    // Far limbs first (depth), then torso, then near limbs + implement.
    style.limb(canvas, [now.shoulder, now.farElbow, now.farHand], near: false);
    style.limb(
      canvas,
      [now.hip, now.farKnee, now.farAnkle],
      width: 7,
      near: false,
    );
    style.limb(canvas, [now.farHeel, now.farToe], width: 4.5, near: false);

    style.torso(canvas, now.hip, now.shoulder, glowAlpha: torsoGlow * 0.55);
    style.head(canvas, now.head);

    style.limb(
      canvas,
      [now.hip, now.knee, now.ankle],
      width: 7,
      glow: true,
      glowAlpha: legGlow * 0.5,
    );
    style.limb(canvas, [now.heel, now.toe], width: 5);
    style.limb(
      canvas,
      [now.shoulder, now.elbow, now.hand],
      glow: true,
      glowAlpha: armGlow * 0.5,
    );
    style.handDot(canvas, now.hand);

    _implement(canvas, size, style, now);
  }

  Offset? _fixtureAnchor(PatternSpec spec, _Joints j) => switch (spec.fixture) {
        Fixture.bench => Offset(j.shoulder.dx, j.shoulder.dy),
        Fixture.legPressSled => j.ankle,
        Fixture.wheel => j.hand,
        _ => null,
      };

  // ── Geometry ─────────────────────────────────────────────────────────
  _Joints _resolve(SidePose p) {
    final up = Rig.torsoUp(p.lean);
    final shoulder = p.hip + up * Rig.torso;
    final tilt = Rig.rotate(up, p.headTilt * math.pi / 180);
    final head = shoulder + tilt * Rig.headGap;

    Offset hand;
    Offset elbow;
    if (p.hand != null) {
      hand = Rig.clampReach(
        shoulder,
        p.hand!,
        Rig.upperArm + Rig.foreArm,
      );
      elbow = Rig.solveJoint(
        shoulder,
        hand,
        Rig.upperArm,
        Rig.foreArm,
        p.armBend,
      );
    } else {
      final down = -up;
      final ua = Rig.rotate(down, -p.shoulderAng * math.pi / 180);
      elbow = shoulder + ua * Rig.upperArm;
      final fa = Rig.rotate(ua, -p.elbowAng * math.pi / 180);
      hand = elbow + fa * Rig.foreArm;
    }

    Offset farHand;
    Offset farElbow;
    if (p.farHand != null) {
      farHand = Rig.clampReach(
        shoulder,
        p.farHand!,
        Rig.upperArm + Rig.foreArm,
      );
      farElbow = Rig.solveJoint(
        shoulder,
        farHand,
        Rig.upperArm,
        Rig.foreArm,
        p.armBend,
      );
    } else {
      const depth = Offset(-2.4, 0.4);
      farHand = hand + depth;
      farElbow = elbow + depth;
    }

    final ankle = Rig.clampReach(p.hip, p.ankle, Rig.thigh + Rig.shin);
    final knee = Rig.solveJoint(p.hip, ankle, Rig.thigh, Rig.shin, p.kneeBend);
    final (heel, toe) = _foot(knee, ankle, p.heelLift);

    Offset farAnkle;
    Offset farKnee;
    if (p.farAnkle != null) {
      farAnkle = Rig.clampReach(p.hip, p.farAnkle!, Rig.thigh + Rig.shin);
      farKnee = Rig.solveJoint(
        p.hip,
        farAnkle,
        Rig.thigh,
        Rig.shin,
        p.farKneeBend ?? p.kneeBend,
      );
    } else {
      const depth = Offset(-2.8, 0.4);
      farAnkle = ankle + depth;
      farKnee = knee + depth;
    }
    final (farHeel, farToe) = _foot(farKnee, farAnkle, p.heelLift);

    return _Joints(
      hip: p.hip,
      shoulder: shoulder,
      head: head,
      elbow: elbow,
      hand: hand,
      knee: knee,
      ankle: ankle,
      heel: heel,
      toe: toe,
      farElbow: farElbow,
      farHand: farHand,
      farKnee: farKnee,
      farAnkle: farAnkle,
      farHeel: farHeel,
      farToe: farToe,
    );
  }

  /// Foot perpendicular to the shin, toes forward; a heel lift pivots the
  /// foot on its toe so the ankle rises while the toe stays grounded.
  (Offset, Offset) _foot(Offset knee, Offset ankle, double heelLift) {
    var shin = ankle - knee;
    if (shin.distance < 0.01) shin = const Offset(0, 1);
    shin = shin / shin.distance;
    var fwd = Rig.rotate(shin, -math.pi / 2);
    if (fwd.dx < 0) fwd = -fwd; // toes always point to +x in profile
    if (heelLift > 0) {
      fwd = Rig.rotate(fwd, heelLift * 0.55);
    }
    return (ankle - fwd * 4, ankle + fwd * Rig.foot);
  }

  // ── Implements ───────────────────────────────────────────────────────
  void _implement(Canvas canvas, Size size, FigureStyle style, _Joints j) {
    final lying =
        _spec.fixture == Fixture.bench && pattern != MovementPattern.legCurl;
    switch (equipment) {
      case Equipment.barbell:
      case Equipment.smithMachine:
      case Equipment.ezBar:
        if (pattern == MovementPattern.wristCurl) {
          style.dumbbell(canvas, j.hand, vertical: true);
        } else if (lying ||
            pattern == MovementPattern.verticalPress ||
            pattern == MovementPattern.hinge ||
            pattern == MovementPattern.horizontalPull ||
            pattern == MovementPattern.hipThrust ||
            pattern == MovementPattern.rollout) {
          style.barbellEndOn(canvas, j.hand);
        } else {
          style.barbellEndOn(canvas, j.hand);
        }
      case Equipment.dumbbell:
        final vertical = pattern == MovementPattern.horizontalPress ||
            pattern == MovementPattern.verticalPress ||
            pattern == MovementPattern.carry ||
            pattern == MovementPattern.pullover;
        style.dumbbell(canvas, j.hand, vertical: vertical);
        if (pattern == MovementPattern.carry) {
          style.dumbbell(canvas, j.farHand, vertical: true);
        }
      case Equipment.kettlebell:
        style.kettlebell(canvas, j.hand);
      case Equipment.cable:
        final dir = switch (pattern) {
          MovementPattern.tricepsExtension ||
          MovementPattern.crunch ||
          MovementPattern.pullover =>
            const Offset(0.35, -1),
          MovementPattern.curl ||
          MovementPattern.hinge ||
          MovementPattern.hipThrust =>
            const Offset(0.4, 1),
          _ => const Offset(1, 0),
        };
        style.cable(canvas, size, j.hand, dir / dir.distance);
      case Equipment.bands:
        style.cable(canvas, size, j.hand, const Offset(0, 1));
      case Equipment.machine:
      case Equipment.bodyweight:
      case Equipment.other:
        break;
    }
  }

  @override
  bool shouldRepaint(SideFigurePainter old) =>
      old.t != t ||
      old.pattern != pattern ||
      old.equipment != equipment ||
      old.glow != glow;
}
