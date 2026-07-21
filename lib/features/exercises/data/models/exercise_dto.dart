import '../../domain/entities/exercise.dart';
import '../../domain/entities/exercise_enums.dart';
import '../../domain/entities/muscle.dart';

/// Maps the bundled seed JSON (and, later, the full free-exercise-db import)
/// into domain [Exercise] objects.
///
/// Kept separate from the entity so the domain stays free of JSON concerns.
abstract final class ExerciseDto {
  const ExerciseDto._();

  static Exercise fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      altName: json['altName'] as String?,
      description: (json['description'] as String?) ?? '',
      primaryMuscles: _muscles(json['primaryMuscles']),
      secondaryMuscles: _muscles(json['secondaryMuscles']),
      stabilizers: _muscles(json['stabilizers']),
      category: ExerciseCategory.fromDataset(json['category'] as String?),
      level: ExperienceLevel.fromDataset((json['level'] as String?) ?? ''),
      equipment: Equipment.fromDataset(json['equipment'] as String?),
      mechanic: Mechanic.fromDataset(json['mechanic'] as String?),
      force: ForceType.fromDataset(json['force'] as String?),
      rangeOfMotion: json['rangeOfMotion'] as String?,
      instructions: _strings(json['instructions']),
      tips: _strings(json['tips']),
      commonMistakes: _strings(json['commonMistakes']),
      contraindications: _strings(json['contraindications']),
      variations: _strings(json['variations']),
      tempo: json['tempo'] as String?,
      breathing: json['breathing'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  static List<Muscle> _muscles(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => Muscle.fromDataset(e.toString()))
        .whereType<Muscle>()
        .toList(growable: false);
  }

  static List<String> _strings(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList(growable: false);
  }
}
