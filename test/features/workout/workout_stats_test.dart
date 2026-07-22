import 'package:fittnes/features/workout/domain/entities/workout_exercise_entry.dart';
import 'package:fittnes/features/workout/domain/entities/workout_session.dart';
import 'package:fittnes/features/workout/domain/entities/workout_set.dart';
import 'package:fittnes/features/workout/domain/services/workout_stats.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSession _session(
  int id,
  DateTime day, {
  double weight = 100,
  int reps = 5,
}) {
  return WorkoutSession(
    id: id,
    title: 'S$id',
    startedAt: day,
    finishedAt: day.add(const Duration(hours: 1)),
    entries: [
      WorkoutExerciseEntry(
        id: id,
        exerciseId: 'bench',
        exerciseName: 'Bench',
        sets: [
          WorkoutSet(id: id, weight: weight, reps: reps, isCompleted: true),
        ],
      ),
    ],
  );
}

void main() {
  group('computeWorkoutStats', () {
    test('empty history returns zeroed stats', () {
      expect(computeWorkoutStats(const []), WorkoutStats.empty);
    });

    test('counts workouts and weekly tonnage within 7 days', () {
      final now = DateTime(2026, 6, 10);
      final stats = computeWorkoutStats(
        [
          _session(1, DateTime(2026, 6, 9)), // within week: 500
          _session(2, DateTime(2026, 6, 8)), // within week: 500
          _session(3, DateTime(2026, 5, 1)), // outside week
        ],
        now: now,
      );

      expect(stats.totalWorkouts, 3);
      expect(stats.weeklyTonnage, 1000);
    });

    test('streak counts consecutive days ending at the latest workout', () {
      final now = DateTime(2026, 6, 10);
      final stats = computeWorkoutStats(
        [
          _session(1, DateTime(2026, 6, 10)),
          _session(2, DateTime(2026, 6, 9)),
          _session(3, DateTime(2026, 6, 8)),
          _session(4, DateTime(2026, 6, 6)), // gap breaks the streak
        ],
        now: now,
      );

      expect(stats.streakDays, 3);
    });

    test('bestE1rm picks the top estimated 1RM across sessions', () {
      final now = DateTime(2026, 6, 10);
      final stats = computeWorkoutStats(
        [
          _session(1, DateTime(2026, 6, 9), weight: 100, reps: 5),
          _session(2, DateTime(2026, 6, 8), weight: 120, reps: 3),
        ],
        now: now,
      );

      // Epley(120,3) = 132 > Epley(100,5) ≈ 116.7
      expect(stats.bestE1rm, closeTo(132, 0.01));
    });
  });
}
