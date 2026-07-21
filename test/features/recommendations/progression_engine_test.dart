import 'package:fittnes/features/recommendations/domain/progression_advice.dart';
import 'package:fittnes/features/recommendations/domain/progression_engine.dart';
import 'package:fittnes/features/workout/domain/entities/workout_exercise_entry.dart';
import 'package:fittnes/features/workout/domain/entities/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutExerciseEntry _entry(List<WorkoutSet> sets) => WorkoutExerciseEntry(
      id: 1,
      exerciseId: 'bench',
      exerciseName: 'Bench',
      sets: sets,
    );

WorkoutSet _set({required double weight, required int reps, double? rpe, int id = 1}) =>
    WorkoutSet(id: id, weight: weight, reps: reps, rpe: rpe, isCompleted: true);

void main() {
  group('ProgressionEngine', () {
    test('no history → start advice', () {
      final advice = ProgressionEngine.recommend(null);
      expect(advice.action, ProgressionAction.start);
    });

    test('no completed sets → finish sets', () {
      final advice = ProgressionEngine.recommend(_entry(const [
        WorkoutSet(id: 1, weight: 100, reps: 5, isCompleted: false),
      ]));
      expect(advice.action, ProgressionAction.finishSets);
    });

    test('top of range with reps in reserve → increase weight by increment', () {
      final advice = ProgressionEngine.recommend(
        _entry([_set(weight: 100, reps: 12, rpe: 7)]),
      );
      expect(advice.action, ProgressionAction.increaseWeight);
      expect(advice.suggestedWeight, 102.5);
    });

    test('top of range but maxed effort → keep weight', () {
      final advice = ProgressionEngine.recommend(
        _entry([_set(weight: 100, reps: 12, rpe: 10)]),
      );
      expect(advice.action, ProgressionAction.keepWeight);
      expect(advice.suggestedWeight, 100);
    });

    test('below range on high effort → reduce weight', () {
      final advice = ProgressionEngine.recommend(
        _entry([_set(weight: 100, reps: 5, rpe: 10)]),
      );
      expect(advice.action, ProgressionAction.reduceWeight);
      expect(advice.suggestedWeight, 90); // round(100 * 0.9)
    });

    test('within range with reserve → add a rep', () {
      final advice = ProgressionEngine.recommend(
        _entry([_set(weight: 100, reps: 9, rpe: 7)]),
      );
      expect(advice.action, ProgressionAction.addReps);
      expect(advice.suggestedReps, 10);
    });

    test('early systemic fatigue → more rest', () {
      final advice = ProgressionEngine.recommend(_entry([
        _set(weight: 100, reps: 9, rpe: 9.5, id: 1),
        _set(weight: 100, reps: 8, rpe: 10, id: 2),
      ]));
      expect(advice.action, ProgressionAction.addRest);
    });
  });
}
