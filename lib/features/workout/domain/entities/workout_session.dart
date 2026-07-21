import 'workout_exercise_entry.dart';

/// A workout session — the aggregate root for a single training day.
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.title,
    required this.startedAt,
    this.finishedAt,
    this.entries = const [],
  });

  final int id;
  final String title;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<WorkoutExerciseEntry> entries;

  bool get isFinished => finishedAt != null;

  /// Total tonnage across all working sets (kg).
  double get totalVolume => entries.fold(0, (sum, e) => sum + e.volume);

  int get totalSets => entries.fold(0, (sum, e) => sum + e.sets.length);

  int get completedSets => entries.fold(0, (sum, e) => sum + e.completedSets);

  /// Elapsed duration. Uses [finishedAt] when finished, otherwise [now].
  Duration elapsed([DateTime? now]) =>
      (finishedAt ?? now ?? DateTime.now()).difference(startedAt);

  WorkoutSession copyWith({
    String? title,
    DateTime? finishedAt,
    List<WorkoutExerciseEntry>? entries,
  }) {
    return WorkoutSession(
      id: id,
      title: title ?? this.title,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      entries: entries ?? this.entries,
    );
  }
}
