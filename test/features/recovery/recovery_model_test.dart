import 'package:fittnes/features/exercises/domain/entities/muscle.dart';
import 'package:fittnes/features/recovery/domain/recovery_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 10, 12);

  group('computeMuscleRecovery', () {
    test('no events → fully recovered', () {
      final r = computeMuscleRecovery(const [], now: now);
      expect(r.fatigue, isEmpty);
      expect(r.overallReadiness, 1);
      expect(r.recoveryOf(Muscle.chest), 1);
    });

    test('a hard session today produces high fatigue', () {
      final r = computeMuscleRecovery([
        MuscleStimulusEvent(now, const {Muscle.chest: 6000}),
      ], now: now);
      // 1 - e^(-6000/6000) = 1 - e^-1 ≈ 0.632
      expect(r.fatigueOf(Muscle.chest), closeTo(0.632, 0.01));
    });

    test('older stimulus decays with the half-life', () {
      final today = computeMuscleRecovery([
        MuscleStimulusEvent(now, const {Muscle.chest: 6000}),
      ], now: now);
      final fourDaysAgo = computeMuscleRecovery([
        MuscleStimulusEvent(now.subtract(const Duration(hours: 96)),
            const {Muscle.chest: 6000}),
      ], now: now);

      expect(fourDaysAgo.fatigueOf(Muscle.chest),
          lessThan(today.fatigueOf(Muscle.chest)));
    });

    test('byFatigue orders muscles most-fatigued first', () {
      final r = computeMuscleRecovery([
        MuscleStimulusEvent(now, const {Muscle.chest: 8000, Muscle.biceps: 1000}),
      ], now: now);
      expect(r.byFatigue.first.key, Muscle.chest);
      expect(r.byFatigue.last.key, Muscle.biceps);
    });
  });
}
