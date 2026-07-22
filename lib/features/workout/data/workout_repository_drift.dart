import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/personal_record.dart';
import '../domain/entities/set_type.dart';
import '../domain/entities/workout_exercise_entry.dart';
import '../domain/entities/workout_session.dart';
import '../domain/entities/workout_set.dart';
import '../domain/repositories/workout_repository.dart';

/// Drift/SQLite-backed [WorkoutRepository] — the persistent implementation.
///
/// Writes go through Drift transactions; derived queries (last performance,
/// PRs) are computed in Dart over the assembled history to keep the SQL simple
/// and identical in behaviour to the in-memory version.
class WorkoutRepositoryDrift implements WorkoutRepository {
  WorkoutRepositoryDrift(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(WorkoutSession session) async {
    await _db.transaction(() async {
      final sessionId = await _db.into(_db.sessions).insert(
            SessionsCompanion.insert(
              title: session.title,
              startedAt: session.startedAt,
              finishedAt: Value(session.finishedAt),
            ),
          );

      for (var i = 0; i < session.entries.length; i++) {
        final entry = session.entries[i];
        final entryId = await _db.into(_db.entries).insert(
              EntriesCompanion.insert(
                sessionId: sessionId,
                exerciseId: entry.exerciseId,
                exerciseName: entry.exerciseName,
                position: i,
                supersetGroup: Value(entry.supersetGroup),
                restSeconds: Value(entry.restSeconds),
                note: Value(entry.note),
              ),
            );

        for (var j = 0; j < entry.sets.length; j++) {
          final s = entry.sets[j];
          await _db.into(_db.setEntries).insert(
                SetEntriesCompanion.insert(
                  entryId: entryId,
                  position: j,
                  type: Value(s.type.index),
                  weight: Value(s.weight),
                  reps: Value(s.reps),
                  rpe: Value(s.rpe),
                  rir: Value(s.rir),
                  isCompleted: Value(s.isCompleted),
                  note: Value(s.note),
                ),
              );
        }
      }
    });
  }

  @override
  Future<List<WorkoutSession>> history() async {
    final sessionRows = await (_db.select(_db.sessions)
          ..where((t) => t.finishedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    if (sessionRows.isEmpty) return const [];

    final sessionIds = sessionRows.map((s) => s.id).toList();
    final entryRows = await (_db.select(_db.entries)
          ..where((t) => t.sessionId.isIn(sessionIds))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();

    final entryIds = entryRows.map((e) => e.id).toList();
    final setRows = entryIds.isEmpty
        ? const <SetRow>[]
        : await (_db.select(_db.setEntries)
              ..where((t) => t.entryId.isIn(entryIds))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();

    final setsByEntry = <int, List<WorkoutSet>>{};
    for (final r in setRows) {
      (setsByEntry[r.entryId] ??= []).add(_toSet(r));
    }

    final entriesBySession = <int, List<WorkoutExerciseEntry>>{};
    for (final e in entryRows) {
      (entriesBySession[e.sessionId] ??= [])
          .add(_toEntry(e, setsByEntry[e.id] ?? const []));
    }

    return [
      for (final s in sessionRows)
        _toSession(s, entriesBySession[s.id] ?? const []),
    ];
  }

  @override
  Future<WorkoutExerciseEntry?> lastPerformance(String exerciseId) async {
    for (final session in await history()) {
      final match = session.entries
          .where((e) => e.exerciseId == exerciseId && e.sets.isNotEmpty);
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }

  @override
  Future<PersonalRecord?> personalRecord(String exerciseId) async {
    PersonalRecord? best;
    for (final session in await history()) {
      for (final entry
          in session.entries.where((e) => e.exerciseId == exerciseId)) {
        for (final set in entry.sets) {
          if (!set.isCompleted ||
              !set.isFilled ||
              set.estimatedOneRepMax <= 0) {
            continue;
          }
          if (best == null ||
              set.estimatedOneRepMax > best.bestEstimatedOneRepMax) {
            best = PersonalRecord(
              exerciseId: exerciseId,
              bestWeight: set.weight!,
              bestReps: set.reps!,
              bestEstimatedOneRepMax: set.estimatedOneRepMax,
              achievedAt: session.finishedAt ?? session.startedAt,
            );
          }
        }
      }
    }
    return best;
  }

  // ── mappers ─────────────────────────────────────────────────────────
  WorkoutSet _toSet(SetRow r) => WorkoutSet(
        id: r.id,
        weight: r.weight,
        reps: r.reps,
        rpe: r.rpe,
        rir: r.rir,
        type: _setType(r.type),
        isCompleted: r.isCompleted,
        note: r.note,
      );

  WorkoutExerciseEntry _toEntry(EntryRow e, List<WorkoutSet> sets) =>
      WorkoutExerciseEntry(
        id: e.id,
        exerciseId: e.exerciseId,
        exerciseName: e.exerciseName,
        sets: sets,
        note: e.note,
        supersetGroup: e.supersetGroup,
        restSeconds: e.restSeconds,
      );

  WorkoutSession _toSession(SessionRow s, List<WorkoutExerciseEntry> entries) =>
      WorkoutSession(
        id: s.id,
        title: s.title,
        startedAt: s.startedAt,
        finishedAt: s.finishedAt,
        entries: entries,
      );

  SetType _setType(int index) => (index >= 0 && index < SetType.values.length)
      ? SetType.values[index]
      : SetType.normal;
}
