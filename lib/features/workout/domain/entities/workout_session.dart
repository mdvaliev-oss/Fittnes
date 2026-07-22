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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
        id: (j['id'] as num).toInt(),
        title: j['title'] as String? ?? 'Тренировка',
        startedAt: DateTime.parse(j['startedAt'] as String),
        finishedAt: j['finishedAt'] == null
            ? null
            : DateTime.parse(j['finishedAt'] as String),
        entries: ((j['entries'] as List?) ?? const [])
            .map(
                (e) => WorkoutExerciseEntry.fromJson(e as Map<String, dynamic>),)
            .toList(),
      );
}
