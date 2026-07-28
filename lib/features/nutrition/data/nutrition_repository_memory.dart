import '../domain/entities/food_entry.dart';
import '../domain/entities/food_item.dart';
import '../domain/repositories/nutrition_repository.dart';

/// In-memory [NutritionRepository] for tests and non-persistent flows.
class NutritionRepositoryMemory implements NutritionRepository {
  final List<FoodEntry> _entries = [];
  final List<FoodItem> _customFoods = [];
  int _entryId = 0;
  int _foodId = 0;

  static DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<List<FoodEntry>> entriesForDay(DateTime day) async {
    final key = _dayKey(day);
    return _entries.where((e) => _dayKey(e.day) == key).toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<int> addEntry(FoodEntry entry) async {
    final id = ++_entryId;
    _entries.add(entry.copyWith(id: id));
    return id;
  }

  @override
  Future<void> removeEntry(int id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<FoodItem>> customFoods() async =>
      _customFoods.reversed.toList(growable: false);

  @override
  Future<String> saveCustomFood(FoodItem food) async {
    final idx = _customFoods.indexWhere((f) => f.id == food.id);
    if (idx != -1) {
      _customFoods[idx] = food;
      return food.id;
    }
    final id = 'custom:${++_foodId}';
    _customFoods.add(food.copyWith(id: id, isCustom: true));
    return id;
  }

  @override
  Future<void> deleteCustomFood(String id) async {
    _customFoods.removeWhere((f) => f.id == id);
  }

  @override
  Future<List<String>> recentFoods({int limit = 20}) async {
    final sorted = _entries.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final seen = <String>{};
    final names = <String>[];
    for (final e in sorted) {
      if (seen.add(e.name)) names.add(e.name);
      if (names.length >= limit) break;
    }
    return names;
  }
}
