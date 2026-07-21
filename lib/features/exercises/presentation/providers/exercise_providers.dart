import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/exercise_local_data_source.dart';
import '../../data/exercise_repository_impl.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/exercise_enums.dart';
import '../../domain/entities/muscle.dart';
import '../../domain/exercise_filter.dart';
import '../../domain/repositories/exercise_repository.dart';

/// Bundled data source.
final exerciseLocalDataSourceProvider =
    Provider<ExerciseLocalDataSource>((ref) => ExerciseLocalDataSource());

/// Repository — the single dependency presentation talks to.
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepositoryImpl(ref.watch(exerciseLocalDataSourceProvider));
});

/// Holds the active search + facet filters.
class ExerciseFilterNotifier extends Notifier<ExerciseFilter> {
  @override
  ExerciseFilter build() => const ExerciseFilter();

  void setQuery(String q) => state = state.withQuery(q);
  void toggleMuscle(Muscle? muscle) => state = state.toggleMuscle(muscle);
  void toggleEquipment(Equipment? equipment) =>
      state = state.toggleEquipment(equipment);
  void toggleLevel(ExperienceLevel? level) => state = state.toggleLevel(level);
  void toggleCategory(ExerciseCategory? category) =>
      state = state.toggleCategory(category);
  void clear() => state = state.cleared();
}

final exerciseFilterProvider =
    NotifierProvider<ExerciseFilterNotifier, ExerciseFilter>(
  ExerciseFilterNotifier.new,
);

/// Exercises matching the current filter. Rebuilds when filters change.
final filteredExercisesProvider = FutureProvider<List<Exercise>>((ref) {
  final filter = ref.watch(exerciseFilterProvider);
  return ref.watch(exerciseRepositoryProvider).search(filter);
});

/// Total catalog size (for the header count).
final exerciseCountProvider = FutureProvider<int>((ref) async {
  final all = await ref.watch(exerciseRepositoryProvider).getAll();
  return all.length;
});

/// Single exercise by id, for the detail screen.
final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((ref, id) {
  return ref.watch(exerciseRepositoryProvider).getById(id);
});
