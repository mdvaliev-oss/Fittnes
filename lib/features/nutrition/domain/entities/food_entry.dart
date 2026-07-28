import 'meal_type.dart';

/// One logged food in the diary. Macros are a **snapshot** computed when the
/// entry was added, so past days stay accurate even if the source product is
/// later edited or deleted.
class FoodEntry {
  const FoodEntry({
    this.id,
    required this.day,
    required this.meal,
    required this.name,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.createdAt,
  });

  /// Null until persisted (DB assigns the id).
  final int? id;

  /// Date-only (midnight) the entry belongs to.
  final DateTime day;
  final MealType meal;
  final String name;
  final double grams;
  final double kcal;
  final double protein;
  final double fat;
  final double carb;
  final DateTime createdAt;

  FoodEntry copyWith({int? id}) => FoodEntry(
        id: id ?? this.id,
        day: day,
        meal: meal,
        name: name,
        grams: grams,
        kcal: kcal,
        protein: protein,
        fat: fat,
        carb: carb,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day.toIso8601String(),
        'meal': meal.index,
        'name': name,
        'grams': grams,
        'kcal': kcal,
        'protein': protein,
        'fat': fat,
        'carb': carb,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
        id: (j['id'] as num?)?.toInt(),
        day: DateTime.parse(j['day'] as String),
        meal: MealType.fromIndex((j['meal'] as num?)?.toInt() ?? 3),
        name: (j['name'] as String?) ?? '',
        grams: (j['grams'] as num?)?.toDouble() ?? 0,
        kcal: (j['kcal'] as num?)?.toDouble() ?? 0,
        protein: (j['protein'] as num?)?.toDouble() ?? 0,
        fat: (j['fat'] as num?)?.toDouble() ?? 0,
        carb: (j['carb'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
