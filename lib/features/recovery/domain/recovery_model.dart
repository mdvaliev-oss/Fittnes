import 'dart:math' as math;

import '../../exercises/domain/entities/muscle.dart';

/// Muscle stimulus accumulated in one session (weighted training volume).
class MuscleStimulusEvent {
  const MuscleStimulusEvent(this.date, this.stimulus);
  final DateTime date;
  final Map<Muscle, double> stimulus;
}

/// Per-muscle recovery state, derived from recent stimulus with time decay.
class MuscleRecovery {
  const MuscleRecovery(this.fatigue);

  /// Fatigue per muscle in `0..1` (1 = fully fatigued). Absent → fresh.
  final Map<Muscle, double> fatigue;

  double fatigueOf(Muscle m) => fatigue[m] ?? 0;
  double recoveryOf(Muscle m) => 1 - fatigueOf(m);

  /// Whole-body readiness `0..1` averaged over stimulated muscles.
  double get overallReadiness {
    if (fatigue.isEmpty) return 1;
    final avg = fatigue.values.reduce((a, b) => a + b) / fatigue.length;
    return 1 - avg;
  }

  /// Muscles ordered most-fatigued first.
  List<MapEntry<Muscle, double>> get byFatigue =>
      fatigue.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}

/// Computes [MuscleRecovery] from stimulus [events].
///
/// Each event decays with a ~[halfLifeHours] half-life (protein synthesis /
/// soreness window); accumulated load saturates to fatigue via `1 - e^(-L/scale)`.
/// Pure and deterministic ([now] injectable for tests).
MuscleRecovery computeMuscleRecovery(
  List<MuscleStimulusEvent> events, {
  DateTime? now,
  double halfLifeHours = 48,
  double scale = 6000,
}) {
  final ref = now ?? DateTime.now();
  final decayed = <Muscle, double>{};

  for (final e in events) {
    final hours = ref.difference(e.date).inMinutes / 60.0;
    if (hours < 0) continue;
    final factor = math.pow(0.5, hours / halfLifeHours).toDouble();
    e.stimulus.forEach((m, v) {
      decayed.update(m, (x) => x + v * factor, ifAbsent: () => v * factor);
    });
  }

  final fatigue = <Muscle, double>{};
  decayed.forEach((m, load) {
    fatigue[m] = (1 - math.exp(-load / scale)).clamp(0.0, 1.0).toDouble();
  });
  return MuscleRecovery(fatigue);
}
