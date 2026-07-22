import '../../exercises/domain/entities/exercise_enums.dart'
    show ExperienceLevel;

enum ProgramCategory {
  fullBody('Full Body'),
  upperLower('Upper / Lower'),
  ppl('Push / Pull / Legs'),
  broSplit('Bro Split'),
  powerlifting('Powerlifting'),
  bodybuilding('Bodybuilding');

  const ProgramCategory(this.label);
  final String label;
}

/// A prescribed exercise within a program day.
class ProgramExercise {
  const ProgramExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.sets = 3,
    this.targetMin = 8,
    this.targetMax = 12,
  });

  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int targetMin;
  final int targetMax;

  String get repScheme => '$sets × $targetMin–$targetMax';
}

/// A single training day of a program.
class ProgramDay {
  const ProgramDay({required this.name, required this.exercises});
  final String name;
  final List<ProgramExercise> exercises;
}

/// A structured training program.
class WorkoutProgram {
  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.level,
    required this.days,
  });

  final String id;
  final String name;
  final String description;
  final ProgramCategory category;
  final ExperienceLevel level;
  final List<ProgramDay> days;

  int get dayCount => days.length;
}
