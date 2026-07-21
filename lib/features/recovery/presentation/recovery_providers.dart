import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../exercises/domain/entities/muscle.dart';
import '../../exercises/presentation/providers/exercise_providers.dart';
import '../../workout/presentation/providers/workout_providers.dart';
import '../domain/recovery_model.dart';

/// Muscle recovery derived from the last 7 days of training.
///
/// Resolves each logged exercise to its worked muscles (primary ×1.0,
/// secondary ×0.4) via the catalog, then decays by recency.
final muscleRecoveryProvider = FutureProvider<MuscleRecovery>((ref) async {
  final history = await ref.watch(workoutHistoryProvider.future);
  final repo = ref.watch(exerciseRepositoryProvider);
  final cutoff = DateTime.now().subtract(const Duration(days: 7));

  final events = <MuscleStimulusEvent>[];
  for (final session in history) {
    if (session.startedAt.isBefore(cutoff)) continue;
    final stimulus = <Muscle, double>{};
    for (final entry in session.entries) {
      final vol = entry.volume;
      if (vol <= 0) continue;
      final exercise = await repo.getById(entry.exerciseId);
      if (exercise == null) continue;
      for (final m in exercise.primaryMuscles) {
        stimulus.update(m, (x) => x + vol, ifAbsent: () => vol);
      }
      for (final m in exercise.secondaryMuscles) {
        stimulus.update(m, (x) => x + vol * 0.4, ifAbsent: () => vol * 0.4);
      }
    }
    if (stimulus.isNotEmpty) {
      events.add(MuscleStimulusEvent(session.startedAt, stimulus));
    }
  }
  return computeMuscleRecovery(events);
});

/// Maps a fatigue value `0..1` onto the recovery heat color
/// (green → amber → red).
Color recoveryHeatColor(double fatigue) {
  final f = fatigue.clamp(0.0, 1.0).toDouble();
  final color = f < 0.5
      ? Color.lerp(AppColors.accent, AppColors.warning, f * 2)!
      : Color.lerp(AppColors.warning, AppColors.danger, (f - 0.5) * 2)!;
  return color.withOpacity(0.9);
}
