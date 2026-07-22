import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../domain/entities/exercise_enums.dart';
import '../domain/entities/muscle.dart';
import 'providers/exercise_providers.dart';
import 'widgets/exercise_card.dart';
import 'widgets/filter_chip_row.dart';

/// Exercise catalog: live search + muscle / equipment / level facets.
class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(exerciseFilterProvider);
    final notifier = ref.read(exerciseFilterProvider.notifier);
    final results = ref.watch(filteredExercisesProvider);
    final total = ref.watch(exerciseCountProvider);
    final glass = context.glass;
    final text = Theme.of(context).textTheme;

    return AmbientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Упражнения', style: text.headlineLarge),
                  const SizedBox(width: AppSpacing.xs),
                  total.maybeWhen(
                    data: (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('$n', style: text.bodyMedium),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const Spacer(),
                  if (!filter.isEmpty)
                    TextButton(
                      onPressed: notifier.clear,
                      child: const Text('Сбросить'),
                    ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                onChanged: notifier.setQuery,
                style: text.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Поиск упражнения…',
                  prefixIcon: Icon(Icons.search_rounded, color: glass.textMid),
                  filled: true,
                  fillColor: glass.fill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Facet chip rows
            FilterChipRow<Muscle>(
              values: Muscle.values,
              labelOf: (m) => m.label,
              selected: filter.muscle,
              onToggle: notifier.toggleMuscle,
            ),
            const SizedBox(height: AppSpacing.xs),
            FilterChipRow<Equipment>(
              values: Equipment.values,
              labelOf: (e) => e.label,
              selected: filter.equipment,
              onToggle: notifier.toggleEquipment,
            ),
            const SizedBox(height: AppSpacing.xs),
            FilterChipRow<ExperienceLevel>(
              values: ExperienceLevel.values,
              labelOf: (l) => l.label,
              selected: filter.level,
              onToggle: notifier.toggleLevel,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Results
            Expanded(
              child: results.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Ошибка загрузки: $e', style: text.bodyMedium),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text('Ничего не найдено', style: text.bodyMedium),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xxl * 2,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, i) {
                      final ex = list[i];
                      return ExerciseCard(
                        exercise: ex,
                        onTap: () =>
                            context.push(AppRoutes.exerciseDetail(ex.id)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
