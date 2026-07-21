import 'package:fittnes/features/exercises/data/models/exercise_dto.dart';
import 'package:fittnes/features/exercises/domain/entities/exercise_enums.dart';
import 'package:fittnes/features/exercises/domain/entities/muscle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseDto.fromJson', () {
    test('maps dataset fields onto the domain entity', () {
      final ex = ExerciseDto.fromJson({
        'id': 'squat',
        'name': 'Приседания',
        'altName': 'Back Squat',
        'description': 'desc',
        'primaryMuscles': ['quadriceps', 'glutes'],
        'secondaryMuscles': ['hamstrings'],
        'category': 'strength',
        'level': 'expert',
        'equipment': 'barbell',
        'mechanic': 'compound',
        'force': 'push',
        'instructions': ['a', 'b'],
        'tips': ['tip'],
      });

      expect(ex.id, 'squat');
      expect(ex.primaryMuscles, [Muscle.quads, Muscle.glutes]);
      expect(ex.secondaryMuscles, [Muscle.hamstrings]);
      expect(ex.level, ExperienceLevel.advanced); // "expert" -> advanced
      expect(ex.equipment, Equipment.barbell);
      expect(ex.mechanic, Mechanic.compound);
      expect(ex.force, ForceType.push);
      expect(ex.instructions, ['a', 'b']);
    });

    test('unknown muscles are dropped, missing lists default to empty', () {
      final ex = ExerciseDto.fromJson({
        'id': 'x',
        'name': 'X',
        'primaryMuscles': ['chest', 'unknown-muscle'],
        'category': 'strength',
        'level': 'beginner',
        'equipment': 'body only',
      });

      expect(ex.primaryMuscles, [Muscle.chest]);
      expect(ex.secondaryMuscles, isEmpty);
      expect(ex.equipment, Equipment.bodyweight);
      expect(ex.description, '');
    });

    test('muscleActivation layers primary over secondary over stabilizer', () {
      final ex = ExerciseDto.fromJson({
        'id': 'x',
        'name': 'X',
        'primaryMuscles': ['chest'],
        'secondaryMuscles': ['triceps'],
        'stabilizers': ['abdominals'],
        'category': 'strength',
        'level': 'beginner',
        'equipment': 'barbell',
      });

      final act = ex.muscleActivation;
      expect(act[Muscle.chest], MuscleActivation.primary);
      expect(act[Muscle.triceps], MuscleActivation.secondary);
      expect(act[Muscle.abs], MuscleActivation.stabilizer);
    });
  });
}
