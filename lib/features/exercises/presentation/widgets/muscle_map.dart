import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/muscle.dart';

/// Renders a front + back body, coloring each supplied muscle.
///
/// Geometry is shared: [MuscleMap] colors by [MuscleActivation] (exercise
/// detail) while recovery/heat views pass an explicit `muscleColors` map.
class MuscleBodyMap extends StatelessWidget {
  const MuscleBodyMap({super.key, required this.muscleColors});

  final Map<Muscle, Color> muscleColors;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final silhouette =
        isDark ? const Color(0xFF23232E) : const Color(0xFFDFDFE7);
    final outline = isDark ? const Color(0xFF33333F) : const Color(0xFFC4C4CE);

    return Row(
      children: [
        Expanded(
          child: _Figure(
            side: BodySide.front,
            label: 'Спереди',
            colors: muscleColors,
            silhouette: silhouette,
            outline: outline,
          ),
        ),
        Expanded(
          child: _Figure(
            side: BodySide.back,
            label: 'Сзади',
            colors: muscleColors,
            silhouette: silhouette,
            outline: outline,
          ),
        ),
      ],
    );
  }
}

/// Body map highlighting muscles by their activation level for an exercise.
class MuscleMap extends StatelessWidget {
  const MuscleMap({super.key, required this.activation});

  final Map<Muscle, MuscleActivation> activation;

  static Color colorFor(MuscleActivation level) => switch (level) {
        MuscleActivation.primary =>
          AppColors.primaryBright.withValues(alpha: 0.95),
        MuscleActivation.secondary => AppColors.primary.withValues(alpha: 0.5),
        MuscleActivation.stabilizer => AppColors.accent.withValues(alpha: 0.45),
      };

  @override
  Widget build(BuildContext context) {
    return MuscleBodyMap(
      muscleColors: {
        for (final e in activation.entries) e.key: colorFor(e.value),
      },
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.side,
    required this.label,
    required this.colors,
    required this.silhouette,
    required this.outline,
  });

  final BodySide side;
  final String label;
  final Map<Muscle, Color> colors;
  final Color silhouette;
  final Color outline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 0.42,
          child: CustomPaint(
            painter: _BodyPainter(
              side: side,
              colors: colors,
              silhouette: silhouette,
              outline: outline,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style:
              Theme.of(context).textTheme.labelSmall?.copyWith(color: outline),
        ),
      ],
    );
  }
}

/// One rounded blob in normalized figure coordinates (fractions of w / h).
class _Blob {
  const _Blob(this.cx, this.cy, this.cw, this.ch);
  final double cx, cy, cw, ch;

