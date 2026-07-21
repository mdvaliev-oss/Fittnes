import '../domain/entities/exercise.dart';
import '../domain/exercise_filter.dart';
import '../domain/repositories/exercise_repository.dart';
import 'exercise_local_data_source.dart';

/// In-memory implementation backed by the bundled catalog.
///
/// The catalog is read-only reference data, so an indexed in-memory cache is
/// both simpler and faster than a database for search/filter. User-generated
/// data (workout logs) will live in Drift from Module 2.
class ExerciseRepositoryImpl implements ExerciseRepository {
  ExerciseRepositoryImpl(this._local);

  final ExerciseLocalDataSource _local;

  List<Exercise>? _cache;
  Map<String, Exercise>? _byId;

  Future<List<Exercise>> _ensureLoaded() async {
    if (_cache != null) return _cache!;
    final list = await _local.loadAll()
      ..sort((a, b) => a.name.compareTo(b.name));
    _cache = list;
    _byId = {for (final e in list) e.id: e};
    return list;
  }

  @override
  Future<List<Exercise>> getAll() => _ensureLoaded();

  @override
  Future<List<Exercise>> search(ExerciseFilter filter) async {
    final all = await _ensureLoaded();
    if (filter.isEmpty) return all;
    return all.where(filter.matches).toList(growable: false);
  }

  @override
  Future<Exercise?> getById(String id) async {
    await _ensureLoaded();
    return _byId?[id];
  }
}
