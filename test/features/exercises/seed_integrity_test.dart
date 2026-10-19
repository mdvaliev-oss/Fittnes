import 'package:fittnes/features/exercises/data/exercise_local_data_source.dart';
import 'package:fittnes/features/exercises/domain/entities/exercise.dart';
import 'package:fittnes/features/exercises/domain/entities/exercise_enums.dart';
import 'package:fittnes/features/exercises/domain/entities/movement_pattern.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> all;

  setUpAll(() async {
    all = await ExerciseLocalDataSource(bundle: rootBundle).loadAll();
  });

  test('catalog is sizeable and every entry parses', () {
    expect(all.length, greaterThanOrEqualTo(120));
  });

  test('ids are unique', () {
    final ids = all.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every exercise has a full description and instructions', () {
    for (final e in all) {
      expect(e.name.trim(), isNotEmpty, reason: '${e.id} name');
      expect(
        e.description.trim().length,
        greaterThanOrEqualTo(80),
        reason: '${e.id} description is too thin',
      );
      expect(
        e.instructions.length,
        greaterThanOrEqualTo(3),
        reason: '${e.id} instructions',
      );
      expect(e.tips, isNotEmpty, reason: '${e.id} tips');
      expect(e.commonMistakes, isNotEmpty, reason: '${e.id} mistakes');
    }
  });

  test('every exercise maps at least one primary muscle', () {
    // Unmapped dataset muscle names are silently dropped by the DTO, so an
    // empty primary list means a typo in the seed.
    for (final e in all) {
      expect(e.primaryMuscles, isNotEmpty, reason: '${e.id} has no primary');
    }
  });

  test('every exercise states its movement pattern explicitly', () {
    for (final e in all) {
      expect(e.patternOverride, isNotNull, reason: '${e.id} has no pattern');
      expect(e.pattern, isNot(MovementPattern.generic), reason: e.id);
    }
  });

  test('equipment and level never fall back to a default by accident', () {
    // `other` / `intermediate` are the DTO fallbacks for unknown strings, so a
    // curated seed should only hit them on purpose (none do today).
    final other = all.where((e) => e.equipment == Equipment.other);
    expect(other, isEmpty, reason: other.map((e) => e.id).join(', '));
    expect(
      all.where((e) => e.level == ExperienceLevel.advanced).length,
      greaterThanOrEqualTo(8),
    );
  });

  test('catalog covers every muscle group with several exercises', () {
    final byMuscle = <String, int>{};
    for (final e in all) {
      for (final m in e.primaryMuscles) {
        byMuscle[m.name] = (byMuscle[m.name] ?? 0) + 1;
      }
    }
    for (final group in ['chest', 'lats', 'quads', 'hamstrings', 'glutes']) {
      expect(byMuscle[group] ?? 0, greaterThanOrEqualTo(8), reason: group);
    }
  });
}
