import 'package:fittnes/core/settings/app_settings.dart';
import 'package:fittnes/core/units/weight_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeightUnitX conversion', () {
    test('kg is identity', () {
      expect(WeightUnit.kg.fromKg(100), 100);
      expect(WeightUnit.kg.toKg(100), 100);
    });

    test('kg → lb and back round-trips', () {
      final lb = WeightUnit.lb.fromKg(100);
      expect(lb, closeTo(220.462, 0.01));
      expect(WeightUnit.lb.toKg(lb), closeTo(100, 1e-9));
    });

    test('step and decimals differ by unit', () {
      expect(WeightUnit.kg.step, 2.5);
      expect(WeightUnit.lb.step, 5);
      expect(WeightUnit.kg.decimals, 1);
      expect(WeightUnit.lb.decimals, 0);
    });
  });

  group('formatWeight', () {
    test('kg trims trailing zeros and appends unit', () {
      expect(formatWeight(60, WeightUnit.kg), '60 кг');
      expect(formatWeight(62.5, WeightUnit.kg), '62.5 кг');
    });

    test('lb rounds to whole and appends unit', () {
      expect(formatWeight(100, WeightUnit.lb), '220 фунт');
    });

    test('withUnit:false yields the bare number', () {
      expect(formatWeight(62.5, WeightUnit.kg, withUnit: false), '62.5');
    });
  });

  group('formatValue', () {
    test('formats an already-converted value', () {
      expect(formatValue(60, WeightUnit.kg), '60');
      expect(formatValue(220.462, WeightUnit.lb), '220');
    });
  });
}
