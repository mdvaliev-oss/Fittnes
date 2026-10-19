import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'rig.dart';

/// Strokes, glows and implements shared by both figure painters so the two
/// views look like the same avatar.
class FigureStyle {
  FigureStyle(this.scale, this.offset);

  /// Virtual → canvas.
  final double scale;
  final Offset offset;

  Offset m(Offset p) =>
      Offset(offset.dx + p.dx * scale, offset.dy + p.dy * scale);
  double s(double v) => v * scale;

  static const Color bar = Color(0xFFB8BAC6);

  // ── Body segments ────────────────────────────────────────────────────
  void limb(
    Canvas canvas,
    List<Offset> virtualPts, {
    double width = 6,
    bool near = true,
    bool glow = false,
    double glowAlpha = 0,
  }) {
    final pts = virtualPts.map(m).toList();
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (glow && glowAlpha > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.accent.withValues(alpha: glowAlpha)
          ..strokeWidth = s(width + 7)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: near ? 0.9 : 0.28)
        ..strokeWidth = s(near ? width : width - 0.5)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  void torso(
    Canvas canvas,
    Offset hip,
    Offset shoulder, {
    double glowAlpha = 0,
  }) {
    final a = m(hip);
    final b = m(shoulder);
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = (glowAlpha > 0 ? AppColors.accent : AppColors.primary)
            .withValues(alpha: 0.3 + glowAlpha * 0.4)
        ..strokeWidth = s(12)
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawLine(
      a,
      b,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryBright],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromPoints(a, b))
        ..strokeWidth = s(9)
        ..strokeCap = StrokeCap.round,
    );
  }

  void head(Canvas canvas, Offset centre) {
    final c = m(centre);
    canvas.drawCircle(c, s(7), Paint()..color = AppColors.primaryBright);
    canvas.drawCircle(
      c,
      s(7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s(1.2)
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  void handDot(Canvas canvas, Offset hand) =>
      canvas.drawCircle(m(hand), s(2.6), Paint()..color = AppColors.accent);

  // ── Guides & environment ─────────────────────────────────────────────
  void ground(Canvas canvas, Size size, double y) {
    final cy = m(Offset(0, y)).dy;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, cy, size.width, 1))
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width * 0.1, cy),
      Offset(size.width * 0.9, cy),
      paint,
    );
  }

  /// Dashed accent trace between the two extremes of the focus point.
  void motionGuide(Canvas canvas, Offset a, Offset b) {
    final p1 = m(a);
    final p2 = m(b);
    if ((p1 - p2).distance < s(3)) return;
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.35)
      ..strokeWidth = s(1.4)
      ..strokeCap = StrokeCap.round;
    const segments = 9;
    for (var i = 0; i < segments; i += 2) {
      canvas.drawLine(
        Offset.lerp(p1, p2, i / segments)!,
        Offset.lerp(p1, p2, (i + 1) / segments)!,
        paint,
      );
    }
    // Arrow head at the end of the concentric path.
    final dir = (p2 - p1) / (p2 - p1).distance;
    final n = Offset(-dir.dy, dir.dx);
    final tip = p2 + dir * s(2);
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        (tip - dir * s(4) + n * s(2.4)).dx,
        (tip - dir * s(4) + n * s(2.4)).dy,
      )
      ..lineTo(
        (tip - dir * s(4) - n * s(2.4)).dx,
        (tip - dir * s(4) - n * s(2.4)).dy,
      )
      ..close();
    canvas.drawPath(
      arrow,
      Paint()..color = AppColors.accent.withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      p1,
      s(1.8),
      Paint()..color = AppColors.accent.withValues(alpha: 0.5),
    );
  }

  void fixture(Canvas canvas, Size size, Fixture f, {Offset? anchor}) {
    final wood = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = s(3)
      ..strokeCap = StrokeCap.round;
    final frame = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = s(2)
      ..strokeCap = StrokeCap.round;
    switch (f) {
      case Fixture.ground:
        ground(canvas, size, Rig.groundY);
      case Fixture.bench:
        ground(canvas, size, Rig.groundY);
        final y = anchor?.dy ?? 62;
        final x0 = anchor == null ? 18.0 : anchor.dx - 10;
        canvas.drawLine(m(Offset(x0, y + 4)), m(Offset(x0 + 46, y + 4)), wood);
        for (final x in [x0 + 6, x0 + 40]) {
          canvas.drawLine(
            m(Offset(x, y + 5)),
            m(Offset(x, Rig.groundY)),
            frame,
          );
        }
      case Fixture.inclineBench:
        ground(canvas, size, Rig.groundY);
        canvas.drawLine(m(const Offset(26, 70)), m(const Offset(56, 70)), wood);
        canvas.drawLine(m(const Offset(26, 70)), m(const Offset(16, 40)), wood);
      case Fixture.seat:
        ground(canvas, size, Rig.groundY);
        canvas.drawLine(m(const Offset(34, 66)), m(const Offset(56, 66)), wood);
        canvas.drawLine(
          m(const Offset(36, 66)),
          m(const Offset(36, Rig.groundY)),
          frame,
        );
        canvas.drawLine(
          m(const Offset(54, 66)),
          m(const Offset(54, Rig.groundY)),
          frame,
        );
        canvas.drawLine(m(const Offset(34, 66)), m(const Offset(30, 40)), wood);
      case Fixture.overheadBar:
        canvas.drawLine(
          m(const Offset(18, 12)),
          m(const Offset(82, 12)),
          Paint()
            ..color = bar
            ..strokeWidth = s(2.6)
            ..strokeCap = StrokeCap.round,
        );
        for (final x in [20.0, 80.0]) {
          canvas.drawLine(m(Offset(x, 0)), m(Offset(x, 12)), frame);
        }
      case Fixture.parallelBars:
        for (final x in [40.0, 72.0]) {
          canvas.drawLine(m(Offset(x, 56)), m(Offset(x, Rig.groundY)), frame);
        }
        canvas.drawLine(
          m(const Offset(38, 56)),
          m(const Offset(74, 56)),
          Paint()
            ..color = bar
            ..strokeWidth = s(2.6)
            ..strokeCap = StrokeCap.round,
        );
        ground(canvas, size, Rig.groundY);
      case Fixture.legPressSled:
        ground(canvas, size, Rig.groundY);
        // Reclined seat + the foot plate the figure pushes.
        canvas.drawLine(m(const Offset(14, 42)), m(const Offset(36, 70)), wood);
        canvas.drawLine(m(const Offset(36, 70)), m(const Offset(46, 70)), wood);
        canvas.drawLine(
          m(const Offset(30, 70)),
          m(const Offset(30, Rig.groundY)),
          frame,
        );
        final plate = anchor ?? const Offset(66, 46);
        canvas.drawLine(
          m(plate + const Offset(4, -12)),
          m(plate + const Offset(4, 12)),
          Paint()
            ..color = AppColors.primaryBright.withValues(alpha: 0.8)
            ..strokeWidth = s(4)
            ..strokeCap = StrokeCap.round,
        );
      case Fixture.wheel:
        ground(canvas, size, Rig.groundY);
        final c = anchor ?? const Offset(64, 86);
        canvas.drawCircle(
          m(Offset(c.dx, Rig.groundY - 4)),
          s(4),
          Paint()
            ..color = AppColors.primaryBright
            ..style = PaintingStyle.stroke
            ..strokeWidth = s(2),
        );
      case Fixture.none:
        break;
    }
  }

  // ── Implements ───────────────────────────────────────────────────────
  /// Barbell seen along its axis (lying / overhead in profile): a plate disc.
  void barbellEndOn(Canvas canvas, Offset hand) {
    final c = m(hand);
    canvas.drawCircle(
      c,
      s(7),
      Paint()..color = AppColors.primaryBright.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      c,
      s(7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s(1)
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.drawCircle(c, s(1.8), Paint()..color = bar);
  }

  /// Barbell seen from the front: a long bar with plates at both ends.
  void barbellFront(Canvas canvas, Offset handL, Offset handR) {
    final y = (m(handL).dy + m(handR).dy) / 2;
    final x0 = m(const Offset(22, 0)).dx;
    final x1 = m(const Offset(78, 0)).dx;
    canvas.drawLine(
      Offset(x0, y),
      Offset(x1, y),
      Paint()
        ..color = bar
        ..strokeWidth = s(2.4)
        ..strokeCap = StrokeCap.round,
    );
    for (final x in [x0, x1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: s(4), height: s(12)),
          Radius.circular(s(2)),
        ),
        Paint()..color = AppColors.primaryBright,
      );
    }
  }

  void dumbbell(Canvas canvas, Offset hand, {bool vertical = false}) {
    final c = m(hand);
    final axis = vertical ? const Offset(0, 1) : const Offset(1, 0);
    canvas.drawLine(
      c - axis * s(5),
      c + axis * s(5),
      Paint()
        ..color = bar
        ..strokeWidth = s(2)
        ..strokeCap = StrokeCap.round,
    );
    for (final side in [-1.0, 1.0]) {
      final centre = c + axis * side * s(5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: centre,
            width: vertical ? s(7) : s(4),
            height: vertical ? s(4) : s(7),
          ),
          Radius.circular(s(1.5)),
        ),
        Paint()..color = AppColors.primaryBright,
      );
    }
  }

  void kettlebell(Canvas canvas, Offset hand) {
    final c = m(hand);
    canvas.drawCircle(
      c + Offset(0, s(5)),
      s(4.2),
      Paint()..color = AppColors.primaryBright,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c + Offset(0, s(1)), radius: s(3)),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = bar
        ..style = PaintingStyle.stroke
        ..strokeWidth = s(1.6),
    );
  }

  /// A cable from the hand to the edge of the frame in [direction].
  void cable(Canvas canvas, Size size, Offset hand, Offset direction) {
    final h = m(hand);
    final far = h + direction * (size.longestSide * 2);
    canvas.drawLine(
      h,
      far,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = s(1.4),
    );
    canvas.drawCircle(h, s(2.4), Paint()..color = bar);
  }
}
