import 'package:fittnes/features/nutrition/data/food_local_data_source.dart';
import 'package:fittnes/features/nutrition/data/meal_plan_local_data_source.dart';
import 'package:fittnes/features/nutrition/domain/entities/food_item.dart';
import 'package:fittnes/features/nutrition/domain/entities/meal_plan.dart';
import 'package:fittnes/features/nutrition/domain/entities/meal_type.dart';
import 'package:fittnes/features/nutrition/domain/nutrition_math.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MealPlan> plans;
  late Map<String, FoodItem> catalog;

  setUpAll(() async {
    plans = await MealPlanLocalDataSource(bundle: rootBundle).loadAll();
    final foods = await FoodLocalDataSource(bundle: rootBundle).loadAll();
    catalog = {for (final f in foods) f.id: f};
  });

  test('there are 7 weekly menus with unique ids', () {
    expect(plans, hasLength(7));
    final ids = plans.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every meal plan item references an existing catalog food', () {
    for (final plan in plans) {
      for (final item in plan.items) {
        expect(
          catalog.containsKey(item.foodId),
          isTrue,
          reason: '${plan.id}: unknown food ${item.foodId}',
        );
        expect(item.grams, greaterThan(0), reason: '${plan.id} ${item.foodId}');
      }
    }
  });

  test('each menu has breakfast, lunch and dinner', () {
    for (final plan in plans) {
      for (final meal in [
        MealType.breakfast,
        MealType.lunch,
        MealType.dinner,
      ]) {
        expect(
          plan.ofMeal(meal),
          isNotEmpty,
          reason: '${plan.id}: no ${meal.name}',
        );
      }
    }
  });

  test('each menu totals roughly 2000 kcal', () {
    for (final plan in plans) {
      final kcal = mealPlanTotals(plan, catalog).kcal;
      expect(
        kcal,
        inInclusiveRange(1850, 2150),
        reason: '${plan.id}: ${kcal.round()} kcal',
      );
    }
  });
}
