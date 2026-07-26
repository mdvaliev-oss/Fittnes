import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/units/weight_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../recommendations/domain/progression_advice.dart';
import '../../../recommendations/presentation/recommendation_providers.dart';
import '../../domain/entities/workout_exercise_entry.dart';
import '../providers/active_workout_controller.dart';
import '../providers/workout_providers.dart';
import 'set_row.dart';

/// A single exercise block inside the active workout: header, set rows and the
/// "add set" action. Surfaces last-time hints and a PR badge.
class WorkoutExerciseCard extends ConsumerWidget {
  const WorkoutExerciseCard({super.key, required this.entry});

  final WorkoutExerciseEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(activeWorkoutControllerProvider.notifier);
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    final unit = ref.watch(appSettingsProvider.select((s) => s.unit));
    final last =
        ref.watch(lastPerformanceProvider(entry.exerciseId)).valueOrNull;
    final pr = ref.watch(personalRecordProvider(entry.exerciseId)).valueOrNull;
    final advice =
        ref.watch(recommendationProvider(entry.exerciseId)).valueOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        gradientBorder: entry.isSuperset,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (entry.isSuperset)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child:
                        Icon(Icons.link_rounded, size: 18, color: glass.accent),
                  ),
                Expanded(
                  child: Text(
                    entry.exerciseName,
                    style: text.titleLarge?.copyWith(fontSize: 17),
                  ),
                ),
                if (pr != null)
                  _PrBadge(oneRepMax: pr.bestEstimatedOneRepMax, unit: unit),
                _Menu(entryId: entry.id, controller: controller),
              ],
            ),
            if (last != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: AppSpacing.xs),
                child: Text(
                  'Прошлый раз: ${_summary(last, unit)}',
                  style: text.labelSmall?.copyWith(color: glass.textMid),
                ),
              ),
            if (advice != null)
              _RecommendationChip(
                advice: advice,
                onApply:
                    (advice.suggestedWeight != null && entry.sets.isNotEmpty)
                        ? () => controller.updateSet(
                              entry.id,
                              entry.sets.first.id,
                              weight: advice.suggestedWeight,
                              reps: advice.suggestedReps,
                            )
                        : null,
              ),
            const SizedBox(height: AppSpacing.xs),
            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text('#', style: text.labelSmall)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    flex: 3,
                    child: Center(child: Text('Вес', style: text.labelSmall)),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    flex: 2,
                    child: Center(child: Text('Повт.', style: text.labelSmall)),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 46,
                    child: Center(
                      child: Text('Усилие', style: text.labelSmall),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            for (var i = 0; i < entry.sets.length; i++)
              SetRow(
                key: ValueKey(entry.sets[i].id),
                entryId: entry.id,
                set: entry.sets[i],
                index: _workingIndex(i),
                restSeconds: entry.restSeconds,
                previousHint: _hintForIndex(last, i),
              ),
            const SizedBox(height: AppSpacing.xs),
            _AddSetButton(onTap: () => controller.addSet(entry.id)),
          ],
        ),
      ),
    );
  }

  /// 1-based index counting only non-warmup sets up to position [i].
  int _workingIndex(int i) {
    var n = 0;
    for (var k = 0; k <= i; k++) {
      if (entry.sets[k].type.countsForVolume) n++;
    }
    return n;
  }

  String? _hintForIndex(WorkoutExerciseEntry? last, int i) {
    if (last == null || i >= last.sets.length) return null;
    final s = last.sets[i];
    if (s.weight == null || s.reps == null) return null;
    final w =
        s.weight! % 1 == 0 ? s.weight!.toStringAsFixed(0) : s.weight.toString();
    return '$w×${s.reps}';
  }

  String _summary(WorkoutExerciseEntry last, WeightUnit unit) {
    final working = last.sets.where((s) => s.isFilled).toList();
    if (working.isEmpty) return '—';
    final top = working.reduce((a, b) => a.weight! >= b.weight! ? a : b);
    return '${formatWeight(top.weight!, unit)} × ${top.reps} · '
        '${working.length} подх.';
  }
}

class _PrBadge extends StatelessWidget {
  const _PrBadge({required this.oneRepMax, required this.unit});
  final double oneRepMax;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 13,
            color: AppColors.accent,
          ),
          const SizedBox(width: 3),
          Text(
            formatValue(unit.fromKg(oneRepMax), unit),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.entryId, required this.controller});
  final int entryId;
  final ActiveWorkoutController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (v) {
        switch (v) {
          case 'superset':
            controller.toggleSuperset(entryId);
          case 'remove':
            controller.removeEntry(entryId);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'superset', child: Text('Суперсет с предыдущим')),
        PopupMenuItem(value: 'remove', child: Text('Удалить упражнение')),
      ],
    );
  }
}

class _RecommendationChip extends StatelessWidget {
  const _RecommendationChip({required this.advice, this.onApply});
  final ProgressionAdvice advice;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: advice.action.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: advice.action.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(advice.action.icon, size: 18, color: advice.action.color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.action.label,
                  style: text.labelLarge?.copyWith(color: advice.action.color),
                ),
                Text(advice.message, style: text.labelSmall),
              ],
            ),
          ),
          if (onApply != null)
            TextButton(
              onPressed: onApply,
              style: TextButton.styleFrom(
                foregroundColor: advice.action.color,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: const Text('Применить'),
            ),
        ],
      ),
    );
  }
}

class _AddSetButton extends StatelessWidget {
  const _AddSetButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Добавить подход'),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),
    );
  }
}
