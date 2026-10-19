import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/body_weight_entry.dart';
import '../domain/repositories/body_weight_repository.dart';

/// Drift/SQLite-backed [BodyWeightRepository].
class BodyWeightRepositoryDrift implements BodyWeightRepository {
  BodyWeightRepositoryDrift(this._db);

  final AppDatabase _db;

  BodyWeightEntry _map(BodyWeightRow r) =>
      BodyWeightEntry(id: r.id, measuredAt: r.measuredAt, kg: r.kg);

  @override
  Future<List<BodyWeightEntry>> all() async {
    final rows = await (_db.select(_db.bodyWeights)
          ..orderBy([
            (t) => OrderingTerm.desc(t.measuredAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
    return rows.map(_map).toList();
  }

  @override
  Future<BodyWeightEntry?> latest() async {
    final row = await (_db.select(_db.bodyWeights)
          ..orderBy([
            (t) => OrderingTerm.desc(t.measuredAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<BodyWeightEntry> add(BodyWeightEntry entry) async {
    final id = await _db.into(_db.bodyWeights).insert(
          BodyWeightsCompanion.insert(
            measuredAt: entry.measuredAt,
            kg: entry.kg,
          ),
        );
    return entry.copyWith(id: id);
  }

  @override
  Future<void> delete(int id) =>
      (_db.delete(_db.bodyWeights)..where((t) => t.id.equals(id))).go();
}
