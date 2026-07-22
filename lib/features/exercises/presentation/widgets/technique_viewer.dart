import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/exercise.dart';
import 'exercise_visuals.dart';

/// Shows the exercise technique as an infinitely looping visual.
///
/// When [Exercise.mediaUrl] points at a WebP/GIF it loops that; otherwise it
/// renders an animated rep placeholder that conveys start → end + tempo so the
/// screen is never empty before real media is imported.
class TechniqueViewer extends StatefulWidget {
  const TechniqueViewer({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<TechniqueViewer> createState() => _TechniqueViewerState();
}

class _TechniqueViewerState extends State<TechniqueViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.exercise.mediaUrl;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: _bgGradient),
          child: media != null
              ? Image.network(media, fit: BoxFit.cover)
              : _RepPlaceholder(controller: _c, exercise: widget.exercise),
        ),
      ),
    );
  }

  static const _bgGradient = LinearGradient(
    colors: [Color(0xFF161620), Color(0xFF0E0E16)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class _RepPlaceholder extends StatelessWidget {
  const _RepPlaceholder({required this.controller, required this.exercise});

  final AnimationController controller;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    return Stack(
      children: [
        // Motion trajectory guides.
        const Positioned.fill(
          child: CustomPaint(painter: _TrajectoryPainter()),
        ),
        // Moving equipment marker travelling the rep path.
        AnimatedBuilder(
          animation: curve,
          builder: (context, _) {
            return Align(
              alignment: Alignment(0, -0.5 + curve.value), // top → bottom
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(
                  ExerciseVisuals.equipmentIcon(exercise.equipment),
                  color: Colors.white,
                  size: 26,
                ),
              ),
            );
          },
        ),
        // Position labels.
        const Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.md,
          child: _PosLabel('СТАРТ'),
        ),
        const Positioned(
          bottom: AppSpacing.sm,
          left: AppSpacing.md,
          child: _PosLabel('ФИНИШ'),
        ),
      ],
    );
  }
}

class _PosLabel extends StatelessWidget {
  const _PosLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Colors.white.withValues(alpha: 0.45),
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  const _TrajectoryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Dashed vertical trajectory.
    const dash = 10.0, gap = 8.0;
    var y = size.height * 0.16;
    final end = size.height * 0.84;
    while (y < end) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + dash).clamp(0.0, end)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_TrajectoryPainter oldDelegate) => false;
}
