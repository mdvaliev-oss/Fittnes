import 'package:fittnes/features/exercises/domain/entities/exercise.dart';
import 'package:fittnes/features/exercises/domain/entities/exercise_enums.dart';
import 'package:fittnes/features/exercises/domain/entities/muscle.dart';
import 'package:fittnes/features/exercises/domain/exercise_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _bench() => const Exercise(
      id: 'bench',
      name: 'Жим штанги лёжа',
      altName: 'Bench Press',
      description: '',
      primaryMuscles: [Muscle.chest],
      secondaryMuscles: [Muscle.triceps],
      category: ExerciseCategory.strength,
      level: ExperienceLevel.intermediate,
      equipment: Equipment.barbell,
    );

void main() {
  group('ExerciseFilter', () {
    final bench = _bench();

    test('empty filter matches everything', () {
      expect(const ExerciseFilter().matches(bench), isTrue);
      expect(const ExerciseFilter().isEmpty, isTrue);
    });

    test('query matches name and altName case-insensitively', () {
      expect(const ExerciseFilter(query: 'жим').matches(bench), isTrue);
      expect(const ExerciseFilter(query: 'BENCH').matches(bench), isTrue);
      expect(const ExerciseFilter(query: 'присед').matches(bench), isFalse);
    });

    test('muscle facet checks primary and secondary', () {
      expect(const ExerciseFilter(muscle: Muscle.chest).matches(bench), isTrue);
      expect(const ExerciseFilter(muscle: Muscle.triceps).matches(bench), isTrue);
      expect(const ExerciseFilter(muscle: Muscle.quads).matches(bench), isFalse);
    });

    test('equipment and level facets', () {
      expect(
        const ExerciseFilter(equipment: Equipment.barbell).matches(bench),
        isTrue,
      );
      expect(
        const ExerciseFilter(equipment: Equipment.dumbbell).matches(bench),
        isFalse,
      );
      expect(
        const ExerciseFilter(level: ExperienceLevel.beginner).matches(bench),
        isFalse,
      );
    });

    test('toggle clears the facet when the same value is toggled again', () {
      const base = ExerciseFilter();
      final withMuscle = base.toggleMuscle(Muscle.chest);
      expect(withMuscle.muscle, Muscle.chest);
      expect(withMuscle.toggleMuscle(Muscle.chest).muscle, isNull);
    });

    test('activeFacetCount counts only set facets', () {
      const f = ExerciseFilter(
        muscle: Muscle.chest,
        equipment: Equipment.barbell,
      );
      expect(f.activeFacetCount, 2);
    });
  });
}
