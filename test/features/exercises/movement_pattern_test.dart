import 'package:fittnes/features/exercises/domain/entities/exercise.dart';
import 'package:fittnes/features/exercises/domain/entities/exercise_enums.dart';
import 'package:fittnes/features/exercises/domain/entities/muscle.dart';
import 'package:fittnes/features/exercises/presentation/widgets/technique_animation.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _ex({
  required String name,
  String? altName,
  List<Muscle> primary = const [Muscle.chest],
  ForceType? force,
  Equipment equipment = Equipment.barbell,
}) =>
    Exercise(
      id: name,
      name: name,
      altName: altName,
      description: '',
      primaryMuscles: primary,
      category: ExerciseCategory.strength,
      level: ExperienceLevel.intermediate,
      equipment: equipment,
      force: force,
    );

void main() {
  group('MovementPattern.forExercise', () {
    test('keyword match wins over anatomy fallback', () {
      // Named a squat even though primary muscle would also suggest squat.
      expect(
        MovementPattern.forExercise(_ex(name: 'Присед со штангой')),
        MovementPattern.squat,
      );
      expect(
        MovementPattern.forExercise(_ex(name: 'Становая тяга')),
        MovementPattern.hinge,
      );
      expect(
        MovementPattern.forExercise(_ex(name: 'Подъём на бицепс')),
        MovementPattern.curl,
      );
      expect(
        MovementPattern.forExercise(_ex(name: 'Тяга верхнего блока')),
        MovementPattern.verticalPull,
      );
      expect(
        MovementPattern.forExercise(_ex(name: 'Подъём на носки')),
        MovementPattern.calfRaise,
      );
    });

    test('English altName is considered', () {
      expect(
        MovementPattern.forExercise(
          _ex(name: 'Жим лёжа', altName: 'Bench Press'),
        ),
        MovementPattern.horizontalPress,
      );
    });

    test('falls back to primary muscle + force when no keyword', () {
      expect(
        MovementPattern.forExercise(
          _ex(name: 'Упражнение X', primary: [Muscle.chest]),
        ),
        MovementPattern.horizontalPress,
      );
      expect(
        MovementPattern.forExercise(
          _ex(name: 'Упражнение Y', primary: [Muscle.sideDelts]),
        ),
        MovementPattern.lateralRaise,
      );
      expect(
        MovementPattern.forExercise(
          _ex(
            name: 'Упражнение Z',
            primary: [Muscle.quads],
            force: ForceType.push,
          ),
        ),
        MovementPattern.squat,
      );
    });

    test('generic when nothing matches', () {
      expect(
        MovementPattern.forExercise(
          _ex(name: 'Упражнение', primary: [Muscle.forearms]),
        ),
        MovementPattern.generic,
      );
    });
  });
}
