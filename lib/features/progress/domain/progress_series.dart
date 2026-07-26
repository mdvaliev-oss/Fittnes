import '../../workout/domain/entities/workout_session.dart';

/// A dated strength point (best estimated 1RM that day).
class StrengthPoint {
  const StrengthPoint(this.date, this.e1rm);
  final DateTime date;
  final double e1rm;
}

/// A dated tonnage point (session total volume).
class TonnagePoint {
  const TonnagePoint(this.date, this.tonnage);
  final DateTime date;
  final double tonnage;
}

/// A reference to an exercise present in history (for pickers).
class ExerciseRef {
  const ExerciseRef(this.id, this.name);
  final String id;
  final String name;
}

/// An exercise's best estimated 1RM ever, with the date it was hit.
class PersonalRecord {
  const PersonalRecord({
    required this.name,
    required this.e1rm,
    required this.date,
  });
  final String name;
  final double e1rm;
  final DateTime date;
}

/// Best-e1RM personal record per exercise across [history], strongest first.
List<PersonalRecord> personalRecords(List<WorkoutSession> history) {
  final rows = <PersonalRecord>[];
  for (final ex in exercisesInHistory(history)) {
    final series = strengthSeries(history, ex.id);
    if (series.isEmpty) continue;
    final best = series.reduce((a, b) => a.e1rm >= b.e1rm ? a : b);
    rows.add(PersonalRecord(name: ex.name, e1rm: best.e1rm, date: best.date));
  }
  rows.sort((a, b) => b.e1rm.compareTo(a.e1rm));
  return rows;
}

/// Best-e1RM-per-session series for [exerciseId], oldest → newest.
List<StrengthPoint> strengthSeries(
  List<WorkoutSession> history,
  String exerciseId,
) {
  final points = <StrengthPoint>[];
  for (final session in history) {
    var best = 0.0;
    for (final entry
        in session.entries.where((e) => e.exerciseId == exerciseId)) {
      final top = entry.topEstimatedOneRepMax;
      if (top > best) best = top;
    }
    if (best > 0) points.add(StrengthPoint(session.startedAt, best));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

/// Session tonnage series, oldest → newest.
List<TonnagePoint> tonnageSeries(List<WorkoutSession> history) {
  final points = [
    for (final s in history)
      if (s.totalVolume > 0) TonnagePoint(s.startedAt, s.totalVolume),
  ]..sort((a, b) => a.date.compareTo(b.date));
  return points;
}

/// Distinct exercises seen in history, most-trained first.
List<ExerciseRef> exercisesInHistory(List<WorkoutSession> history) {
  final counts = <String, int>{};
  final names = <String, String>{};
  for (final s in history) {
    for (final e in s.entries) {
      counts.update(e.exerciseId, (v) => v + 1, ifAbsent: () => 1);
      names[e.exerciseId] = e.exerciseName;
    }
  }
  final refs = counts.keys
      .map((id) => ExerciseRef(id, names[id] ?? id))
      .toList()
    ..sort((a, b) => counts[b.id]!.compareTo(counts[a.id]!));
  return refs;
}
