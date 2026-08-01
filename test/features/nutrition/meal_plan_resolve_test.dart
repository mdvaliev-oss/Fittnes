import 'package:fittnes/features/nutrition/data/nutrition_repository_memory.dart';
import 'package:fittnes/features/nutrition/domain/entities/food_entry.dart';
import 'package:fittnes/features/nutrition/domain/entities/food_item.dart';
import 'package:fittnes/features/nutrition/domain/entities/meal_plan.dart';
import 'package:fittnes/features/nutrition/domain/entities/meal_type.dart';
import 'package:fittnes/features/nutrition/domain/nutrition_math.dart';
import 'package:flutter_test/flutter_test.dart';

const _catalog = {
  'chicken': FoodItem(
    id: 'chicken',
    name: 'Курица',
    kcalPer100: 137,
    proteinPer100: 29.8,
    fatPer100: 1.8,
    carbPer100: 0.5,
  ),
  'buckwheat': FoodItem(
    id: 'buckwheat',
    name: 'Гречка',
    kcalPer100: 92,
    proteinPer100: 3.4,
    fatPer100: 0.6,
    carbPer100: 17.1,
  ),
};

const _plan = MealPlan(
  id: 'day-x',
  title: 'Тест',
  subtitle: '',
  items: [
    MealPlanItem(meal: MealType.lunch, foodId: 'chicken', grams: 200),
    MealPlanItem(meal: MealType.lunch, foodId: 'buckwheat', grams: 150),
    MealPlanItem(meal: MealType.lunch, foodId: 'missing', grams: 100),
  ],
);

void main() {
  test('resolveMealPlan builds entries with snapshot macros, skips unknown',
      () {
    final day = DateTime(2026, 6, 1, 15);
    final entries =
        resolveMealPlan(_plan, _catalog, day, now: DateTime(2026, 6, 1));

    // "missing" is dropped.
    expect(entries, hasLength(2));
    final chicken = entries.firstWhere((e) => e.name == 'Курица');
    expect(chicken.day, DateTime(2026, 6, 1));
    expect(chicken.meal, MealType.lunch);
    expect(chicken.kcal, closeTo(274, 0.1)); // 137 * 2
    expect(chicken.protein, closeTo(59.6, 0.1));
  });

  test('mealPlanTotals sums resolvable items', () {
    final t = mealPlanTotals(_plan, _catalog);
    expect(t.kcal, closeTo(274 + 138, 0.5)); // chicken 274 + buckwheat 138
  });

  test('apply = clearDay then add fills the day with exactly the menu',
      () async {
    final repo = NutritionRepositoryMemory();
    final day = DateTime(2026, 6, 1);

    // Pre-existing food that should be wiped by "replace day".
    await repo.addEntry(
      FoodEntry(
        day: day,
        meal: MealType.breakfast,
        name: 'Старое',
        grams: 100,
        kcal: 500,
        protein: 0,
        fat: 0,
        carb: 0,
        createdAt: day,
      ),
    );

    await repo.clearDay(day);
    for (final e in resolveMealPlan(_plan, _catalog, day)) {
      await repo.addEntry(e);
    }

    final result = await repo.entriesForDay(day);
    expect(result, hasLength(2));
    expect(result.any((e) => e.name == 'Старое'), isFalse);
  });
}
