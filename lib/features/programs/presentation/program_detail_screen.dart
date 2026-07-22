import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../recommendations/domain/progression_engine.dart';
import '../../workout/presentation/providers/active_workout_controller.dart';
import '../../workout/presentation/providers/workout_providers.dart';
import '../domain/workout_program.dart';
import 'programs_providers.dart';

/// Program detail: its days and the exercises in each, with a "start day"
/// action that seeds an active workout (weights recommended by the engine).
class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final String programId;

  Future<void> _startDay(
    BuildContext context,
    WidgetRef ref,
    ProgramDay day,
  ) async {
    final controller = ref.read(activeWorkoutControllerProvider.notifier);
    final repo = ref.read(workoutRepositoryProvider);
    controller.start(title: day.name);
    for (final pe in day.exercises) {
      final last = await repo.lastPerformance(pe.exerciseId);
      final advice = ProgressionEngine.recommend(
        last,
        target: RepRange(pe.targetMin, pe.targetMax),
      );
      controller.addExerciseRef(
        pe.exerciseId,
        pe.exerciseName,
        recommendedWeight: advice.suggestedWeight,
        recommendedReps: advice.suggestedReps ?? pe.targetMin,
        sets: pe.sets,
      );
    }
    if (context.mounted) unawaited(context.push(AppRoutes.activeWorkout));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(programByIdProvider(programId));
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: program == null
              ? const Center(child: Text('Программа не найдена'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(program.name, style: text.headlineMedium),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(program.description, style: text.bodyLarge),
                    const SizedBox(height: AppSpacing.md),
                    for (final day in program.days)
                      _DayCard(
                        day: day,
                        onStart: () => _startDay(context, ref, day),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.onStart});
  final ProgramDay day;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day.name, style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final pe in day.exercises)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pe.exerciseName,
                        style: text.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      pe.repScheme,
                      style: text.labelSmall?.copyWith(color: glass.textMid),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'Начать «${day.name}»',
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}
