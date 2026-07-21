/// Estimated one-rep-max (e1RM) formulas.
///
/// e1RM lets us compare sets of different weight×reps on one strength scale —
/// the basis for personal records and progression recommendations.
abstract final class OneRepMax {
  const OneRepMax._();

  /// Epley formula: `w * (1 + reps/30)`. Reasonable in the 1–12 rep range.
  static double epley(double weight, int reps) {
    if (reps <= 0 || weight <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  /// Brzycki formula: `w * 36 / (37 - reps)`. Slightly more conservative.
  static double brzycki(double weight, int reps) {
    if (reps <= 0 || weight <= 0 || reps >= 37) return 0;
    if (reps == 1) return weight;
    return weight * 36 / (37 - reps);
  }

  /// Inverse of Epley: target weight for [reps] at a given [e1rm].
  static double weightFor(double e1rm, int reps) {
    if (e1rm <= 0 || reps <= 0) return 0;
    if (reps == 1) return e1rm;
    return e1rm / (1 + reps / 30);
  }
}
