import '../domain/entities/personal_record.dart';
import '../domain/entities/workout_exercise_entry.dart';
import '../domain/entities/workout_session.dart';
import '../domain/repositories/workout_repository.dart';

/// In-memory [WorkoutRepository] — persists for the lifetime of the app run.
///
/// Keeps derived queries (last performance, PRs) honest so the UI and tests
/// exercise real logic; Module 2B replaces the storage with Drift behind the
/// same interface.
class WorkoutRepositoryMemory implements WorkoutRepository {
  final List<WorkoutSession> _sessions = [];

  @override
  Future<void> save(WorkoutSession session) async {
    _sessions
      ..removeWhere((s) => s.id == session.id)
      ..add(session);
  }

  @override
  Future<List<WorkoutSession>> history() async {
    final finished = _sessions.where((s) => s.isFinished).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return finished;
  }

  @override
  Future<WorkoutExerciseEntry?> lastPerformance(String exerciseId) async {
    for (final session in await history()) {
      final match = session.entries
          .where((e) => e.exerciseId == exerciseId && e.sets.isNotEmpty);
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }

  @override
  Future<PersonalRecord?> personalRecord(String exerciseId) async {
    PersonalRecord? best;
    for (final session in _sessions.where((s) => s.isFinished)) {
      for (final entry in session.entries.where((e) => e.exerciseId == exerciseId)) {
        for (final set in entry.sets) {
          if (!set.isCompleted || !set.isFilled || set.estimatedOneRepMax <= 0) {
            continue;
          }
          if (best == null || set.estimatedOneRepMax > best.bestEstimatedOneRepMax) {
            best = PersonalRecord(
              exerciseId: exerciseId,
              bestWeight: set.weight!,
              bestReps: set.reps!,
              bestEstimatedOneRepMax: set.estimatedOneRepMax,
              achievedAt: session.finishedAt ?? session.startedAt,
            );
          }
        }
      }
    }
    return best;
  }
}
