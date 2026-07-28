import 'package:fittnes/features/nutrition/domain/entities/food_entry.dart';
import 'package:fittnes/features/nutrition/domain/entities/food_item.dart';
import 'package:fittnes/features/nutrition/domain/entities/meal_type.dart';
import 'package:fittnes/features/nutrition/domain/nutrition_math.dart';
import 'package:flutter_test/flutter_test.dart';

FoodEntry _entry(MealType meal, double kcal, double p, double f, double c) =>
    FoodEntry(
      day: DateTime(2026, 5, 1),
      meal: meal,
      name: 'x',
      grams: 100,
      kcal: kcal,
      protein: p,
      fat: f,
      carb: c,
      createdAt: DateTime(2026, 5, 1, 8),
    );

void main() {
  test('macrosFor scales per-100g values by grams', () {
    const chicken = FoodItem(
      id: 'chicken',
      name: 'Курица',
      kcalPer100: 137,
      proteinPer100: 29.8,
      fatPer100: 1.8,
      carbPer100: 0.5,
    );
    final m = macrosFor(chicken, 150);
    expect(m.kcal, closeTo(205.5, 0.01));
    expect(m.protein, closeTo(44.7, 0.01));
    expect(m.fat, closeTo(2.7, 0.01));
    expect(m.carb, closeTo(0.75, 0.01));
  });

  test('DailyNutrition groups by meal and totals', () {
    final day = DailyNutrition(DateTime(2026, 5, 1), [
      _entry(MealType.breakfast, 300, 20, 10, 30),
      _entry(MealType.breakfast, 200, 10, 5, 25),
      _entry(MealType.dinner, 500, 40, 20, 30),
    ]);

    expect(day.ofMeal(MealType.breakfast), hasLength(2));
    expect(day.ofMeal(MealType.lunch), isEmpty);
    expect(day.mealTotals(MealType.breakfast).kcal, 500);
    expect(day.totals.kcal, 1000);
    expect(day.totals.protein, 70);
  });

  test('remaining and progress fraction', () {
    expect(remainingKcal(1800, 2400), 600);
    expect(remainingKcal(2600, 2400), -200); // over target
    expect(progressFraction(1200, 2400), 0.5);
    expect(progressFraction(3000, 2400), 1.0); // clamped
    expect(progressFraction(100, 0), 0.0); // no target
  });
}
