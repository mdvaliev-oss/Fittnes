import 'meal_type.dart';

/// One line of a ready-made meal plan: a catalog food + portion in a meal.
class MealPlanItem {
  const MealPlanItem({
    required this.meal,
    required this.foodId,
    required this.grams,
  });

  final MealType meal;
  final String foodId;
  final double grams;

  factory MealPlanItem.fromJson(Map<String, dynamic> j) => MealPlanItem(
        meal: _mealFromName(j['meal'] as String?),
        foodId: (j['foodId'] as String?) ?? '',
        grams: (j['grams'] as num?)?.toDouble() ?? 0,
      );

  static MealType _mealFromName(String? name) => MealType.values.firstWhere(
        (m) => m.name == name,
        orElse: () => MealType.snack,
      );
}

/// A curated ready-made daily menu (≈2000 kcal), referencing catalog foods.
class MealPlan {
  const MealPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<MealPlanItem> items;

  List<MealPlanItem> ofMeal(MealType meal) =>
      items.where((i) => i.meal == meal).toList(growable: false);

  factory MealPlan.fromJson(Map<String, dynamic> j) => MealPlan(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? '',
        subtitle: (j['subtitle'] as String?) ?? '',
        items: ((j['items'] as List?) ?? const [])
            .map((e) => MealPlanItem.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}
