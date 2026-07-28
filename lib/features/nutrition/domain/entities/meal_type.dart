/// The four meal buckets a food entry can belong to.
enum MealType {
  breakfast('Завтрак'),
  lunch('Обед'),
  dinner('Ужин'),
  snack('Перекус');

  const MealType(this.label);
  final String label;

  /// Stable index used for DB storage / JSON (order must not change).
  static MealType fromIndex(int i) =>
      (i >= 0 && i < values.length) ? values[i] : MealType.snack;
}
