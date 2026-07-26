import 'package:fittnes/features/exercises/data/exercise_local_data_source.dart';
import 'package:fittnes/features/exercises/domain/entities/exercise.dart';
import 'package:fittnes/features/exercises/presentation/widgets/technique_animation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> all;

  setUpAll(() async {
    all = await ExerciseLocalDataSource(bundle: rootBundle).loadAll();
  });

  test('catalog is sizeable and every entry parses', () {
    expect(all.length, greaterThanOrEqualTo(70));
  });

  test('ids are unique', () {
    final ids = all.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every exercise has a name, description and instructions', () {
    for (final e in all) {
      expect(e.name.trim(), isNotEmpty, reason: '${e.id} name');
      expect(e.description.trim(), isNotEmpty, reason: '${e.id} description');
      expect(e.instructions, isNotEmpty, reason: '${e.id} instructions');
    }
  });

  test('every exercise maps at least one primary muscle', () {
    // Unmapped dataset muscle names are silently dropped by the DTO, so an
    // empty primary list means a typo in the seed.
    for (final e in all) {
      expect(e.primaryMuscles, isNotEmpty, reason: '${e.id} has no primary');
    }
  });

  test('every exercise resolves to a concrete movement pattern', () {
    // "generic" is the fallback; a curated catalog should rarely need it.
    final generic = all.where(
      (e) => MovementPattern.forExercise(e) == MovementPattern.generic,
    );
    expect(
      generic.length,
      lessThanOrEqualTo(3),
      reason: 'Too many generic: ${generic.map((e) => e.id).join(', ')}',
    );
  });
}
