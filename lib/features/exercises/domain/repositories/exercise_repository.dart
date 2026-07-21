import '../entities/exercise.dart';
import '../exercise_filter.dart';

/// Abstraction over the exercise catalog. Presentation depends on this,
/// not on any concrete data source (DIP).
abstract interface class ExerciseRepository {
  /// Loads and caches the full catalog. Safe to call repeatedly.
  Future<List<Exercise>> getAll();

  /// Returns the exercises matching [filter], sorted by name.
  Future<List<Exercise>> search(ExerciseFilter filter);

  /// Returns a single exercise by id, or null if not found.
  Future<Exercise?> getById(String id);
}
