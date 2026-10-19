import 'package:fittnes/features/workout/domain/entities/personal_record.dart';
import 'package:fittnes/features/workout/domain/entities/set_type.dart';
import 'package:fittnes/features/workout/domain/entities/workout_set.dart';
import 'package:fittnes/features/workout/domain/services/pr_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final record = PersonalRecord(
    exerciseId: 'bench',
    bestWeight: 100,
    bestReps: 5,
    bestEstimatedOneRepMax: 116.67, // Epley 100×5
    achievedAt: DateTime(2026, 1, 1),
  );

  test('a heavier estimated 1RM beats the record', () {
    const set = WorkoutSet(id: 1, weight: 105, reps: 5);
    expect(beatsPersonalRecord(set, record), isTrue);
  });

  test('matching or lighter sets do not', () {
    const same = WorkoutSet(id: 1, weight: 100, reps: 5);
    const lighter = WorkoutSet(id: 2, weight: 90, reps: 5);
    expect(beatsPersonalRecord(same, record), isFalse);
    expect(beatsPersonalRecord(lighter, record), isFalse);
  });

  test('warm-ups and unfilled sets never count', () {
    const warmup =
        WorkoutSet(id: 1, weight: 200, reps: 5, type: SetType.warmup);
    const unfilled = WorkoutSet(id: 2, weight: 200);
    expect(beatsPersonalRecord(warmup, record), isFalse);
    expect(beatsPersonalRecord(unfilled, record), isFalse);
  });

  test('no history means nothing to beat', () {
    const set = WorkoutSet(id: 1, weight: 100, reps: 5);
    expect(beatsPersonalRecord(set, null), isFalse);
  });
}
