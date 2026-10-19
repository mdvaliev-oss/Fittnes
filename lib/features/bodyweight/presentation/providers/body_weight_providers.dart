import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/profile_providers.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../../data/body_weight_repository_drift.dart';
import '../../domain/body_weight_series.dart';
import '../../domain/entities/body_weight_entry.dart';
import '../../domain/repositories/body_weight_repository.dart';

/// Persistent body-weight repository (Drift/SQLite).
final bodyWeightRepositoryProvider = Provider<BodyWeightRepository>((ref) {
  return BodyWeightRepositoryDrift(ref.watch(appDatabaseProvider));
});

/// Every measurement, newest first. Invalidated by [BodyWeightActions].
final bodyWeightHistoryProvider = FutureProvider<List<BodyWeightEntry>>((ref) {
  return ref.watch(bodyWeightRepositoryProvider).all();
});

/// Latest value + 30-day change for cards; empty summary while loading.
final bodyWeightSummaryProvider = Provider<BodyWeightSummary>((ref) {
  final entries = ref.watch(bodyWeightHistoryProvider).valueOrNull ?? const [];
  return summarizeBodyWeight(entries);
});

/// Write-side helper: persists a measurement, mirrors it into the profile's
/// `weightKg` (so the profile always shows the current weight) and refreshes
/// every reader.
class BodyWeightActions {
  BodyWeightActions(this._ref);
  final Ref _ref;

  Future<BodyWeightEntry> add({required double kg, DateTime? at}) async {
    final entry = BodyWeightEntry(measuredAt: at ?? DateTime.now(), kg: kg);
    final saved = await _ref.read(bodyWeightRepositoryProvider).add(entry);
    await _syncProfile();
    _ref.invalidate(bodyWeightHistoryProvider);
    return saved;
  }

  Future<void> delete(int id) async {
    await _ref.read(bodyWeightRepositoryProvider).delete(id);
    await _syncProfile();
    _ref.invalidate(bodyWeightHistoryProvider);
  }

  Future<void> _syncProfile() async {
    final latest = await _ref.read(bodyWeightRepositoryProvider).latest();
    if (latest == null) return;
    final profile = _ref.read(profileProvider);
    if (profile.weightKg == latest.kg) return;
    await _ref
        .read(profileProvider.notifier)
        .update(profile.copyWith(weightKg: latest.kg));
  }
}

final bodyWeightActionsProvider =
    Provider<BodyWeightActions>(BodyWeightActions.new);
