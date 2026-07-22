import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../exercises/domain/entities/exercise.dart';
import '../../domain/entities/set_type.dart';
import '../../domain/entities/workout_exercise_entry.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';

/// Owns the in-progress workout as immutable domain state.
///
/// State is `null` when no workout is active. All mutations rebuild the
/// session immutably so Riverpod diffing and undo stay trivial.
class ActiveWorkoutController extends Notifier<WorkoutSession?> {
  int _nextId = 1;

  int _id() => _nextId++;

  @override
  WorkoutSession? build() => null;

  bool get isActive => state != null;

  void start({String title = 'Тренировка'}) {
    state = WorkoutSession(
      id: _id(),
      title: title,
      startedAt: DateTime.now(),
    );
  }

  void addExercise(
    Exercise exercise, {
    double? recommendedWeight,
    int? recommendedReps,
  }) {
    addExerciseRef(
      exercise.id,
      exercise.name,
      recommendedWeight: recommendedWeight,
      recommendedReps: recommendedReps,
    );
  }

  /// Adds an exercise by id/name (used when seeding from a program), creating
  /// [sets] empty sets prefilled with the recommended weight/reps.
  void addExerciseRef(
    String exerciseId,
    String exerciseName, {
    double? recommendedWeight,
    int? recommendedReps,
    int sets = 1,
  }) {
    final session = state;
    if (session == null) return;
    final entry = WorkoutExerciseEntry(
      id: _id(),
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: [
        for (var i = 0; i < (sets < 1 ? 1 : sets); i++)
          WorkoutSet(
            id: _id(),
            weight: recommendedWeight,
            reps: recommendedReps,
          ),
      ],
    );
    state = session.copyWith(entries: [...session.entries, entry]);
  }

  void addSet(int entryId) {
    _updateEntry(entryId, (entry) {
      // Template the new set from the previous one for fast logging.
      final prev = entry.sets.isNotEmpty ? entry.sets.last : null;
      return entry.copyWith(
        sets: [
          ...entry.sets,
          WorkoutSet(
            id: _id(),
            weight: prev?.weight,
            reps: prev?.reps,
            type: prev?.type == SetType.warmup
                ? SetType.normal
                : (prev?.type ?? SetType.normal),
          ),
        ],
      );
    });
  }

  void updateSet(
    int entryId,
    int setId, {
    double? weight,
    int? reps,
    double? rpe,
    int? rir,
    SetType? type,
  }) {
    _updateSet(
      entryId,
      setId,
      (s) => s.copyWith(
        weight: weight,
        reps: reps,
        rpe: rpe,
        rir: rir,
        type: type,
      ),
    );
  }

  /// Sets or clears RPE / RIR (null clears the respective field).
  void setEffort(int entryId, int setId, {double? rpe, int? rir}) {
    _updateSet(
      entryId,
      setId,
      (s) => s.copyWith(
        rpe: rpe,
        rir: rir,
        clearRpe: rpe == null,
        clearRir: rir == null,
      ),
    );
  }

  void toggleSetComplete(int entryId, int setId) {
    _updateSet(entryId, setId, (s) => s.copyWith(isCompleted: !s.isCompleted));
  }

  void cycleSetType(int entryId, int setId) {
    const order = SetType.values;
    _updateSet(entryId, setId, (s) {
      final next = order[(s.type.index + 1) % order.length];
      return s.copyWith(type: next);
    });
  }

  void removeSet(int entryId, int setId) {
    _updateEntry(
      entryId,
      (entry) => entry.copyWith(
        sets: entry.sets.where((s) => s.id != setId).toList(),
      ),
    );
  }

  void removeEntry(int entryId) {
    final session = state;
    if (session == null) return;
    state = session.copyWith(
      entries: session.entries.where((e) => e.id != entryId).toList(),
    );
  }

  /// Groups [entryId] into a superset with the entry directly above it.
  void toggleSuperset(int entryId) {
    final session = state;
    if (session == null) return;
    final idx = session.entries.indexWhere((e) => e.id == entryId);
    if (idx <= 0) return;
    final current = session.entries[idx];
    if (current.isSuperset) {
      _updateEntry(entryId, (e) => e.copyWith(clearSuperset: true));
    } else {
      final above = session.entries[idx - 1];
      final group = above.supersetGroup ?? above.id;
      _updateEntry(above.id, (e) => e.copyWith(supersetGroup: group));
      _updateEntry(entryId, (e) => e.copyWith(supersetGroup: group));
    }
  }

  void setRest(int entryId, int seconds) {
    _updateEntry(entryId, (e) => e.copyWith(restSeconds: seconds));
  }

  /// Finalises the session and clears active state. Returns the finished
  /// session for the caller to persist; null if nothing was active.
  WorkoutSession? finish() {
    final session = state;
    if (session == null) return null;
    final finished = session.copyWith(finishedAt: DateTime.now());
    state = null;
    return finished;
  }

  void cancel() => state = null;

  // ── helpers ─────────────────────────────────────────────────────────
  void _updateEntry(
    int entryId,
    WorkoutExerciseEntry Function(WorkoutExerciseEntry) f,
  ) {
    final session = state;
    if (session == null) return;
    state = session.copyWith(
      entries: [
        for (final e in session.entries)
          if (e.id == entryId) f(e) else e,
      ],
    );
  }

  void _updateSet(int entryId, int setId, WorkoutSet Function(WorkoutSet) f) {
    _updateEntry(
      entryId,
      (entry) => entry.copyWith(
        sets: [
          for (final s in entry.sets)
            if (s.id == setId) f(s) else s,
        ],
      ),
    );
  }
}

final activeWorkoutControllerProvider =
    NotifierProvider<ActiveWorkoutController, WorkoutSession?>(
  ActiveWorkoutController.new,
);
