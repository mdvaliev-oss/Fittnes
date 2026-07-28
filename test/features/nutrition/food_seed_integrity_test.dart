import 'package:fittnes/features/nutrition/data/food_local_data_source.dart';
import 'package:fittnes/features/nutrition/domain/entities/food_item.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<FoodItem> foods;

  setUpAll(() async {
    foods = await FoodLocalDataSource(bundle: rootBundle).loadAll();
  });

  test('catalog is sizeable and every entry parses', () {
    expect(foods.length, greaterThanOrEqualTo(100));
  });

  test('ids are unique', () {
    final ids = foods.map((f) => f.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every food has a name and non-negative macros', () {
    for (final f in foods) {
      expect(f.name.trim(), isNotEmpty, reason: f.id);
      expect(f.kcalPer100, greaterThanOrEqualTo(0), reason: f.id);
      expect(f.proteinPer100, greaterThanOrEqualTo(0), reason: f.id);
      expect(f.fatPer100, greaterThanOrEqualTo(0), reason: f.id);
      expect(f.carbPer100, greaterThanOrEqualTo(0), reason: f.id);
    }
  });

  test('macro kcal is roughly consistent with 4/9/4 rule', () {
    // Atwater: kcal ≈ 4*protein + 9*fat + 4*carb. Allow slack for fiber,
    // alcohol, rounding — just catch gross data-entry errors.
    for (final f in foods) {
      final est = 4 * f.proteinPer100 + 9 * f.fatPer100 + 4 * f.carbPer100;
      if (f.kcalPer100 < 20) continue; // very low-cal items: skip
      expect(
        (est - f.kcalPer100).abs(),
        lessThan(f.kcalPer100 * 0.5 + 60),
        reason: '${f.id}: kcal ${f.kcalPer100} vs est $est',
      );
    }
  });
}
