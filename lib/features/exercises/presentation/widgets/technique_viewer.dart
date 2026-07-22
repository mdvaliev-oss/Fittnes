import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/exercise.dart';
import 'technique_animation.dart';

/// Shows the exercise technique as an infinitely looping visual.
///
/// When [Exercise.mediaUrl] points at a WebP/GIF it loops that; otherwise it
/// renders an [AnimatedTechniqueFigure] that actually performs the movement
/// (squat, hinge, press, pull, curl …) so the screen conveys the real motion
/// before any media is imported.
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
      duration: const Duration(milliseconds: 2600),
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
              : _AnimatedPreview(controller: _c, exercise: widget.exercise),
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

class _AnimatedPreview extends StatelessWidget {
  const _AnimatedPreview({required this.controller, required this.exercise});

  final AnimationController controller;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final pattern = MovementPattern.forExercise(exercise);
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => AnimatedTechniqueFigure(
                progress: controller.value,
                pattern: pattern,
                equipment: exercise.equipment,
              ),
            ),
          ),
        ),
        // Live phase pill (эксцентрика / концентрика) driven by direction.
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.md,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => _PhasePill(
              lowering: controller.status != AnimationStatus.reverse,
            ),
          ),
        ),
        // Tempo hint, when known.
        if (exercise.tempo != null)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.md,
            child: _TempoPill(exercise.tempo!),
          ),
        // Rep progress bar.
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.sm,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => _RepBar(value: controller.value),
          ),
        ),
      ],
    );
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({required this.lowering});
  final bool lowering;

  @override
  Widget build(BuildContext context) {
    final color = lowering ? AppColors.primaryBright : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            lowering
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            lowering ? 'Опускание' : 'Подъём',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TempoPill extends StatelessWidget {
  const _TempoPill(this.tempo);
  final String tempo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        'Темп $tempo',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _RepBar extends StatelessWidget {
  const _RepBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 3,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        valueColor: const AlwaysStoppedAnimation(AppColors.primaryBright),
      ),
    );
  }
}
