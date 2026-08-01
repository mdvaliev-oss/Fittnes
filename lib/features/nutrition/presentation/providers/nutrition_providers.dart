import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../../data/food_local_data_source.dart';
import '../../data/meal_plan_local_data_source.dart';
import '../../data/nutrition_repository_drift.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal_plan.dart';
import '../../domain/entities/nutrition_targets.dart';
import '../../domain/nutrition_math.dart';
import '../../domain/repositories/nutrition_repository.dart';

/// Bundled food catalog data source.
final foodLocalDataSourceProvider =
    Provider<FoodLocalDataSource>((ref) => FoodLocalDataSource());

/// Drift-backed nutrition repository (reuses the shared app database).
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepositoryDrift(ref.watch(appDatabaseProvider));
});

/// The read-only bundled food catalog (macros per 100 g).
final foodCatalogProvider = FutureProvider<List<FoodItem>>((ref) {
  return ref.watch(foodLocalDataSourceProvider).loadAll();
});

/// Food catalog indexed by id (for resolving meal plans).
final foodCatalogByIdProvider =
    FutureProvider<Map<String, FoodItem>>((ref) async {
  final all = await ref.watch(foodCatalogProvider.future);
  return {for (final f in all) f.id: f};
});

/// Ready-made meal plans data source + list.
final mealPlanLocalDataSourceProvider =
    Provider<MealPlanLocalDataSource>((ref) => MealPlanLocalDataSource());

final mealPlansProvider = FutureProvider<List<MealPlan>>((ref) {
  return ref.watch(mealPlanLocalDataSourceProvider).loadAll();
});

/// The user's custom foods.
final customFoodsProvider = FutureProvider<List<FoodItem>>((ref) {
  return ref.watch(nutritionRepositoryProvider).customFoods();
});

/// Catalog + custom foods combined (custom first).
final allFoodsProvider = FutureProvider<List<FoodItem>>((ref) async {
  final catalog = await ref.watch(foodCatalogProvider.future);
  final custom = await ref.watch(customFoodsProvider.future);
  return [...custom, ...catalog];
});

/// The day the nutrition screen is showing (defaults to today, date-only).
final selectedNutritionDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Diary aggregate for the currently selected day.
final dailyNutritionProvider = FutureProvider<DailyNutrition>((ref) async {
  final day = ref.watch(selectedNutritionDateProvider);
  final entries =
      await ref.watch(nutritionRepositoryProvider).entriesForDay(day);
  return DailyNutrition(day, entries);
});

/// Today's diary aggregate (for the home summary card).
final todayNutritionProvider = FutureProvider<DailyNutrition>((ref) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final entries =
      await ref.watch(nutritionRepositoryProvider).entriesForDay(today);
  return DailyNutrition(today, entries);
});

/// Manual daily targets, derived from app settings.
final nutritionTargetsProvider = Provider<NutritionTargets>((ref) {
  final s = ref.watch(appSettingsProvider);
  return NutritionTargets(
    kcal: s.nutritionKcal,
    proteinG: s.nutritionProtein,
    fatG: s.nutritionFat,
    carbG: s.nutritionCarb,
  );
});

/// Recently logged food names for quick re-add.
final recentFoodNamesProvider = FutureProvider<List<String>>((ref) {
  // Depend on the diary so it refreshes after new entries.
  ref.watch(dailyNutritionProvider);
  return ref.watch(nutritionRepositoryProvider).recentFoods();
});
