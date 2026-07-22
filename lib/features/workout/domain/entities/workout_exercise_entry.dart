import 'workout_set.dart';

/// One exercise inside a workout session, holding its ordered sets.
class WorkoutExerciseEntry {
  const WorkoutExerciseEntry({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    this.sets = const [],
    this.note,
    this.supersetGroup,
    this.restSeconds = 120,
  });

  final int id;
  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSet> sets;
  final String? note;

  /// Exercises sharing the same non-null group id form a superset.
  final int? supersetGroup;

  /// Default rest between sets of this exercise, in seconds.
  final int restSeconds;

  double get volume => sets.fold(0, (sum, s) => sum + s.volume);

  int get completedSets => sets.where((s) => s.isCompleted).length;

  bool get isSuperset => supersetGroup != null;

  /// Best estimated 1RM across this entry's sets.
  double get topEstimatedOneRepMax => sets.fold(
        0.0,
        (best, s) => s.estimatedOneRepMax > best ? s.estimatedOneRepMax : best,
      );

  WorkoutExerciseEntry copyWith({
    List<WorkoutSet>? sets,
    String? note,
    int? supersetGroup,
    int? restSeconds,
    bool clearSuperset = false,
  }) {
    return WorkoutExerciseEntry(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets ?? this.sets,
      note: note ?? this.note,
      supersetGroup:
          clearSuperset ? null : (supersetGroup ?? this.supersetGroup),
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }
}
