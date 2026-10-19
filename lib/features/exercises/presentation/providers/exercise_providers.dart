import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/settings/app_settings.dart';
import '../../data/exercise_local_data_source.dart';
import '../../data/exercise_repository_impl.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/exercise_enums.dart';
import '../../domain/entities/muscle.dart';
import '../../domain/entities/muscle_group.dart';
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
  void toggleGroup(MuscleGroup? group) => state = state.toggleGroup(group);
  void toggleMuscle(Muscle? muscle) => state = state.toggleMuscle(muscle);
  void toggleEquipment(Equipment? equipment) =>
      state = state.toggleEquipment(equipment);
  void toggleLevel(ExperienceLevel? level) => state = state.toggleLevel(level);
  void toggleMechanic(Mechanic? mechanic) =>
      state = state.toggleMechanic(mechanic);
  void toggleCategory(ExerciseCategory? category) =>
      state = state.toggleCategory(category);
  void toggleFavorites() => state = state.toggleFavorites();
  void clearFacets() => state = state.clearedFacets();
  void clear() => state = state.cleared();
}

final exerciseFilterProvider =
    NotifierProvider<ExerciseFilterNotifier, ExerciseFilter>(
  ExerciseFilterNotifier.new,
);

/// Starred exercise ids, persisted in SharedPreferences.
class FavoriteExercisesController extends Notifier<Set<String>> {
  static const _key = 'exercises.favorites';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Set<String> build() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const {};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return const {};
    }
  }

  bool isFavorite(String id) => state.contains(id);

  Future<void> toggle(String id) async {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
    await _prefs.setString(_key, jsonEncode(next.toList()));
  }
}

final favoriteExercisesProvider =
    NotifierProvider<FavoriteExercisesController, Set<String>>(
  FavoriteExercisesController.new,
);

/// Exercises matching the current filter. Rebuilds when filters or the
/// favorites set change.
final filteredExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final filter = ref.watch(exerciseFilterProvider);
  final favorites = ref.watch(favoriteExercisesProvider);
  final list = await ref.watch(exerciseRepositoryProvider).search(filter);
  if (!filter.favoritesOnly) return list;
  return list.where((e) => favorites.contains(e.id)).toList(growable: false);
});

/// Catalog presentation: list rows or a two-column grid.
enum CatalogLayout { list, grid }

final catalogLayoutProvider =
    StateProvider<CatalogLayout>((ref) => CatalogLayout.list);

/// The full catalog (used by pickers that filter locally).
final allExercisesProvider = FutureProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).getAll();
});

/// Total catalog size (for the header count).
final exerciseCountProvider = FutureProvider<int>((ref) async {
  final all = await ref.watch(allExercisesProvider.future);
  return all.length;
});

/// Single exercise by id, for the detail screen.
final exerciseByIdProvider =
    FutureProvider.family<Exercise?, String>((ref, id) {
  return ref.watch(exerciseRepositoryProvider).getById(id);
});
