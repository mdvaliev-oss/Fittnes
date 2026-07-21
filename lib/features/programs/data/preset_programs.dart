import '../../exercises/domain/entities/exercise_enums.dart';
import '../domain/workout_program.dart';

/// Built-in programs referencing the bundled exercise catalog by id.
abstract final class PresetPrograms {
  const PresetPrograms._();

  static const List<WorkoutProgram> all = [
    _fullBody,
    _upperLower,
    _ppl,
  ];

  static const _fullBody = WorkoutProgram(
    id: 'full-body-beginner',
    name: 'Full Body для новичка',
    description:
        'Три полнотелые тренировки в неделю на базовых движениях — оптимально для старта.',
    category: ProgramCategory.fullBody,
    level: ExperienceLevel.beginner,
    days: [
      ProgramDay(name: 'День A', exercises: [
        ProgramExercise(exerciseId: 'barbell-back-squat', exerciseName: 'Приседания со штангой', sets: 3, targetMin: 5, targetMax: 8),
        ProgramExercise(exerciseId: 'barbell-bench-press', exerciseName: 'Жим штанги лёжа', sets: 3, targetMin: 5, targetMax: 8),
        ProgramExercise(exerciseId: 'bent-over-row', exerciseName: 'Тяга штанги в наклоне', sets: 3, targetMin: 8, targetMax: 10),
        ProgramExercise(exerciseId: 'plank', exerciseName: 'Планка', sets: 3, targetMin: 1, targetMax: 1),
      ]),
      ProgramDay(name: 'День B', exercises: [
        ProgramExercise(exerciseId: 'romanian-deadlift', exerciseName: 'Румынская тяга', sets: 3, targetMin: 6, targetMax: 10),
        ProgramExercise(exerciseId: 'overhead-press', exerciseName: 'Жим штанги стоя', sets: 3, targetMin: 5, targetMax: 8),
        ProgramExercise(exerciseId: 'lat-pulldown', exerciseName: 'Тяга верхнего блока', sets: 3, targetMin: 8, targetMax: 12),
        ProgramExercise(exerciseId: 'standing-calf-raise', exerciseName: 'Подъём на носки стоя', sets: 3, targetMin: 10, targetMax: 15),
      ]),
    ],
  );

  static const _upperLower = WorkoutProgram(
    id: 'upper-lower',
    name: 'Upper / Lower',
    description:
        'Четыре тренировки: два верха и два низа. Баланс объёма и восстановления.',
    category: ProgramCategory.upperLower,
    level: ExperienceLevel.intermediate,
    days: [
      ProgramDay(name: 'Верх A', exercises: [
        ProgramExercise(exerciseId: 'barbell-bench-press', exerciseName: 'Жим штанги лёжа', sets: 4, targetMin: 6, targetMax: 8),
        ProgramExercise(exerciseId: 'bent-over-row', exerciseName: 'Тяга штанги в наклоне', sets: 4, targetMin: 8, targetMax: 10),
        ProgramExercise(exerciseId: 'overhead-press', exerciseName: 'Жим штанги стоя', sets: 3, targetMin: 8, targetMax: 10),
        ProgramExercise(exerciseId: 'barbell-curl', exerciseName: 'Подъём штанги на бицепс', sets: 3, targetMin: 10, targetMax: 12),
      ]),
      ProgramDay(name: 'Низ A', exercises: [
        ProgramExercise(exerciseId: 'barbell-back-squat', exerciseName: 'Приседания со штангой', sets: 4, targetMin: 5, targetMax: 8),
        ProgramExercise(exerciseId: 'romanian-deadlift', exerciseName: 'Румынская тяга', sets: 3, targetMin: 8, targetMax: 10),
        ProgramExercise(exerciseId: 'leg-press', exerciseName: 'Жим ногами', sets: 3, targetMin: 10, targetMax: 12),
        ProgramExercise(exerciseId: 'standing-calf-raise', exerciseName: 'Подъём на носки стоя', sets: 4, targetMin: 12, targetMax: 15),
      ]),
    ],
  );

  static const _ppl = WorkoutProgram(
    id: 'push-pull-legs',
    name: 'Push / Pull / Legs',
    description:
        'Классический трёхдневный сплит для гипертрофии с высоким недельным объёмом.',
    category: ProgramCategory.ppl,
    level: ExperienceLevel.advanced,
    days: [
      ProgramDay(name: 'Push', exercises: [
        ProgramExercise(exerciseId: 'barbell-bench-press', exerciseName: 'Жим штанги лёжа', sets: 4, targetMin: 6, targetMax: 10),
        ProgramExercise(exerciseId: 'overhead-press', exerciseName: 'Жим штанги стоя', sets: 3, targetMin: 8, targetMax: 10),
        ProgramExercise(exerciseId: 'incline-dumbbell-press', exerciseName: 'Жим гантелей в наклоне', sets: 3, targetMin: 10, targetMax: 12),
        ProgramExercise(exerciseId: 'dumbbell-lateral-raise', exerciseName: 'Махи гантелями в стороны', sets: 3, targetMin: 12, targetMax: 15),
        ProgramExercise(exerciseId: 'triceps-pushdown', exerciseName: 'Разгибания на блоке', sets: 3, targetMin: 12, targetMax: 15),
      ]),
      ProgramDay(name: 'Pull', exercises: [
        ProgramExercise(exerciseId: 'pull-up', exerciseName: 'Подтягивания', sets: 4, targetMin: 6, targetMax: 10),
        ProgramExercise(exerciseId: 'bent-over-row', exerciseName: 'Тяга штанги в наклоне', sets: 4, targetMin: 8, targetMax: 10),
        ProgramExercise(exerciseId: 'seated-cable-row', exerciseName: 'Горизонтальная тяга блока', sets: 3, targetMin: 10, targetMax: 12),
        ProgramExercise(exerciseId: 'face-pull', exerciseName: 'Тяга к лицу', sets: 3, targetMin: 15, targetMax: 20),
        ProgramExercise(exerciseId: 'barbell-curl', exerciseName: 'Подъём штанги на бицепс', sets: 3, targetMin: 10, targetMax: 12),
      ]),
      ProgramDay(name: 'Legs', exercises: [
        ProgramExercise(exerciseId: 'barbell-back-squat', exerciseName: 'Приседания со штангой', sets: 4, targetMin: 5, targetMax: 8),
        ProgramExercise(exerciseId: 'romanian-deadlift', exerciseName: 'Румынская тяга', sets: 3, targetMin: 8, targetMax: 10),
        ProgramExercise(exerciseId: 'leg-press', exerciseName: 'Жим ногами', sets: 3, targetMin: 10, targetMax: 12),
        ProgramExercise(exerciseId: 'hip-thrust', exerciseName: 'Ягодичный мост со штангой', sets: 3, targetMin: 10, targetMax: 12),
        ProgramExercise(exerciseId: 'standing-calf-raise', exerciseName: 'Подъём на носки стоя', sets: 4, targetMin: 12, targetMax: 15),
      ]),
    ],
  );
}
