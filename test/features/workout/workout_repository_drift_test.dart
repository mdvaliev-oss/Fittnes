// Requires generated Drift code: run
//   dart run build_runner build --delete-conflicting-outputs
// before executing this suite.
import 'package:drift/native.dart';
import 'package:fittnes/core/database/app_database.dart';
import 'package:fittnes/features/workout/data/workout_repository_drift.dart';
import 'package:fittnes/features/workout/domain/entities/set_type.dart';
import 'package:fittnes/features/workout/domain/entities/workout_exercise_entry.dart';
import 'package:fittnes/features/workout/domain/entities/workout_session.dart';
import 'package:fittnes/features/workout/domain/entities/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSession _bench(
  int id,
  DateTime at, {
  double weight = 100,
  int reps = 5,
}) {
  return WorkoutSession(
    id: id,
    title: 'Session $id',
    startedAt: at,
    finishedAt: at.add(const Duration(hours: 1)),
    entries: [
      WorkoutExerciseEntry(
        id: id,
        exerciseId: 'bench',
        exerciseName: 'Жим лёжа',
        sets: [
          const WorkoutSet(id: 1, weight: 40, reps: 10, type: SetType.warmup),
          WorkoutSet(
            id: 2,
            weight: weight,
            reps: reps,
            rpe: 8,
            isCompleted: true,
          ),
        ],
      ),
    ],
  );
}

void main() {
  late AppDatabase db;
  late WorkoutRepositoryDrift repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepositoryDrift(db);
  });

  tearDown(() => db.close());

  test('save then history round-trips the session graph', () async {
    await repo.save(_bench(1, DateTime(2026, 1, 1)));

    final history = await repo.history();
    expect(history, hasLength(1));
    final session = history.single;
    expect(session.entries.single.exerciseName, 'Жим лёжа');
    expect(session.entries.single.sets, hasLength(2));
    expect(session.totalVolume, 500); // warm-up excluded
  });

  test('history is ordered newest first', () async {
    await repo.save(_bench(1, DateTime(2026, 1, 1)));
    await repo.save(_bench(2, DateTime(2026, 2, 1)));

    final history = await repo.history();
    expect(history.first.startedAt.isAfter(history.last.startedAt), isTrue);
  });

  test('lastPerformance and personalRecord derive from persisted data',
      () async {
    await repo.save(_bench(1, DateTime(2026, 1, 1), weight: 100, reps: 5));
    await repo.save(_bench(2, DateTime(2026, 2, 1), weight: 110, reps: 3));

    final last = await repo.lastPerformance('bench');
    expect(last!.sets.last.weight, 110);

    final pr = await repo.personalRecord('bench');
    expect(pr!.bestWeight, 110);
    expect(pr.bestReps, 3);
  });
}
