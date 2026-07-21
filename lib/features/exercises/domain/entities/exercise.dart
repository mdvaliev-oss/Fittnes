import 'exercise_enums.dart';
import 'muscle.dart';

/// Core domain entity describing a single exercise.
///
/// Pure Dart — no Flutter, Drift or JSON knowledge (Clean Architecture).
/// Immutable; equality is by [id].
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    this.altName,
    required this.description,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    this.stabilizers = const [],
    required this.category,
    required this.level,
    required this.equipment,
    this.mechanic,
    this.force,
    this.rangeOfMotion,
    this.instructions = const [],
    this.tips = const [],
    this.commonMistakes = const [],
    this.contraindications = const [],
    this.variations = const [],
    this.tempo,
    this.breathing,
    this.mediaUrl,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? altName;
  final String description;

  final List<Muscle> primaryMuscles;
  final List<Muscle> secondaryMuscles;
  final List<Muscle> stabilizers;

  final ExerciseCategory category;
  final ExperienceLevel level;
  final Equipment equipment;
  final Mechanic? mechanic;
  final ForceType? force;

  /// Description of the movement's range of motion.
  final String? rangeOfMotion;

  final List<String> instructions;
  final List<String> tips;
  final List<String> commonMistakes;
  final List<String> contraindications;
  final List<String> variations;

  /// e.g. "2-0-2" (eccentric-pause-concentric seconds).
  final String? tempo;
  final String? breathing;

  /// Looping technique media (WebP/GIF/MP4). May be a bundled asset path or URL.
  final String? mediaUrl;

  /// Static thumbnail used in list rows and as a media fallback.
  final String? imageUrl;

  /// All muscles with their activation level — consumed by [MuscleMap].
  Map<Muscle, MuscleActivation> get muscleActivation => {
        for (final m in stabilizers) m: MuscleActivation.stabilizer,
        for (final m in secondaryMuscles) m: MuscleActivation.secondary,
        for (final m in primaryMuscles) m: MuscleActivation.primary,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Exercise && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
