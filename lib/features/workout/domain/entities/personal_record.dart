/// Best recorded performance for a single exercise.
class PersonalRecord {
  const PersonalRecord({
    required this.exerciseId,
    required this.bestWeight,
    required this.bestReps,
    required this.bestEstimatedOneRepMax,
    required this.achievedAt,
  });

  final String exerciseId;

  /// Heaviest weight ever logged for a completed working set.
  final double bestWeight;
  final int bestReps;

  /// Highest estimated 1RM ever achieved.
  final double bestEstimatedOneRepMax;
  final DateTime achievedAt;
}