  RRect toRRect(Size s) {
    final rect = Rect.fromCenter(
      center: Offset(cx * s.width, cy * s.height),
      width: cw * s.width,
      height: ch * s.height,
    );
    return RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.shortestSide / 2),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.side,
    required this.colors,
    required this.silhouette,
    required this.outline,
  });

  final BodySide side;
  final Map<Muscle, Color> colors;
  final Color silhouette;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final body = _mannequin(size);

    canvas.drawPath(body, Paint()..color = silhouette);

    final regions = _regions[side]!;
    for (final entry in regions.entries) {
      final color = colors[entry.key];
      if (color == null) continue;
      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      for (final blob in entry.value) {
        canvas.drawRRect(blob.toRRect(size), paint);
      }
    }

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = outline,
    );
  }

  /// Flat mannequin assembled from capsules (unioned via non-zero fill).
  Path _mannequin(Size s) {
    final w = s.width, h = s.height;
    final path = Path();

    void oval(double cx, double cy, double cw, double ch) {
      path.addOval(
        Rect.fromCenter(
          center: Offset(cx * w, cy * h),
          width: cw * w,
          height: ch * h,
        ),
      );
    }

    void capsule(double cx, double cy, double cw, double ch) {
      final rect = Rect.fromCenter(
        center: Offset(cx * w, cy * h),
        width: cw * w,
        height: ch * h,
      );
      path.addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2)),
      );
    }

    oval(0.5, 0.06, 0.24, 0.10); // head
    capsule(0.5, 0.135, 0.12, 0.05); // neck
    capsule(0.5, 0.30, 0.52, 0.28); // torso
    capsule(0.5, 0.47, 0.44, 0.12); // hips
    capsule(0.20, 0.29, 0.14, 0.26); // upper arm L
    capsule(0.80, 0.29, 0.14, 0.26); // upper arm R
    capsule(0.14, 0.50, 0.11, 0.22); // forearm L
    capsule(0.86, 0.50, 0.11, 0.22); // forearm R
    capsule(0.38, 0.66, 0.20, 0.26); // thigh L
    capsule(0.62, 0.66, 0.20, 0.26); // thigh R
    capsule(0.38, 0.88, 0.14, 0.22); // shin L
    capsule(0.62, 0.88, 0.14, 0.22); // shin R

    return path;
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.colors != colors || old.silhouette != silhouette || old.side != side;

  static const Map<BodySide, Map<Muscle, List<_Blob>>> _regions = {
    BodySide.front: {
      Muscle.chest: [
        _Blob(0.40, 0.25, 0.20, 0.11),
        _Blob(0.60, 0.25, 0.20, 0.11),
      ],
      Muscle.frontDelts: [
        _Blob(0.25, 0.21, 0.14, 0.09),
        _Blob(0.75, 0.21, 0.14, 0.09),
      ],
      Muscle.sideDelts: [
        _Blob(0.19, 0.23, 0.11, 0.09),
        _Blob(0.81, 0.23, 0.11, 0.09),
      ],
      Muscle.biceps: [
        _Blob(0.21, 0.32, 0.11, 0.12),
        _Blob(0.79, 0.32, 0.11, 0.12),
      ],
      Muscle.forearms: [
        _Blob(0.14, 0.50, 0.10, 0.16),
        _Blob(0.86, 0.50, 0.10, 0.16),
      ],
      Muscle.abs: [_Blob(0.5, 0.38, 0.18, 0.14)],
      Muscle.obliques: [
        _Blob(0.38, 0.40, 0.09, 0.13),
        _Blob(0.62, 0.40, 0.09, 0.13),
      ],
      Muscle.quads: [
        _Blob(0.38, 0.64, 0.17, 0.20),
        _Blob(0.62, 0.64, 0.17, 0.20),
      ],
      Muscle.adductors: [
        _Blob(0.44, 0.60, 0.08, 0.14),
        _Blob(0.56, 0.60, 0.08, 0.14),
      ],
    },
    BodySide.back: {
      Muscle.traps: [_Blob(0.5, 0.20, 0.26, 0.11)],
      Muscle.rearDelts: [
        _Blob(0.24, 0.22, 0.12, 0.09),
        _Blob(0.76, 0.22, 0.12, 0.09),
      ],
      Muscle.triceps: [
        _Blob(0.21, 0.32, 0.11, 0.13),
        _Blob(0.79, 0.32, 0.11, 0.13),
      ],
      Muscle.lats: [
        _Blob(0.40, 0.35, 0.16, 0.15),
        _Blob(0.60, 0.35, 0.16, 0.15),
      ],
      Muscle.lowerBack: [_Blob(0.5, 0.45, 0.22, 0.08)],
      Muscle.glutes: [
        _Blob(0.40, 0.53, 0.17, 0.11),
        _Blob(0.60, 0.53, 0.17, 0.11),
      ],
      Muscle.hamstrings: [
        _Blob(0.38, 0.70, 0.17, 0.18),
        _Blob(0.62, 0.70, 0.17, 0.18),
      ],
      Muscle.calves: [
        _Blob(0.38, 0.89, 0.13, 0.16),
        _Blob(0.62, 0.89, 0.13, 0.16),
      ],
      Muscle.forearms: [
        _Blob(0.14, 0.50, 0.10, 0.16),
        _Blob(0.86, 0.50, 0.10, 0.16),
      ],
    },
  };
}
