import '../entities/food_entry.dart';
import '../entities/food_item.dart';

/// Persistence for the nutrition diary and the user's custom foods.
abstract interface class NutritionRepository {
  /// Diary entries for a single day (any time on [day]).
  Future<List<FoodEntry>> entriesForDay(DateTime day);

  /// All diary entries across every day (used by backup export).
  Future<List<FoodEntry>> allEntries();

  /// Inserts an entry, returning its new id.
  Future<int> addEntry(FoodEntry entry);

  Future<void> removeEntry(int id);

  /// Deletes every diary entry on [day] (used by "replace day" meal plans).
  Future<void> clearDay(DateTime day);

  /// User-authored foods (most-recent first).
  Future<List<FoodItem>> customFoods();

  /// Inserts or updates a custom food, returning its id.
  Future<String> saveCustomFood(FoodItem food);

  Future<void> deleteCustomFood(String id);

  /// Distinct recently logged food names (for quick re-add).
  Future<List<String>> recentFoods({int limit = 20});
}
