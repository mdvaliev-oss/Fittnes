import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../workout/presentation/providers/workout_providers.dart';
import '../../domain/progress_series.dart';

/// Currently selected exercise id for the strength chart (null → first).
final selectedProgressExerciseProvider = StateProvider<String?>((ref) => null);

/// Personal records, memoized off workout history so they recompute only when
/// history changes — not on every widget rebuild (unit toggle, selection…).
final personalRecordsProvider = Provider<List<PersonalRecord>>((ref) {
  final history = ref.watch(workoutHistoryProvider).valueOrNull ?? const [];
  return personalRecords(history);
});
