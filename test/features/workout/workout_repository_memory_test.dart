import 'package:fittnes/features/workout/data/workout_repository_memory.dart';
import 'package:fittnes/features/workout/domain/entities/set_type.dart';
import 'package:fittnes/features/workout/domain/entities/workout_exercise_entry.dart';
import 'package:fittnes/features/workout/domain/entities/workout_session.dart';
import 'package:fittnes/features/workout/domain/entities/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSession _session({
  required int id,
  required DateTime at,
  required List<WorkoutSet> benchSets,
}) {
  return WorkoutSession(
    id: id,
    title: 'Session $id',
    startedAt: at,
    finishedAt: at.add(const Duration(hours: 1)),
    entries: [
      WorkoutExerciseEntry(
        id: id * 10,
        exerciseId: 'bench',
        exerciseName: 'Жим лёжа',
        sets: benchSets,
      ),
    ],
  );
}

void main() {
  group('Workout aggregates', () {
    test('warm-up sets are excluded from volume and e1RM', () {
      const warm = WorkoutSet(id: 1, weight: 40, reps: 10, type: SetType.warmup);
      const work = WorkoutSet(id: 2, weight: 100, reps: 5);
      const entry = WorkoutExerciseEntry(
        id: 1,
        exerciseId: 'bench',
        exerciseName: 'Bench',
        sets: [warm, work],
      );
      expect(entry.volume, 500); // only the working set
      expect(entry.topEstimatedOneRepMax, greaterThan(0));
    });

    test('session totals sum across entries', () {
      final s = _session(
        id: 1,
        at: DateTime(2026, 1, 1),
        benchSets: const [
          WorkoutSet(id: 1, weight: 100, reps: 5, isCompleted: true),
          WorkoutSet(id: 2, weight: 100, reps: 5, isCompleted: true),
        ],
      );
      expect(s.totalVolume, 1000);
      expect(s.totalSets, 2);
      expect(s.completedSets, 2);
    });
  });

  group('WorkoutRepositoryMemory', () {
    test('history returns finished sessions newest first', () async {
      final repo = WorkoutRepositoryMemory();
      await repo.save(_session(id: 1, at: DateTime(2026, 1, 1), benchSets: const []));
      await repo.save(_session(id: 2, at: DateTime(2026, 2, 1), benchSets: const []));

      final history = await repo.history();
      expect(history.map((s) => s.id), [2, 1]);
    });

    test('lastPerformance returns the most recent entry for the exercise', () async {
      final repo = WorkoutRepositoryMemory();
      await repo.save(_session(
        id: 1,
        at: DateTime(2026, 1, 1),
        benchSets: const [WorkoutSet(id: 1, weight: 90, reps: 5, isCompleted: true)],
      ),);
      await repo.save(_session(
        id: 2,
        at: DateTime(2026, 2, 1),
        benchSets: const [WorkoutSet(id: 2, weight: 100, reps: 5, isCompleted: true)],
      ),);

      final last = await repo.lastPerformance('bench');
      expect(last, isNotNull);
      expect(last!.sets.single.weight, 100);
    });

    test('personalRecord tracks the best estimated 1RM', () async {
      final repo = WorkoutRepositoryMemory();
      await repo.save(_session(
        id: 1,
        at: DateTime(2026, 1, 1),
        benchSets: const [WorkoutSet(id: 1, weight: 100, reps: 5, isCompleted: true)],
      ),);
      await repo.save(_session(
        id: 2,
        at: DateTime(2026, 2, 1),
        benchSets: const [WorkoutSet(id: 2, weight: 110, reps: 3, isCompleted: true)],
      ),);

      final pr = await repo.personalRecord('bench');
      expect(pr, isNotNull);
      expect(pr!.bestWeight, 110);
      expect(pr.bestReps, 3);
    });

    test('incomplete or unfilled sets do not count towards a PR', () async {
      final repo = WorkoutRepositoryMemory();
      await repo.save(_session(
        id: 1,
        at: DateTime(2026, 1, 1),
        benchSets: const [
          WorkoutSet(id: 1, weight: 200, reps: 1, isCompleted: false),
          WorkoutSet(id: 2, weight: 80, reps: 8, isCompleted: true),
        ],
      ),);

      final pr = await repo.personalRecord('bench');
      expect(pr!.bestWeight, 80); // the 200kg set was not completed
    });
  });
}
