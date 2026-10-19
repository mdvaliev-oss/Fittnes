import 'package:fittnes/features/exercises/domain/entities/exercise.dart';
import 'package:fittnes/features/exercises/domain/entities/exercise_enums.dart';
import 'package:fittnes/features/exercises/domain/entities/muscle.dart';
import 'package:fittnes/features/exercises/domain/entities/muscle_group.dart';
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
      expect(
        const ExerciseFilter(muscle: Muscle.triceps).matches(bench),
        isTrue,
      );
      expect(
        const ExerciseFilter(muscle: Muscle.quads).matches(bench),
        isFalse,
      );
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

    test('region chip matches primary muscles only', () {
      expect(
        const ExerciseFilter(group: MuscleGroup.chest).matches(bench),
        isTrue,
      );
      expect(
        const ExerciseFilter(group: MuscleGroup.arms).matches(bench),
        isFalse, // triceps is only secondary
      );
      expect(
        const ExerciseFilter(group: MuscleGroup.legs).matches(bench),
        isFalse,
      );
    });

    test('favorites facet only applies when the caller passes the set', () {
      const f = ExerciseFilter(favoritesOnly: true);
      expect(f.matches(bench), isTrue);
      expect(f.matches(bench, favorites: const {}), isFalse);
      expect(f.matches(bench, favorites: const {'bench'}), isTrue);
    });

    test('isBrowsing is false once a query or region narrows the catalog', () {
      expect(const ExerciseFilter().isBrowsing, isTrue);
      expect(
        const ExerciseFilter(equipment: Equipment.barbell).isBrowsing,
        isTrue,
      );
      expect(const ExerciseFilter(query: 'x').isBrowsing, isFalse);
      expect(const ExerciseFilter(group: MuscleGroup.back).isBrowsing, isFalse);
    });

    test('clearedFacets keeps search, region and favorites', () {
      const f = ExerciseFilter(
        query: 'жим',
        group: MuscleGroup.chest,
        equipment: Equipment.barbell,
        level: ExperienceLevel.beginner,
        favoritesOnly: true,
      );
      final cleared = f.clearedFacets();
      expect(cleared.query, 'жим');
      expect(cleared.group, MuscleGroup.chest);
      expect(cleared.favoritesOnly, isTrue);
      expect(cleared.activeFacetCount, 0);
    });

    test('every muscle belongs to exactly one region', () {
      for (final m in Muscle.values) {
        expect(
          MuscleGroup.values.where((g) => g.muscles.contains(m)).length,
          1,
          reason: m.name,
        );
      }
    });
  });
}
