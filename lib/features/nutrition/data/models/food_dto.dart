import '../../domain/entities/food_item.dart';

/// Maps the bundled foods JSON into domain [FoodItem]s (macros per 100 g).
abstract final class FoodDto {
  const FoodDto._();

  static FoodItem fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        kcalPer100: _num(json['kcal']),
        proteinPer100: _num(json['protein']),
        fatPer100: _num(json['fat']),
        carbPer100: _num(json['carb']),
      );

  static double _num(Object? v) => (v as num?)?.toDouble() ?? 0;
}
