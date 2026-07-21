import 'package:fittnes/features/progress/domain/progress_series.dart';
import 'package:fittnes/features/workout/domain/entities/workout_exercise_entry.dart';
import 'package:fittnes/features/workout/domain/entities/workout_session.dart';
import 'package:fittnes/features/workout/domain/entities/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSession _session(int id, DateTime day, String exId, double weight, int reps) {
  return WorkoutSession(
    id: id,
    title: 'S$id',
    startedAt: day,
    finishedAt: day,
    entries: [
      WorkoutExerciseEntry(
        id: id,
        exerciseId: exId,
        exerciseName: exId,
        sets: [WorkoutSet(id: id, weight: weight, reps: reps, isCompleted: true)],
      ),
    ],
  );
}

void main() {
  final history = [
    _session(2, DateTime(2026, 2, 1), 'bench', 110, 5),
    _session(1, DateTime(2026, 1, 1), 'bench', 100, 5),
    _session(3, DateTime(2026, 3, 1), 'squat', 140, 5),
  ];

  test('strengthSeries is sorted oldest → newest for one exercise', () {
    final series = strengthSeries(history, 'bench');
    expect(series.map((p) => p.date), [DateTime(2026, 1, 1), DateTime(2026, 2, 1)]);
    expect(series.first.e1rm < series.last.e1rm, isTrue);
  });

  test('tonnageSeries includes all sessions with volume, ascending', () {
    final series = tonnageSeries(history);
    expect(series, hasLength(3));
    expect(series.first.date.isBefore(series.last.date), isTrue);
  });

  test('exercisesInHistory returns distinct exercises', () {
    final refs = exercisesInHistory(history);
    expect(refs.map((r) => r.id).toSet(), {'bench', 'squat'});
  });
}
