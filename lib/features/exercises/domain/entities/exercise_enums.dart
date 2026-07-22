/// Difficulty / experience level required for an exercise.
enum ExperienceLevel {
  beginner('Начальный'),
  intermediate('Средний'),
  advanced('Продвинутый');

  const ExperienceLevel(this.label);
  final String label;

  static ExperienceLevel fromDataset(String raw) =>
      switch (raw.toLowerCase().trim()) {
        'beginner' => ExperienceLevel.beginner,
        'expert' => ExperienceLevel.advanced,
        _ => ExperienceLevel.intermediate,
      };
}

/// Movement pattern — compound uses multiple joints, isolation a single one.
enum Mechanic {
  compound('Базовое'),
  isolation('Изолирующее');

  const Mechanic(this.label);
  final String label;

  static Mechanic? fromDataset(String? raw) =>
      switch (raw?.toLowerCase().trim()) {
        'compound' => Mechanic.compound,
        'isolation' => Mechanic.isolation,
        _ => null,
      };
}

/// Primary force vector of the movement.
enum ForceType {
  push('Жим'),
  pull('Тяга'),
  static_('Статика');

  const ForceType(this.label);
  final String label;

  static ForceType? fromDataset(String? raw) =>
      switch (raw?.toLowerCase().trim()) {
        'push' => ForceType.push,
        'pull' => ForceType.pull,
        'static' => ForceType.static_,
        _ => null,
      };
}

/// Equipment / inventory needed. Used as a search facet.
enum Equipment {
  barbell('Штанга'),
  dumbbell('Гантели'),
  machine('Тренажёр'),
  cable('Блок'),
  bodyweight('Свой вес'),
  kettlebell('Гиря'),
  bands('Резина'),
  smithMachine('Смит'),
  ezBar('EZ-гриф'),
  other('Прочее');

  const Equipment(this.label);
  final String label;

  static Equipment fromDataset(String? raw) =>
      switch (raw?.toLowerCase().trim()) {
        'barbell' => Equipment.barbell,
        'dumbbell' => Equipment.dumbbell,
        'machine' => Equipment.machine,
        'cable' => Equipment.cable,
        'body only' || 'bodyweight' => Equipment.bodyweight,
        'kettlebells' || 'kettlebell' => Equipment.kettlebell,
        'bands' => Equipment.bands,
        'ez curl bar' => Equipment.ezBar,
        _ => Equipment.other,
      };
}

/// Training category / exercise type.
enum ExerciseCategory {
  strength('Сила'),
  hypertrophy('Гипертрофия'),
  powerlifting('Пауэрлифтинг'),
  olympic('Тяжёлая атлетика'),
  cardio('Кардио'),
  stretching('Растяжка'),
  plyometrics('Плиометрика');

  const ExerciseCategory(this.label);
  final String label;

  static ExerciseCategory fromDataset(String? raw) =>
      switch (raw?.toLowerCase().trim()) {
        'strength' => ExerciseCategory.strength,
        'powerlifting' => ExerciseCategory.powerlifting,
        'olympic weightlifting' => ExerciseCategory.olympic,
        'cardio' => ExerciseCategory.cardio,
        'stretching' => ExerciseCategory.stretching,
        'plyometrics' => ExerciseCategory.plyometrics,
        _ => ExerciseCategory.hypertrophy,
      };
}
