import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/exercise_enums.dart';
import '../../domain/entities/muscle.dart';

/// A recognizable movement pattern the [AnimatedTechniqueFigure] can act out.
///
/// Picked from an exercise's name, force vector and target muscles so the
/// placeholder shows the *actual* motion (a squat looks like a squat) instead
/// of an abstract marker travelling a line.
enum MovementPattern {
  squat,
  hinge,
  horizontalPress,
  verticalPress,
  horizontalPull,
  verticalPull,
  curl,
  tricepsExtension,
  lateralRaise,
  calfRaise,
  crunch,
  generic;

  /// Best-effort classification. Keyword match (RU + EN) first, then a
  /// fallback by [ForceType] + primary [Muscle]s.
  static MovementPattern forExercise(Exercise e) {
    final hay = '${e.name} ${e.altName ?? ''} ${e.id}'.toLowerCase();

    bool has(List<String> keys) => keys.any(hay.contains);

    if (has([
      'присед',
      'squat',
      'goblet',
      'выпад',
      'lunge',
      'жим ног',
      'leg press',
      'hack',
      'гакк',
    ])) {
      return MovementPattern.squat;
    }
    if (has([
      'становая',
      'deadlift',
      'румын',
      'rdl',
      'hinge',
      'good morning',
      'наклон',
      'гиперэкстен',
      'hyperextension',
      'back extension',
    ])) {
      return MovementPattern.hinge;
    }
    if (has(['подъём на носк', 'подъем на носк', 'носки', 'calf', 'икр'])) {
      return MovementPattern.calfRaise;
    }
    if (has([
      'подтяг',
      'pull-up',
      'pullup',
      'pull up',
      'верхнего блока',
      'pulldown',
      'lat pulldown',
      'широчайш',
    ])) {
      return MovementPattern.verticalPull;
    }
    if (has(['тяга', 'row', 'face pull', 'к поясу', 'к животу'])) {
      return MovementPattern.horizontalPull;
    }
    if (has([
      'french',
      'французс',
      'pushdown',
      'на трицепс',
      'разгибание рук',
      'triceps extension',
      'разгибания на трицепс',
    ])) {
      return MovementPattern.tricepsExtension;
    }
    if (has(['curl', 'сгибан', 'на бицепс', 'бицепс'])) {
      return MovementPattern.curl;
    }
    if (has([
      'махи',
      'lateral',
      'разведен',
      'raise',
      'в стороны',
      'подъёмы перед',
      'front raise',
    ])) {
      return MovementPattern.lateralRaise;
    }
    if (has([
      'над головой',
      'overhead',
      'military',
      'жим стоя',
      'жим сидя',
      'shoulder press',
      'arnold',
      'арнольд',
      'швунг',
    ])) {
      return MovementPattern.verticalPress;
    }
    if (has([
      'жим лёжа',
      'жим лежа',
      'bench',
      'отжим',
      'push-up',
      'push up',
      'chest press',
      'сведение',
      'fly',
      'dip',
      'брусь',
    ])) {
      return MovementPattern.horizontalPress;
    }
    if (has([
      'скручиван',
      'crunch',
      'sit-up',
      'пресс',
      'планка',
      'plank',
      'подъём ног',
      'core',
    ])) {
      return MovementPattern.crunch;
    }

    // Fallback: infer from anatomy + force.
    final primary = e.primaryMuscles.toSet();
    if (primary.contains(Muscle.calves)) return MovementPattern.calfRaise;
    if (primary.contains(Muscle.quads) || primary.contains(Muscle.glutes)) {
      return e.force == ForceType.pull
          ? MovementPattern.hinge
          : MovementPattern.squat;
    }
    if (primary.contains(Muscle.hamstrings) ||
        primary.contains(Muscle.lowerBack)) {
      return MovementPattern.hinge;
    }
    if (primary.contains(Muscle.chest)) return MovementPattern.horizontalPress;
    if (primary.contains(Muscle.lats) || primary.contains(Muscle.traps)) {
      return MovementPattern.horizontalPull;
    }
    if (primary.contains(Muscle.frontDelts) ||
        primary.contains(Muscle.sideDelts)) {
      return primary.contains(Muscle.sideDelts)
          ? MovementPattern.lateralRaise
          : MovementPattern.verticalPress;
    }
    if (primary.contains(Muscle.biceps)) return MovementPattern.curl;
    if (primary.contains(Muscle.triceps)) {
      return MovementPattern.tricepsExtension;
    }
    if (primary.contains(Muscle.abs) || primary.contains(Muscle.obliques)) {
      return MovementPattern.crunch;
    }
    return switch (e.force) {
      ForceType.push => MovementPattern.horizontalPress,
      ForceType.pull => MovementPattern.horizontalPull,
      _ => MovementPattern.generic,
    };
  }
}

