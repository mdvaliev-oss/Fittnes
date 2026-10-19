import '../entities/personal_record.dart';
import '../entities/workout_set.dart';

/// Decides whether a just-completed [set] beats the lifter's [record] for
/// that exercise — the trigger for the "new PR" celebration.
///
/// A set counts when it is a working set with weight and reps, and its
/// estimated 1RM exceeds the stored best by a hair (floating-point safe).
/// With no history at all there is nothing to beat, so the first-ever set is
/// not a "record" — celebrating every first set would cheapen the moment.
bool beatsPersonalRecord(WorkoutSet set, PersonalRecord? record) {
  if (!set.isFilled || !set.type.countsForVolume) return false;
  final e1rm = set.estimatedOneRepMax;
  if (e1rm <= 0 || record == null) return false;
  return e1rm > record.bestEstimatedOneRepMax + 0.01;
}
