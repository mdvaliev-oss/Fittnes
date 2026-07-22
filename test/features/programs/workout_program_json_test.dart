import 'dart:convert';

import 'package:fittnes/features/exercises/domain/entities/exercise_enums.dart';
import 'package:fittnes/features/programs/data/custom_program_repository.dart';
import 'package:fittnes/features/programs/domain/workout_program.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

WorkoutProgram _program() => const WorkoutProgram(
      id: 'custom-1',
      name: 'Моя PPL',
      description: 'desc',
      category: ProgramCategory.ppl,
      level: ExperienceLevel.advanced,
      isCustom: true,
      days: [
        ProgramDay(
          name: 'Push',
          exercises: [
            ProgramExercise(
              exerciseId: 'bench',
              exerciseName: 'Жим',
              sets: 4,
              targetMin: 6,
              targetMax: 10,
            ),
          ],
        ),
      ],
    );

void main() {
  test('WorkoutProgram round-trips through JSON', () {
    final decoded = WorkoutProgram.fromJson(
      jsonDecode(jsonEncode(_program().toJson())) as Map<String, dynamic>,
    );
    expect(decoded.id, 'custom-1');
    expect(decoded.category, ProgramCategory.ppl);
    expect(decoded.level, ExperienceLevel.advanced);
    expect(decoded.isCustom, isTrue);
    expect(decoded.days.single.name, 'Push');
    expect(decoded.days.single.exercises.single.sets, 4);
    expect(decoded.days.single.exercises.single.repScheme, '4 × 6–10');
  });

  group('CustomProgramRepository', () {
    test('save, list and delete', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = CustomProgramRepository(prefs);

      expect(repo.getAll(), isEmpty);
      await repo.save(_program());
      expect(repo.getAll(), hasLength(1));
      expect(repo.getAll().single.name, 'Моя PPL');

      // Saving the same id replaces rather than duplicates.
      await repo.save(_program());
      expect(repo.getAll(), hasLength(1));

      await repo.delete('custom-1');
      expect(repo.getAll(), isEmpty);
    });
  });
}
