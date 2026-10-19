import '../domain/entities/body_weight_entry.dart';
import '../domain/repositories/body_weight_repository.dart';

/// In-memory [BodyWeightRepository] for tests and previews.
class BodyWeightRepositoryMemory implements BodyWeightRepository {
  BodyWeightRepositoryMemory([Iterable<BodyWeightEntry> seed = const []]) {
    for (final e in seed) {
      _entries.add(e.id == 0 ? e.copyWith(id: ++_nextId) : e);
      if (e.id > _nextId) _nextId = e.id;
    }
  }

  final List<BodyWeightEntry> _entries = [];
  int _nextId = 0;

  @override
  Future<List<BodyWeightEntry>> all() async {
    final sorted = [..._entries]..sort((a, b) {
        final byDate = b.measuredAt.compareTo(a.measuredAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    return sorted;
  }

  @override
  Future<BodyWeightEntry?> latest() async {
    final list = await all();
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<BodyWeightEntry> add(BodyWeightEntry entry) async {
    final saved = entry.copyWith(id: ++_nextId);
    _entries.add(saved);
    return saved;
  }

  @override
  Future<void> delete(int id) async {
    _entries.removeWhere((e) => e.id == id);
  }
}
