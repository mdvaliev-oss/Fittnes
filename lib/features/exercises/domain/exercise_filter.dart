import 'entities/exercise.dart';
import 'entities/exercise_enums.dart';
import 'entities/muscle.dart';
import 'entities/muscle_group.dart';

/// Immutable value object describing the active search + facet filters.
class ExerciseFilter {
  const ExerciseFilter({
    this.query = '',
    this.group,
    this.muscle,
    this.equipment,
    this.level,
    this.mechanic,
    this.category,
    this.favoritesOnly = false,
  });

  final String query;

  /// Quick-chip region (chest / back / …). Matches primary muscles only, so
  /// "Спина" doesn't fill up with presses that merely stabilise with the back.
  final MuscleGroup? group;
  final Muscle? muscle;
  final Equipment? equipment;
  final ExperienceLevel? level;
  final Mechanic? mechanic;
  final ExerciseCategory? category;
  final bool favoritesOnly;

  bool get isEmpty =>
      query.isEmpty && group == null && !favoritesOnly && activeFacetCount == 0;

  /// Facets that live in the "Фильтры" sheet (not the quick chips / search).
  int get activeFacetCount => [
        muscle,
        equipment,
        level,
        mechanic,
        category,
      ].where((f) => f != null).length;

  /// When nothing narrows the catalog by region or text, the list is shown
  /// grouped by region with headers.
  bool get isBrowsing => query.isEmpty && group == null;

  ExerciseFilter copyWith({
    String? query,
    MuscleGroup? group,
    Muscle? muscle,
    Equipment? equipment,
    ExperienceLevel? level,
    Mechanic? mechanic,
    ExerciseCategory? category,
    bool? favoritesOnly,
  }) {
    return ExerciseFilter(
      query: query ?? this.query,
      group: group ?? this.group,
      muscle: muscle ?? this.muscle,
      equipment: equipment ?? this.equipment,
      level: level ?? this.level,
      mechanic: mechanic ?? this.mechanic,
      category: category ?? this.category,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }

  // copyWith can't set a facet back to null, so each toggle rebuilds the
  // value explicitly: same value again → cleared, otherwise → replaced.
  ExerciseFilter toggleGroup(MuscleGroup? g) => ExerciseFilter(
        query: query,
        group: group == g ? null : g,
        muscle: muscle,
        equipment: equipment,
        level: level,
        mechanic: mechanic,
        category: category,
        favoritesOnly: favoritesOnly,
      );
  ExerciseFilter toggleMuscle(Muscle? m) => ExerciseFilter(
        query: query,
        group: group,
        muscle: muscle == m ? null : m,
        equipment: equipment,
        level: level,
        mechanic: mechanic,
        category: category,
        favoritesOnly: favoritesOnly,
      );
  ExerciseFilter toggleEquipment(Equipment? e) => ExerciseFilter(
        query: query,
        group: group,
        muscle: muscle,
        equipment: equipment == e ? null : e,
        level: level,
        mechanic: mechanic,
        category: category,
        favoritesOnly: favoritesOnly,
      );
  ExerciseFilter toggleLevel(ExperienceLevel? l) => ExerciseFilter(
        query: query,
        group: group,
        muscle: muscle,
        equipment: equipment,
        level: level == l ? null : l,
        mechanic: mechanic,
        category: category,
        favoritesOnly: favoritesOnly,
      );
  ExerciseFilter toggleMechanic(Mechanic? m) => ExerciseFilter(
        query: query,
        group: group,
        muscle: muscle,
        equipment: equipment,
        level: level,
        mechanic: mechanic == m ? null : m,
        category: category,
        favoritesOnly: favoritesOnly,
      );
  ExerciseFilter toggleCategory(ExerciseCategory? c) => ExerciseFilter(
        query: query,
        group: group,
        muscle: muscle,
        equipment: equipment,
        level: level,
        mechanic: mechanic,
        category: category == c ? null : c,
        favoritesOnly: favoritesOnly,
      );
  ExerciseFilter toggleFavorites() => copyWith(favoritesOnly: !favoritesOnly);

  ExerciseFilter withQuery(String q) => copyWith(query: q);

  /// Clears only the sheet facets, keeping search text and the quick chip.
  ExerciseFilter clearedFacets() => ExerciseFilter(
        query: query,
        group: group,
        favoritesOnly: favoritesOnly,
      );

  ExerciseFilter cleared() => const ExerciseFilter();

  /// Returns true if [e] passes every active filter. The favorites facet is
  /// applied only when the caller supplies the [favorites] set — the
  /// repository doesn't know it, the presentation layer does.
  bool matches(Exercise e, {Set<String>? favorites}) {
    if (favoritesOnly && favorites != null && !favorites.contains(e.id)) {
      return false;
    }
    if (group != null && !e.primaryMuscles.any(group!.muscles.contains)) {
      return false;
    }
    if (muscle != null &&
        !e.primaryMuscles.contains(muscle) &&
        !e.secondaryMuscles.contains(muscle)) {
      return false;
    }
    if (equipment != null && e.equipment != equipment) return false;
    if (level != null && e.level != level) return false;
    if (mechanic != null && e.mechanic != mechanic) return false;
    if (category != null && e.category != category) return false;
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      final hit = e.name.toLowerCase().contains(q) ||
          (e.altName?.toLowerCase().contains(q) ?? false);
      if (!hit) return false;
    }
    return true;
  }
}
