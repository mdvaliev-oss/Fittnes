import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workout/presentation/providers/workout_providers.dart';
import '../domain/progression_advice.dart';
import '../domain/progression_engine.dart';

/// Auto-progression advice for an exercise, derived from its last performance.
final recommendationProvider =
    FutureProvider.family<ProgressionAdvice, String>((ref, exerciseId) async {
  final last = await ref.watch(lastPerformanceProvider(exerciseId).future);
  return ProgressionEngine.recommend(last);
});