/// Draws a side-profile coach avatar that performs one rep of [pattern],
/// driven by [progress] (0 = start pose, 1 = end pose). Holds the appropriate
/// implement for [equipment] and traces the bar/hand path so the motion reads
/// at a glance — a real technique preview, fully vector and offline.
class AnimatedTechniqueFigure extends StatelessWidget {
  const AnimatedTechniqueFigure({
    super.key,
    required this.progress,
    required this.pattern,
    required this.equipment,
  });

  final double progress;
  final MovementPattern pattern;
  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FigurePainter(
        t: progress,
        pattern: pattern,
        equipment: equipment,
      ),
      size: Size.infinite,
    );
  }
}

/// Skeleton parameters in a 100×100 virtual space (origin top-left, figure
/// facing +x). Arms are resolved by forward kinematics from joint angles;
/// legs from explicit knee/hip so squats and hinges stay controllable.
class _Params {
  const _Params({
    this.hipX = 50,
    this.hipY = 54,
    this.lean = 0,
    this.shoulderAng = 12,
    this.elbowAng = 8,
    this.kneeX = 50,
    this.kneeY = 72,
    this.ankleX = 50,
    this.heelLift = 0,
  });

  /// Pelvis position.
  final double hipX, hipY;

  /// Torso lean from vertical, degrees (+ = fold forward).
  final double lean;

  /// Upper-arm angle from straight-down, degrees (0 down, 90 forward, 180 up).
  final double shoulderAng;

  /// Elbow flexion, degrees (0 = straight).
  final double elbowAng;

  final double kneeX, kneeY, ankleX;

  /// 0..1 heel raise for calf work.
  final double heelLift;

  static _Params lerp(_Params a, _Params b, double t) => _Params(
        hipX: _l(a.hipX, b.hipX, t),
        hipY: _l(a.hipY, b.hipY, t),
        lean: _l(a.lean, b.lean, t),
        shoulderAng: _l(a.shoulderAng, b.shoulderAng, t),
        elbowAng: _l(a.elbowAng, b.elbowAng, t),
        kneeX: _l(a.kneeX, b.kneeX, t),
        kneeY: _l(a.kneeY, b.kneeY, t),
        ankleX: _l(a.ankleX, b.ankleX, t),
        heelLift: _l(a.heelLift, b.heelLift, t),
      );

  static double _l(double a, double b, double t) => a + (b - a) * t;
}

/// Resolved joint positions in virtual space.
class _Pose {
  const _Pose({
    required this.hip,
    required this.shoulder,
    required this.head,
    required this.elbow,
    required this.hand,
    required this.knee,
    required this.ankle,
    required this.toe,
    required this.heel,
  });

  final Offset hip, shoulder, head, elbow, hand, knee, ankle, toe, heel;
}

class _FigurePainter extends CustomPainter {
  _FigurePainter({
    required this.t,
    required this.pattern,
    required this.equipment,
  });

  final double t;
  final MovementPattern pattern;
  final Equipment equipment;

