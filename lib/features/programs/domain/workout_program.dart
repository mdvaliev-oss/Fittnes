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

  ProgramExercise copyWith({int? sets, int? targetMin, int? targetMax}) =>
      ProgramExercise(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        sets: sets ?? this.sets,
        targetMin: targetMin ?? this.targetMin,
        targetMax: targetMax ?? this.targetMax,
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets,
        'targetMin': targetMin,
        'targetMax': targetMax,
      };

  factory ProgramExercise.fromJson(Map<String, dynamic> j) => ProgramExercise(
        exerciseId: j['exerciseId'] as String,
        exerciseName: j['exerciseName'] as String,
        sets: (j['sets'] as num?)?.toInt() ?? 3,
        targetMin: (j['targetMin'] as num?)?.toInt() ?? 8,
        targetMax: (j['targetMax'] as num?)?.toInt() ?? 12,
      );
}

/// A single training day of a program.
class ProgramDay {
  const ProgramDay({required this.name, required this.exercises});
  final String name;
  final List<ProgramExercise> exercises;

  Map<String, dynamic> toJson() => {
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory ProgramDay.fromJson(Map<String, dynamic> j) => ProgramDay(
        name: j['name'] as String,
        exercises: ((j['exercises'] as List?) ?? const [])
            .map((e) => ProgramExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A structured training program (built-in or user-created).
class WorkoutProgram {
  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.level,
    required this.days,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String description;
  final ProgramCategory category;
  final ExperienceLevel level;
  final List<ProgramDay> days;
  final bool isCustom;

  int get dayCount => days.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'level': level.name,
        'isCustom': isCustom,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory WorkoutProgram.fromJson(Map<String, dynamic> j) => WorkoutProgram(
        id: j['id'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        category: ProgramCategory.values.asNameMap()[j['category']] ??
            ProgramCategory.fullBody,
        level: ExperienceLevel.values.asNameMap()[j['level']] ??
            ExperienceLevel.beginner,
        isCustom: j['isCustom'] as bool? ?? true,
        days: ((j['days'] as List?) ?? const [])
            .map((d) => ProgramDay.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}
