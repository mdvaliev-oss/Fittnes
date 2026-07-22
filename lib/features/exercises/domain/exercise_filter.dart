import 'entities/exercise.dart';
import 'entities/exercise_enums.dart';
import 'entities/muscle.dart';

/// Immutable value object describing the active search + facet filters.
class ExerciseFilter {
  const ExerciseFilter({
    this.query = '',
    this.muscle,
    this.equipment,
    this.level,
    this.category,
  });

  final String query;
  final Muscle? muscle;
  final Equipment? equipment;
  final ExperienceLevel? level;
  final ExerciseCategory? category;

  bool get isEmpty =>
      query.isEmpty &&
      muscle == null &&
      equipment == null &&
      level == null &&
      category == null;

  int get activeFacetCount => [
        muscle,
        equipment,
        level,
        category,
      ].where((f) => f != null).length;

  ExerciseFilter copyWith({
    String? query,
    Muscle? muscle,
    Equipment? equipment,
    ExperienceLevel? level,
    ExerciseCategory? category,
  }) {
    return ExerciseFilter(
      query: query ?? this.query,
      muscle: muscle ?? this.muscle,
      equipment: equipment ?? this.equipment,
      level: level ?? this.level,
      category: category ?? this.category,
    );
  }

  /// copyWith can't set fields back to null; these toggles handle clearing.
  ExerciseFilter toggleMuscle(Muscle? m) => ExerciseFilter(
        query: query,
        muscle: muscle == m ? null : m,
        equipment: equipment,
        level: level,
        category: category,
      );
  ExerciseFilter toggleEquipment(Equipment? e) => ExerciseFilter(
        query: query,
        muscle: muscle,
        equipment: equipment == e ? null : e,
        level: level,
        category: category,
      );
  ExerciseFilter toggleLevel(ExperienceLevel? l) => ExerciseFilter(
        query: query,
        muscle: muscle,
        equipment: equipment,
        level: level == l ? null : l,
        category: category,
      );
  ExerciseFilter toggleCategory(ExerciseCategory? c) => ExerciseFilter(
        query: query,
        muscle: muscle,
        equipment: equipment,
        level: level,
        category: category == c ? null : c,
      );

  ExerciseFilter withQuery(String q) => copyWith(query: q);

  ExerciseFilter cleared() => const ExerciseFilter();

  /// Returns true if [e] passes every active filter.
  bool matches(Exercise e) {
    if (muscle != null &&
        !e.primaryMuscles.contains(muscle) &&
        !e.secondaryMuscles.contains(muscle)) {
      return false;
    }
    if (equipment != null && e.equipment != equipment) return false;
    if (level != null && e.level != level) return false;
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
