import '../settings/app_settings.dart';

/// Weight is stored canonically in **kilograms** everywhere (DB, entities,
/// backup). Conversion and formatting happen only at the display / input
/// boundary via these helpers, so switching [WeightUnit] never migrates data.
extension WeightUnitX on WeightUnit {
  /// Kilograms in one unit (1 kg per kg; 1 lb ≈ 0.4536 kg).
  static const double _lbPerKg = 2.2046226218;

  /// Convert a canonical kilogram value into this unit for display / editing.
  double fromKg(double kg) => this == WeightUnit.lb ? kg * _lbPerKg : kg;

  /// Convert a value entered in this unit back into canonical kilograms.
  double toKg(double value) => this == WeightUnit.lb ? value / _lbPerKg : value;

  /// Sensible decimals when rendering a value in this unit.
  int get decimals => this == WeightUnit.lb ? 0 : 1;

  /// Natural load increment in this unit (2.5 kg / 5 lb).
  double get step => this == WeightUnit.lb ? 5 : 2.5;
}

/// Formats a canonical [kg] value in the user's [unit], e.g. `"61 кг"` /
/// `"135 фунт"`. Set [withUnit] to `false` for the bare number (input fields).
/// Trailing `.0` is trimmed so kilograms read `"60"` not `"60.0"`.
String formatWeight(double kg, WeightUnit unit, {bool withUnit = true}) {
  final value = unit.fromKg(kg);
  final text = _trim(value, unit.decimals);
  return withUnit ? '$text ${unit.label}' : text;
}

/// Formats a value already expressed in [unit] (no conversion) — for seeding
/// an input field from a canonical kg value the caller already converted.
String formatValue(double value, WeightUnit unit) =>
    _trim(value, unit.decimals);

String _trim(double value, int decimals) {
  final fixed = value.toStringAsFixed(decimals);
  if (!fixed.contains('.')) return fixed;
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
