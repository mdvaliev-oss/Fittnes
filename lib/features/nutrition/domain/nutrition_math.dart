import 'entities/food_entry.dart';
import 'entities/food_item.dart';
import 'entities/meal_type.dart';

/// A macro total (kcal + grams of each macronutrient). Used for a meal, a day,
/// and remaining-to-target math.
class MacroTotals {
  const MacroTotals({
    this.kcal = 0,
    this.protein = 0,
    this.fat = 0,
    this.carb = 0,
  });

  final double kcal;
  final double protein;
  final double fat;
  final double carb;

  MacroTotals operator +(MacroTotals o) => MacroTotals(
        kcal: kcal + o.kcal,
        protein: protein + o.protein,
        fat: fat + o.fat,
        carb: carb + o.carb,
      );
}

/// Macros for [grams] of [food], scaling its per-100 g values.
MacroTotals macrosFor(FoodItem food, double grams) {
  final k = grams / 100.0;
  return MacroTotals(
    kcal: food.kcalPer100 * k,
    protein: food.proteinPer100 * k,
    fat: food.fatPer100 * k,
    carb: food.carbPer100 * k,
  );
}

/// Sum of a list of diary entries.
MacroTotals sumEntries(Iterable<FoodEntry> entries) {
  var total = const MacroTotals();
  for (final e in entries) {
    total +=
        MacroTotals(kcal: e.kcal, protein: e.protein, fat: e.fat, carb: e.carb);
  }
  return total;
}

/// One day's diary: entries grouped by meal, plus totals.
class DailyNutrition {
  DailyNutrition(this.day, List<FoodEntry> entries)
      : entries = List.unmodifiable(entries);

  final DateTime day;
  final List<FoodEntry> entries;

  List<FoodEntry> ofMeal(MealType meal) =>
      entries.where((e) => e.meal == meal).toList(growable: false);

  MacroTotals mealTotals(MealType meal) => sumEntries(ofMeal(meal));

  MacroTotals get totals => sumEntries(entries);
}

/// Remaining kcal to a target (can go negative when over).
double remainingKcal(double consumed, double target) => target - consumed;

/// Fraction 0..1 of a target reached (clamped for progress rings).
double progressFraction(double consumed, double target) {
  if (target <= 0) return 0;
  return (consumed / target).clamp(0.0, 1.0);
}
