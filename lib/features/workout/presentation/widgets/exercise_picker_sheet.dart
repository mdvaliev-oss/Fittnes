import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/ambient_background.dart';
import '../../../exercises/domain/entities/exercise.dart';
import '../../../exercises/presentation/providers/exercise_providers.dart';
import '../../../exercises/presentation/widgets/exercise_visuals.dart';

/// Modal picker to add an exercise to the active workout. Returns the chosen
/// [Exercise], or null if dismissed.
Future<Exercise?> showExercisePicker(BuildContext context) {
  return showModalBottomSheet<Exercise>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.85,
      child: _ExercisePickerSheet(),
    ),
  );
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet();

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    final async = ref.watch(allExercisesProvider);

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      child: AmbientBackground(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text('Добавить упражнение', style: text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Поиск…',
                    prefixIcon:
                        Icon(Icons.search_rounded, color: glass.textMid),
                    filled: true,
                    fillColor: glass.fill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: async.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Ошибка: $e')),
                    data: (all) {
                      final list = _query.isEmpty
                          ? all
                          : all
                              .where(
                                (e) =>
                                    e.name.toLowerCase().contains(_query) ||
                                    (e.altName
                                            ?.toLowerCase()
                                            .contains(_query) ??
                                        false),
                              )
                              .toList();
                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final ex = list[i];
                          return ListTile(
                            leading: Icon(
                              ExerciseVisuals.categoryIcon(ex.category),
                              color: glass.textMid,
                            ),
                            title: Text(ex.name),
                            subtitle: Text(
                              ex.primaryMuscles.map((m) => m.label).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => Navigator.pop(context, ex),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
