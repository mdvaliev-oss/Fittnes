import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Weight display unit.
enum WeightUnit {
  kg('кг'),
  lb('фунт');

  const WeightUnit(this.label);
  final String label;
}

/// Immutable app-wide settings.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.unit = WeightUnit.kg,
    this.remindersEnabled = false,
    this.reminderHour = 18,
    this.reminderMinute = 0,
    this.nutritionKcal = 2000,
    this.nutritionProtein = 150,
    this.nutritionFat = 65,
    this.nutritionCarb = 200,
  });

  final ThemeMode themeMode;
  final WeightUnit unit;
  final bool remindersEnabled;
  final int reminderHour;
  final int reminderMinute;

  // Manual daily nutrition goal (kept as raw values so `core` stays free of
  // feature imports; the nutrition layer maps these to its NutritionTargets).
  final double nutritionKcal;
  final double nutritionProtein;
  final double nutritionFat;
  final double nutritionCarb;

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);

  AppSettings copyWith({
    ThemeMode? themeMode,
    WeightUnit? unit,
    bool? remindersEnabled,
    int? reminderHour,
    int? reminderMinute,
    double? nutritionKcal,
    double? nutritionProtein,
    double? nutritionFat,
    double? nutritionCarb,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        unit: unit ?? this.unit,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        nutritionKcal: nutritionKcal ?? this.nutritionKcal,
        nutritionProtein: nutritionProtein ?? this.nutritionProtein,
        nutritionFat: nutritionFat ?? this.nutritionFat,
        nutritionCarb: nutritionCarb ?? this.nutritionCarb,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'unit': unit.name,
        'remindersEnabled': remindersEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'nutritionKcal': nutritionKcal,
        'nutritionProtein': nutritionProtein,
        'nutritionFat': nutritionFat,
        'nutritionCarb': nutritionCarb,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        themeMode:
            ThemeMode.values.asNameMap()[j['themeMode']] ?? ThemeMode.dark,
        unit: WeightUnit.values.asNameMap()[j['unit']] ?? WeightUnit.kg,
        remindersEnabled: j['remindersEnabled'] as bool? ?? false,
        reminderHour: (j['reminderHour'] as num?)?.toInt() ?? 18,
        reminderMinute: (j['reminderMinute'] as num?)?.toInt() ?? 0,
        nutritionKcal: (j['nutritionKcal'] as num?)?.toDouble() ?? 2000,
        nutritionProtein: (j['nutritionProtein'] as num?)?.toDouble() ?? 150,
        nutritionFat: (j['nutritionFat'] as num?)?.toDouble() ?? 65,
        nutritionCarb: (j['nutritionCarb'] as num?)?.toDouble() ?? 200,
      );
}

/// Injected in `main()` after `SharedPreferences.getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in ProviderScope'),
);

/// Reads/writes [AppSettings] synchronously via SharedPreferences.
class AppSettingsController extends Notifier<AppSettings> {
  static const _key = 'settings.data';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> _save(AppSettings next) async {
    state = next;
    await _prefs.setString(_key, jsonEncode(next.toJson()));
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _save(state.copyWith(themeMode: mode));

  Future<void> setUnit(WeightUnit unit) => _save(state.copyWith(unit: unit));

  Future<void> setNutritionTargets({
    double? kcal,
    double? protein,
    double? fat,
    double? carb,
  }) =>
      _save(
        state.copyWith(
          nutritionKcal: kcal,
          nutritionProtein: protein,
          nutritionFat: fat,
          nutritionCarb: carb,
        ),
      );

  Future<void> setReminders({bool? enabled, int? hour, int? minute}) => _save(
        state.copyWith(
          remindersEnabled: enabled,
          reminderHour: hour,
          reminderMinute: minute,
        ),
      );

  /// Replaces all settings (used by data import).
  Future<void> replace(AppSettings next) => _save(next);
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);
