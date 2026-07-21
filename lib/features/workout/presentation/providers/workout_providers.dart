import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/workout_repository_memory.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/workout_exercise_entry.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/workout_repository.dart';

/// Single app-lifetime repository instance (in-memory for 2A, Drift for 2B).
final workoutRepositoryProvider =
    Provider<WorkoutRepository>((ref) => WorkoutRepositoryMemory());

/// Finished sessions, most recent first. Invalidate after [save].
final workoutHistoryProvider = FutureProvider<List<WorkoutSession>>((ref) {
  return ref.watch(workoutRepositoryProvider).history();
});

/// Last logged entry for an exercise — "last time" + recommended weight.
final lastPerformanceProvider =
    FutureProvider.family<WorkoutExerciseEntry?, String>((ref, exerciseId) {
  ref.watch(workoutHistoryProvider); // refresh when history changes
  return ref.watch(workoutRepositoryProvider).lastPerformance(exerciseId);
});

/// Best-ever performance for an exercise.
final personalRecordProvider =
    FutureProvider.family<PersonalRecord?, String>((ref, exerciseId) {
  ref.watch(workoutHistoryProvider);
  return ref.watch(workoutRepositoryProvider).personalRecord(exerciseId);
});

/// Emits once per second while an active workout screen is mounted, so the
/// elapsed-time header re-renders without storing time in the session.
final workoutTickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream<int>.periodic(const Duration(seconds: 1), (i) => i);
});
