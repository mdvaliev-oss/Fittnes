import '../entities/workout_session.dart';

/// Aggregate dashboard metrics derived from workout history.
class WorkoutStats {
  const WorkoutStats({
    required this.totalWorkouts,
    required this.weeklyTonnage,
    required this.streakDays,
    required this.bestE1rm,
  });

  final int totalWorkouts;

  /// Total tonnage (kg) across sessions in the last 7 days.
  final double weeklyTonnage;

  /// Consecutive calendar days (ending at the latest workout) with a session.
  final int streakDays;

  /// Best estimated 1RM ever recorded across all exercises.
  final double bestE1rm;

  static const empty = WorkoutStats(
    totalWorkouts: 0,
    weeklyTonnage: 0,
    streakDays: 0,
    bestE1rm: 0,
  );
}

/// Pure computation of [WorkoutStats] from [sessions] (finished only).
///
/// [now] is injectable for deterministic tests.
WorkoutStats computeWorkoutStats(
  List<WorkoutSession> sessions, {
  DateTime? now,
}) {
  if (sessions.isEmpty) return WorkoutStats.empty;
  final today = _dateOnly(now ?? DateTime.now());

  var weekly = 0.0;
  var bestE1rm = 0.0;
  final workoutDays = <DateTime>{};

  for (final s in sessions) {
    final day = _dateOnly(s.startedAt);
    workoutDays.add(day);
    if (today.difference(day).inDays < 7) weekly += s.totalVolume;
    for (final e in s.entries) {
      final top = e.topEstimatedOneRepMax;
      if (top > bestE1rm) bestE1rm = top;
    }
  }

  return WorkoutStats(
    totalWorkouts: sessions.length,
    weeklyTonnage: weekly,
    streakDays: _streak(workoutDays),
    bestE1rm: bestE1rm,
  );
}

/// Consecutive days ending at the most recent workout day.
int _streak(Set<DateTime> days) {
  if (days.isEmpty) return 0;
  final sorted = days.toList()..sort((a, b) => b.compareTo(a));
  var streak = 1;
  var cursor = sorted.first;
  for (final day in sorted.skip(1)) {
    if (cursor.difference(day).inDays == 1) {
      streak++;
      cursor = day;
    } else if (cursor.difference(day).inDays == 0) {
      continue;
    } else {
      break;
    }
  }
  return streak;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