  static const double _groundY = 90;
  static const double _torsoLen = 22;
  static const double _headGap = 12;
  static const double _upperArm = 13;
  static const double _foreArm = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final pose = _resolve(_paramsAt(t));
    final poseStart = _resolve(_paramsAt(0));
    final poseEnd = _resolve(_paramsAt(1));

    // Virtual → canvas transform: fit the 100-tall figure, center horizontally.
    final scale = size.height / 100;
    final dx = size.width / 2 - 50 * scale;
    Offset m(Offset p) => Offset(dx + p.dx * scale, p.dy * scale);
    double s(double v) => v * scale;

    _drawGround(canvas, size, m, s);
    _drawMotionGuide(canvas, poseStart, poseEnd, m, s);

    // Far-side limbs (depth) — dimmer and slightly offset.
    const depth = Offset(-3.2, 0.6);
    _drawArm(canvas, pose, m, s, depth: depth, near: false);
    _drawLeg(canvas, pose, m, s, depth: depth, near: false);

    _drawTorsoHead(canvas, pose, m, s);

    // Near-side limbs.
    _drawLeg(canvas, pose, m, s, depth: Offset.zero, near: true);
    _drawArm(canvas, pose, m, s, depth: Offset.zero, near: true);

    _drawImplement(canvas, pose, m, s);
  }

  // ── Geometry ────────────────────────────────────────────────────────
  _Params _paramsAt(double tt) {
    final (start, end) = _keyframes(pattern);
    return _Params.lerp(start, end, Curves.easeInOut.transform(tt));
  }

  _Pose _resolve(_Params p) {
    final hip = Offset(p.hipX, p.hipY);
    final rad = p.lean * math.pi / 180;
    final up = Offset(math.sin(rad), -math.cos(rad)); // torso direction
    final shoulder = hip + up * _torsoLen;
    final head = shoulder + up * _headGap;

    final saRad = p.shoulderAng * math.pi / 180;
    final ua = Offset(math.sin(saRad), math.cos(saRad));
    final elbow = shoulder + ua * _upperArm;
    final fa = _rotate(ua, -p.elbowAng * math.pi / 180);
    final hand = elbow + fa * _foreArm;

    final ankle = Offset(p.ankleX, _groundY - p.heelLift * 5);
    final toe = Offset(p.ankleX + 9, _groundY);
    final heel = Offset(p.ankleX - 5, _groundY - p.heelLift * 5);
    final knee = Offset(p.kneeX, p.kneeY);
    return _Pose(
      hip: hip,
      shoulder: shoulder,
      head: head,
      elbow: elbow,
      hand: hand,
      knee: knee,
      ankle: ankle,
      toe: toe,
      heel: heel,
    );
  }

  static Offset _rotate(Offset v, double a) => Offset(
        v.dx * math.cos(a) - v.dy * math.sin(a),
        v.dx * math.sin(a) + v.dy * math.cos(a),
      );

  /// (start, end) key poses per pattern. t=0 is the start of the rep.
  (_Params, _Params) _keyframes(MovementPattern p) => switch (p) {
        MovementPattern.squat => (
            const _Params(hipY: 52, lean: 8, shoulderAng: 55, elbowAng: 80),
            const _Params(
              hipY: 70,
              lean: 26,
              shoulderAng: 62,
              elbowAng: 88,
              kneeX: 58,
              kneeY: 80,
            ),
          ),
        MovementPattern.hinge => (
            const _Params(hipY: 52, lean: 4, shoulderAng: 6, elbowAng: 4),
            const _Params(
              hipX: 44,
              hipY: 58,
              lean: 56,
              shoulderAng: 6,
              elbowAng: 4,
              kneeX: 53,
              kneeY: 74,
            ),
          ),
        MovementPattern.horizontalPress => (
            const _Params(shoulderAng: 90, elbowAng: 6),
            const _Params(shoulderAng: 78, elbowAng: 78),
          ),
        MovementPattern.verticalPress => (
            const _Params(shoulderAng: 168, elbowAng: 8),
            const _Params(shoulderAng: 120, elbowAng: 92),
          ),
        MovementPattern.horizontalPull => (
            const _Params(lean: 34, shoulderAng: 58, elbowAng: 10, kneeY: 74),
            const _Params(lean: 34, shoulderAng: 30, elbowAng: 96, kneeY: 74),
          ),
        MovementPattern.verticalPull => (
            const _Params(shoulderAng: 164, elbowAng: 10),
            const _Params(shoulderAng: 122, elbowAng: 104),
          ),
        MovementPattern.curl => (
            const _Params(shoulderAng: 16, elbowAng: 10),
            const _Params(shoulderAng: 22, elbowAng: 132),
          ),
        MovementPattern.tricepsExtension => (
            const _Params(shoulderAng: 16, elbowAng: 122),
            const _Params(shoulderAng: 16, elbowAng: 10),
          ),
        MovementPattern.lateralRaise => (
            const _Params(shoulderAng: 10, elbowAng: 16),
            const _Params(shoulderAng: 92, elbowAng: 16),
          ),
        MovementPattern.calfRaise => (
            const _Params(shoulderAng: 8, elbowAng: 6),
            const _Params(
              hipY: 49,
              kneeY: 69,
              shoulderAng: 8,
              elbowAng: 6,
              heelLift: 1,
            ),
          ),
        MovementPattern.crunch => (
            const _Params(lean: 4, shoulderAng: 150, elbowAng: 120),
            const _Params(lean: 42, shoulderAng: 150, elbowAng: 120),
          ),
        MovementPattern.generic => (
            const _Params(hipY: 52, shoulderAng: 28, elbowAng: 36),
            const _Params(hipY: 57, shoulderAng: 34, elbowAng: 48),
          ),
      };

  // ── Drawing ─────────────────────────────────────────────────────────
  void _drawGround(
    Canvas canvas,
    Size size,
    Offset Function(Offset) m,
    double Function(double) s,
  ) {
    final y = m(const Offset(0, _groundY + 1)).dy;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, y, size.width, 1))
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width * 0.12, y),
      Offset(size.width * 0.88, y),
      paint,
    );
  }

  /// Translucent trace of the hand path between the two rep extremes.
  void _drawMotionGuide(
    Canvas canvas,
    _Pose a,
    _Pose b,
    Offset Function(Offset) m,
    double Function(double) s,
  ) {
    final p1 = m(a.hand);
    final p2 = m(b.hand);
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.35)
      ..strokeWidth = s(1.4)
      ..strokeCap = StrokeCap.round;

    // Dashed line between extremes.
    const segments = 7;
    for (var i = 0; i < segments; i += 2) {
      final t0 = i / segments;
      final t1 = (i + 1) / segments;
      canvas.drawLine(
        Offset.lerp(p1, p2, t0)!,
        Offset.lerp(p1, p2, t1)!,
        paint,
      );
    }
    // Endpoint ticks.
    final dot = Paint()..color = AppColors.accent.withValues(alpha: 0.5);
    canvas.drawCircle(p1, s(1.8), dot);
    canvas.drawCircle(p2, s(1.8), dot);
  }

  void _drawTorsoHead(
    Canvas canvas,
    _Pose pose,
    Offset Function(Offset) m,
    double Function(double) s,
  ) {
    final glow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..strokeWidth = s(11)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(m(pose.hip), m(pose.shoulder), glow);

    final torso = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryBright],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromPoints(m(pose.hip), m(pose.shoulder)))
      ..strokeWidth = s(9)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(m(pose.hip), m(pose.shoulder), torso);

    // Head.
    final c = m(pose.head);
    canvas.drawCircle(
      c,
      s(7),
      Paint()..color = AppColors.primaryBright,
    );
    canvas.drawCircle(
      c,
      s(7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s(1.2)
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  void _drawArm(
    Canvas canvas,
    _Pose pose,
    Offset Function(Offset) m,
    double Function(double) s, {
    required Offset depth,
    required bool near,
  }) {
    final color = near
        ? Colors.white.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.28);
    final paint = Paint()
      ..color = color
      ..strokeWidth = s(near ? 6 : 5.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(m(pose.shoulder + depth).dx, m(pose.shoulder + depth).dy)
      ..lineTo(m(pose.elbow + depth).dx, m(pose.elbow + depth).dy)
      ..lineTo(m(pose.hand + depth).dx, m(pose.hand + depth).dy);
    canvas.drawPath(path, paint);

    if (near) {
      canvas.drawCircle(
        m(pose.hand),
        s(2.6),
        Paint()..color = AppColors.accent,
      );
    }
  }

  void _drawLeg(
    Canvas canvas,
    _Pose pose,
    Offset Function(Offset) m,
    double Function(double) s, {
    required Offset depth,
    required bool near,
  }) {
    final color = near
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.26);
    final paint = Paint()
      ..color = color
      ..strokeWidth = s(near ? 7 : 6.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(m(pose.hip + depth).dx, m(pose.hip + depth).dy)
      ..lineTo(m(pose.knee + depth).dx, m(pose.knee + depth).dy)
      ..lineTo(m(pose.ankle + depth).dx, m(pose.ankle + depth).dy);
    canvas.drawPath(path, paint);

    // Foot.
    canvas.drawLine(
      m(pose.heel + depth),
      m(pose.toe + depth),
      paint..strokeWidth = s(near ? 5 : 4.5),
    );
  }

  void _drawImplement(
    Canvas canvas,
    _Pose pose,
    Offset Function(Offset) m,
    double Function(double) s,
  ) {
    final hand = m(pose.hand);
    switch (equipment) {
      case Equipment.barbell:
      case Equipment.smithMachine:
      case Equipment.ezBar:
        _drawBarbell(canvas, hand, s);
      case Equipment.dumbbell:
      case Equipment.kettlebell:
        _drawDumbbell(canvas, hand, s);
      case Equipment.cable:
        _drawCable(canvas, pose, m, s);
      case Equipment.machine:
      case Equipment.bands:
      case Equipment.bodyweight:
      case Equipment.other:
        break; // bodyweight — no implement
    }
  }

  void _drawBarbell(Canvas canvas, Offset hand, double Function(double) s) {
    final barPaint = Paint()
      ..color = const Color(0xFFB8BAC6)
      ..strokeWidth = s(2.4)
      ..strokeCap = StrokeCap.round;
    final half = s(17);
    canvas.drawLine(
      Offset(hand.dx - half, hand.dy),
      Offset(hand.dx + half, hand.dy),
      barPaint,
    );
    final plate = Paint()..color = AppColors.primaryBright;
    for (final side in [-1.0, 1.0]) {
      final cx = hand.dx + side * half;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, hand.dy),
            width: s(4),
            height: s(11),
          ),
          Radius.circular(s(2)),
        ),
        plate,
      );
    }
  }

  void _drawDumbbell(Canvas canvas, Offset hand, double Function(double) s) {
    final bar = Paint()
      ..color = const Color(0xFFB8BAC6)
      ..strokeWidth = s(2)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(hand.dx, hand.dy - s(5)),
      Offset(hand.dx, hand.dy + s(5)),
      bar,
    );
    final bell = Paint()..color = AppColors.primaryBright;
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(hand.dx, hand.dy + side * s(5)),
            width: s(7),
            height: s(4),
          ),
          Radius.circular(s(1.5)),
        ),
        bell,
      );
    }
  }

  void _drawCable(
    Canvas canvas,
    _Pose pose,
    Offset Function(Offset) m,
    double Function(double) s,
  ) {
    // A cable running from the hand straight up to an off-screen pulley.
    final hand = m(pose.hand);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = s(1.4);
    canvas.drawLine(hand, Offset(hand.dx, 0), paint);
    canvas.drawCircle(hand, s(2.4), Paint()..color = const Color(0xFFB8BAC6));
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.t != t || old.pattern != pattern || old.equipment != equipment;
}
