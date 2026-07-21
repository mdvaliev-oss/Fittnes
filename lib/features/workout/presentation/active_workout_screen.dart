import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/primary_button.dart';
import '../../recommendations/domain/progression_engine.dart';
import '../domain/entities/workout_session.dart';
import 'providers/active_workout_controller.dart';
import 'providers/rest_timer_controller.dart';
import 'providers/workout_providers.dart';
import 'widgets/exercise_picker_sheet.dart';
import 'widgets/rest_timer_bar.dart';
import 'widgets/workout_exercise_card.dart';

/// The live training screen: log sets, auto-rest, then finish & persist.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure a session exists if the screen was opened directly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(activeWorkoutControllerProvider.notifier);
      if (!controller.isActive) controller.start();
    });
  }

  Future<void> _addExercise() async {
    final exercise = await showExercisePicker(context);
    if (exercise == null) return;
    final last = await ref
        .read(workoutRepositoryProvider)
        .lastPerformance(exercise.id);
    final advice = ProgressionEngine.recommend(last);
    ref.read(activeWorkoutControllerProvider.notifier).addExercise(
          exercise,
          recommendedWeight: advice.suggestedWeight,
          recommendedReps: advice.suggestedReps,
        );
  }

  Future<void> _finish() async {
    final controller = ref.read(activeWorkoutControllerProvider.notifier);
    final finished = controller.finish();
    ref.read(restTimerProvider.notifier).skip();
    if (finished != null && finished.totalSets > 0) {
      await ref.read(workoutRepositoryProvider).save(finished);
      ref.invalidate(workoutHistoryProvider);
    }
    if (mounted) context.go(AppRoutes.home);
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Отменить тренировку?'),
        content: const Text('Несохранённые подходы будут потеряны.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Назад'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отменить', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      ref.read(activeWorkoutControllerProvider.notifier).cancel();
      ref.read(restTimerProvider.notifier).skip();
      if (mounted) context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeWorkoutControllerProvider);
    ref.watch(workoutTickerProvider); // 1 Hz rebuild for the elapsed clock

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        body: AmbientBackground(
          child: SafeArea(
            child: session == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _Header(
                        session: session,
                        onFinish: _finish,
                        onCancel: _confirmCancel,
                      ),
                      const RestTimerBar(),
                      Expanded(
                        child: session.entries.isEmpty
                            ? const _EmptyState()
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.xs,
                                  AppSpacing.md,
                                  120,
                                ),
                                children: [
                                  for (final e in session.entries)
                                    WorkoutExerciseCard(entry: e),
                                ],
                              ),
                      ),
                    ],
                  ),
          ),
        ),
        floatingActionButton: session == null
            ? null
            : FloatingActionButton.extended(
                onPressed: _addExercise,
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Упражнение', style: TextStyle(color: Colors.white)),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.session,
    required this.onFinish,
    required this.onCancel,
  });

  final WorkoutSession session;
  final VoidCallback onFinish;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: onCancel, icon: const Icon(Icons.close_rounded)),
              Expanded(child: Text(session.title, style: text.titleLarge)),
              SizedBox(
                width: 130,
                child: PrimaryButton(
                  label: 'Завершить',
                  icon: Icons.check_rounded,
                  onPressed: onFinish,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'Время', value: formatClock(session.elapsed())),
              _Stat(
                label: 'Тоннаж',
                value: '${session.totalVolume.toStringAsFixed(0)} кг',
              ),
              _Stat(
                label: 'Подходы',
                value: '${session.completedSets}/${session.totalSets}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Column(
      children: [
        Text(value, style: AppTypography.numeric(glass.textHi, size: 20)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center_rounded, size: 48, color: glass.textLow),
            const SizedBox(height: AppSpacing.md),
            Text('Добавьте первое упражнение', style: text.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Нажмите «Упражнение», чтобы начать логировать подходы.',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
