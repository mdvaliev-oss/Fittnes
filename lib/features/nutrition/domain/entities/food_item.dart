/// A food product with macros expressed per 100 g.
///
/// Catalog items come from a bundled JSON asset (`isCustom == false`); items
/// the user creates are stored in the database (`isCustom == true`).
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.fatPer100,
    required this.carbPer100,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final double kcalPer100;
  final double proteinPer100;
  final double fatPer100;
  final double carbPer100;
  final bool isCustom;

  FoodItem copyWith({
    String? id,
    String? name,
    double? kcalPer100,
    double? proteinPer100,
    double? fatPer100,
    double? carbPer100,
    bool? isCustom,
  }) =>
      FoodItem(
        id: id ?? this.id,
        name: name ?? this.name,
        kcalPer100: kcalPer100 ?? this.kcalPer100,
        proteinPer100: proteinPer100 ?? this.proteinPer100,
        fatPer100: fatPer100 ?? this.fatPer100,
        carbPer100: carbPer100 ?? this.carbPer100,
        isCustom: isCustom ?? this.isCustom,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FoodItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
