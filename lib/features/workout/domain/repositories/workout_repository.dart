import '../entities/personal_record.dart';
import '../entities/workout_exercise_entry.dart';
import '../entities/workout_session.dart';

/// Persistence boundary for workouts. Presentation depends on this; the
/// in-memory implementation is swapped for a Drift-backed one in Module 2B
/// without any change above this line (DIP).
abstract interface class WorkoutRepository {
  /// Persists a finished session and updates derived records.
  Future<void> save(WorkoutSession session);

  /// Finished sessions, most recent first.
  Future<List<WorkoutSession>> history();

  /// The most recent logged entry for [exerciseId] — powers "last time" and
  /// the recommended starting weight.
  Future<WorkoutExerciseEntry?> lastPerformance(String exerciseId);

  /// Best-ever performance for [exerciseId], or null if never trained.
  Future<PersonalRecord?> personalRecord(String exerciseId);
}
