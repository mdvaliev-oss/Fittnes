import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/workout_repository_drift.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/workout_exercise_entry.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/services/workout_stats.dart';

/// The app-lifetime SQLite database, closed with the container.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Persistent workout repository (Drift/SQLite).
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepositoryDrift(ref.watch(appDatabaseProvider));
});

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

/// Dashboard aggregates (workouts, weekly tonnage, streak, best e1RM).
final workoutStatsProvider = FutureProvider<WorkoutStats>((ref) async {
  final history = await ref.watch(workoutHistoryProvider.future);
  return computeWorkoutStats(history);
});

/// Emits once per second while an active workout screen is mounted, so the
/// elapsed-time header re-renders without storing time in the session.
final workoutTickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream<int>.periodic(const Duration(seconds: 1), (i) => i);
});
