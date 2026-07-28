import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/food_entry.dart';
import '../domain/entities/food_item.dart';
import '../domain/entities/meal_type.dart';
import '../domain/repositories/nutrition_repository.dart';

/// Custom-food ids are stored as `custom:<rowId>` so they never collide with
/// bundled catalog ids.
const _customPrefix = 'custom:';

/// Drift/SQLite-backed [NutritionRepository].
class NutritionRepositoryDrift implements NutritionRepository {
  NutritionRepositoryDrift(this._db);

  final AppDatabase _db;

  static DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<List<FoodEntry>> entriesForDay(DateTime day) async {
    final start = _dayKey(day);
    final end = start.add(const Duration(days: 1));
    final rows = await (_db.select(_db.foodEntries)
          ..where(
            (t) =>
                t.day.isBiggerOrEqualValue(start) &
                t.day.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_toEntry).toList(growable: false);
  }

  @override
  Future<List<FoodEntry>> allEntries() async {
    final rows = await (_db.select(_db.foodEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_toEntry).toList(growable: false);
  }

  @override
  Future<int> addEntry(FoodEntry entry) {
    return _db.into(_db.foodEntries).insert(
          FoodEntriesCompanion.insert(
            day: _dayKey(entry.day),
            meal: entry.meal.index,
            name: entry.name,
            grams: entry.grams,
            kcal: entry.kcal,
            protein: entry.protein,
            fat: entry.fat,
            carb: entry.carb,
            createdAt: entry.createdAt,
          ),
        );
  }

  @override
  Future<void> removeEntry(int id) async {
    await (_db.delete(_db.foodEntries)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<List<FoodItem>> customFoods() async {
    final rows = await (_db.select(_db.customFoods)
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
    return rows.map(_toFood).toList(growable: false);
  }

  @override
  Future<String> saveCustomFood(FoodItem food) async {
    final existing = _rowIdOf(food.id);
    final companion = CustomFoodsCompanion(
      name: Value(food.name),
      kcalPer100: Value(food.kcalPer100),
      proteinPer100: Value(food.proteinPer100),
      fatPer100: Value(food.fatPer100),
      carbPer100: Value(food.carbPer100),
    );
    if (existing != null) {
      await (_db.update(_db.customFoods)..where((t) => t.id.equals(existing)))
          .write(companion);
      return food.id;
    }
    final id = await _db.into(_db.customFoods).insert(
          CustomFoodsCompanion.insert(
            name: food.name,
            kcalPer100: food.kcalPer100,
            proteinPer100: food.proteinPer100,
            fatPer100: food.fatPer100,
            carbPer100: food.carbPer100,
          ),
        );
    return '$_customPrefix$id';
  }

  @override
  Future<void> deleteCustomFood(String id) async {
    final rowId = _rowIdOf(id);
    if (rowId == null) return;
    await (_db.delete(_db.customFoods)..where((t) => t.id.equals(rowId))).go();
  }

  @override
  Future<List<String>> recentFoods({int limit = 20}) async {
    final rows = await (_db.select(_db.foodEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    final seen = <String>{};
    final names = <String>[];
    for (final r in rows) {
      if (seen.add(r.name)) names.add(r.name);
      if (names.length >= limit) break;
    }
    return names;
  }

  // ── mappers ─────────────────────────────────────────────────────────
  int? _rowIdOf(String id) => id.startsWith(_customPrefix)
      ? int.tryParse(id.substring(_customPrefix.length))
      : null;

  FoodEntry _toEntry(FoodEntryRow r) => FoodEntry(
        id: r.id,
        day: r.day,
        meal: MealType.fromIndex(r.meal),
        name: r.name,
        grams: r.grams,
        kcal: r.kcal,
        protein: r.protein,
        fat: r.fat,
        carb: r.carb,
        createdAt: r.createdAt,
      );

  FoodItem _toFood(CustomFoodRow r) => FoodItem(
        id: '$_customPrefix${r.id}',
        name: r.name,
        kcalPer100: r.kcalPer100,
        proteinPer100: r.proteinPer100,
        fatPer100: r.fatPer100,
        carbPer100: r.carbPer100,
        isCustom: true,
      );
}
