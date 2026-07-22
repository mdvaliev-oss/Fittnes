import 'dart:convert';

import 'package:fittnes/features/workout/domain/entities/set_type.dart';
import 'package:fittnes/features/workout/domain/entities/workout_exercise_entry.dart';
import 'package:fittnes/features/workout/domain/entities/workout_session.dart';
import 'package:fittnes/features/workout/domain/entities/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WorkoutSession round-trips through JSON', () {
    final session = WorkoutSession(
      id: 7,
      title: 'Push Day',
      startedAt: DateTime(2026, 3, 1, 10),
      finishedAt: DateTime(2026, 3, 1, 11),
      entries: [
        const WorkoutExerciseEntry(
          id: 1,
          exerciseId: 'bench',
          exerciseName: 'Жим лёжа',
          restSeconds: 150,
          sets: [
            WorkoutSet(id: 1, weight: 40, reps: 10, type: SetType.warmup),
            WorkoutSet(id: 2, weight: 100, reps: 5, rpe: 8, isCompleted: true),
          ],
        ),
      ],
    );

    final decoded = WorkoutSession.fromJson(
      jsonDecode(jsonEncode(session.toJson())) as Map<String, dynamic>,
    );

    expect(decoded.id, 7);
    expect(decoded.title, 'Push Day');
    expect(decoded.finishedAt, DateTime(2026, 3, 1, 11));
    expect(decoded.entries.single.restSeconds, 150);
    final sets = decoded.entries.single.sets;
    expect(sets, hasLength(2));
    expect(sets.first.type, SetType.warmup);
    expect(sets.last.rpe, 8);
    expect(decoded.totalVolume, 500); // warm-up excluded
  });
}
