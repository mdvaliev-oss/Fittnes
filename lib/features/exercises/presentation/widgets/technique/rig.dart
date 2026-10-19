import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Geometry shared by the side- and front-view figure painters.
///
/// Everything lives in a 100×100 virtual space (origin top-left, ground at
/// y = [groundY]); painters scale it to the canvas. Limbs are solved with a
/// two-bone IK so a keyframe only states *where the hand / foot is* — the
/// elbow / knee follow, bending to the side [bend] picks.
abstract final class Rig {
  const Rig._();

  static const double groundY = 90;
  static const double torso = 22;
  static const double headGap = 12;
  static const double upperArm = 13;
  static const double foreArm = 12;
  static const double thigh = 18;
  static const double shin = 18;
  static const double foot = 9;

  /// Eases [t] with a short hold at both extremes so the rep reads as
  /// "move – pause – move" rather than a pendulum that never settles.
  static double ease(double t) {
    const hold = 0.09;
    final u = ((t - hold) / (1 - 2 * hold)).clamp(0.0, 1.0);
    return Curves.easeInOutSine.transform(u);
  }

  static double lerp(double a, double b, double t) => a + (b - a) * t;

  static Offset rotate(Offset v, double radians) => Offset(
        v.dx * math.cos(radians) - v.dy * math.sin(radians),
        v.dx * math.sin(radians) + v.dy * math.cos(radians),
      );

  /// Unit vector pointing "up the torso" for a lean of [deg] from vertical
  /// (+ = folding forward / towards +x, −90 = lying with the head at −x).
  static Offset torsoUp(double deg) {
    final r = deg * math.pi / 180;
    return Offset(math.sin(r), -math.cos(r));
  }

  /// Two-bone IK: joint between [root] and [target] for bone lengths [l1],
  /// [l2]. [bend] = +1 puts the joint on the right-hand side of the
  /// root→target direction (clockwise on screen), −1 on the left.
  static Offset solveJoint(
    Offset root,
    Offset target,
    double l1,
    double l2,
    double bend,
  ) {
    var delta = target - root;
    var d = delta.distance;
    if (d < 0.001) {
      delta = const Offset(0, 1);
      d = 0.001;
    }
    final reach = l1 + l2 - 0.01;
    if (d > reach) {
      delta = delta / d * reach;
      d = reach;
    }
    final cosA = ((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)).clamp(-1.0, 1.0);
    final a = math.acos(cosA);
    final dir = delta / d;
    return root + rotate(dir, bend.sign * a) * l1;
  }

  /// Point reached from [root] walking [l1] + [l2] towards [target] when the
  /// target is beyond reach (so a straight limb still ends on the line).
  static Offset clampReach(Offset root, Offset target, double reach) {
    final delta = target - root;
    final d = delta.distance;
    if (d <= reach || d == 0) return target;
    return root + delta / d * reach;
  }
}

/// What the figure stands / lies / hangs on — drawn behind it so the pose
/// is unambiguous (a bench under a press, a bar above a pull-up).
enum Fixture {
  ground,
  bench,
  inclineBench,
  seat,
  overheadBar,
  parallelBars,
  legPressSled,
  wheel,
  none,
}

/// Which body region to glow — the muscles the pattern is "about".
enum Emphasis { arms, legs, torso, shoulders, back, chest }

/// A side-view key pose. Arms are either IK-driven ([hand]) or FK-driven
/// ([shoulderAng] / [elbowAng]); legs are always IK-driven from [ankle].
class SidePose {
  const SidePose({
    this.hip = const Offset(50, 54),
    this.lean = 0,
    this.hand,
    this.shoulderAng = 6,
    this.elbowAng = 4,
    this.armBend = -1,
    this.ankle = const Offset(50, Rig.groundY),
    this.kneeBend = 1,
    this.farAnkle,
    this.farKneeBend,
    this.farHand,
    this.heelLift = 0,
    this.headTilt = 0,
  });

  final Offset hip;

  /// Torso lean from vertical, degrees (+ forward, −90 lying head to −x).
  final double lean;

  /// Hand target (IK). When null the FK angles are used instead.
  final Offset? hand;

  /// FK: upper-arm angle from "down along the torso" (+ = forward), and
  /// elbow flexion in degrees.
  final double shoulderAng;
  final double elbowAng;

  /// IK bend side for the elbow (see [Rig.solveJoint]).
  final double armBend;

  final Offset ankle;
  final double kneeBend;

  /// Far leg / hand when they differ from the near ones (lunges, carries).
  final Offset? farAnkle;
  final double? farKneeBend;
  final Offset? farHand;

  /// 0..1 heel raise (calf work) — draws the foot pivoting on its toe.
  final double heelLift;

  /// Head nod in degrees (+ = chin down).
  final double headTilt;

  static SidePose lerp(SidePose a, SidePose b, double t) => SidePose(
        hip: Offset.lerp(a.hip, b.hip, t)!,
        lean: Rig.lerp(a.lean, b.lean, t),
        hand: a.hand == null || b.hand == null
            ? null
            : Offset.lerp(a.hand, b.hand, t),
        shoulderAng: Rig.lerp(a.shoulderAng, b.shoulderAng, t),
        elbowAng: Rig.lerp(a.elbowAng, b.elbowAng, t),
        armBend: a.armBend,
        ankle: Offset.lerp(a.ankle, b.ankle, t)!,
        kneeBend: a.kneeBend,
        farAnkle: a.farAnkle == null || b.farAnkle == null
            ? null
            : Offset.lerp(a.farAnkle, b.farAnkle, t),
        farKneeBend: a.farKneeBend,
        farHand: a.farHand == null || b.farHand == null
            ? null
            : Offset.lerp(a.farHand, b.farHand, t),
        heelLift: Rig.lerp(a.heelLift, b.heelLift, t),
        headTilt: Rig.lerp(a.headTilt, b.headTilt, t),
      );
}

/// A front-view key pose (symmetric body, independent hands / feet).
class FrontPose {
  const FrontPose({
    this.shoulderY = 31,
    this.hipY = 54,
    this.shoulderHalf = 11,
    this.handL = const Offset(37, 56),
    this.handR = const Offset(63, 56),
    this.elbowOut = 1,
    this.ankleL = const Offset(40, Rig.groundY),
    this.ankleR = const Offset(60, Rig.groundY),
    this.kneeOut = 1,
    this.headY,
  });

  final double shoulderY;
  final double hipY;
  final double shoulderHalf;
  final Offset handL, handR;

  /// +1 bends elbows outwards (away from the midline), −1 inwards.
  final double elbowOut;
  final Offset ankleL, ankleR;
  final double kneeOut;

  /// Explicit head centre y; defaults to a fixed gap above the shoulders.
  final double? headY;

  static FrontPose lerp(FrontPose a, FrontPose b, double t) => FrontPose(
        shoulderY: Rig.lerp(a.shoulderY, b.shoulderY, t),
        hipY: Rig.lerp(a.hipY, b.hipY, t),
        shoulderHalf: Rig.lerp(a.shoulderHalf, b.shoulderHalf, t),
        handL: Offset.lerp(a.handL, b.handL, t)!,
        handR: Offset.lerp(a.handR, b.handR, t)!,
        elbowOut: a.elbowOut,
        ankleL: Offset.lerp(a.ankleL, b.ankleL, t)!,
        ankleR: Offset.lerp(a.ankleR, b.ankleR, t)!,
        kneeOut: a.kneeOut,
        headY: a.headY == null || b.headY == null
            ? null
            : Rig.lerp(a.headY!, b.headY!, t),
      );
}
