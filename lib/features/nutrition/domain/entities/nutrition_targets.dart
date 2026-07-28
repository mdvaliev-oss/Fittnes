/// Manual daily nutrition goal (kcal + macro grams). Persisted in app settings.
class NutritionTargets {
  const NutritionTargets({
    this.kcal = 2000,
    this.proteinG = 150,
    this.fatG = 65,
    this.carbG = 200,
  });

  final double kcal;
  final double proteinG;
  final double fatG;
  final double carbG;

  NutritionTargets copyWith({
    double? kcal,
    double? proteinG,
    double? fatG,
    double? carbG,
  }) =>
      NutritionTargets(
        kcal: kcal ?? this.kcal,
        proteinG: proteinG ?? this.proteinG,
        fatG: fatG ?? this.fatG,
        carbG: carbG ?? this.carbG,
      );

  Map<String, dynamic> toJson() => {
        'kcal': kcal,
        'proteinG': proteinG,
        'fatG': fatG,
        'carbG': carbG,
      };

  factory NutritionTargets.fromJson(Map<String, dynamic> j) => NutritionTargets(
        kcal: (j['kcal'] as num?)?.toDouble() ?? 2000,
        proteinG: (j['proteinG'] as num?)?.toDouble() ?? 150,
        fatG: (j['fatG'] as num?)?.toDouble() ?? 65,
        carbG: (j['carbG'] as num?)?.toDouble() ?? 200,
      );
}
