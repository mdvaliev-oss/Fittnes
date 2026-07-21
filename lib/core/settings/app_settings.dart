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
  });

  final ThemeMode themeMode;
  final WeightUnit unit;

  AppSettings copyWith({ThemeMode? themeMode, WeightUnit? unit}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        unit: unit ?? this.unit,
      );
}

/// Injected in `main()` after `SharedPreferences.getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in ProviderScope'),
);

/// Reads/writes [AppSettings] synchronously via SharedPreferences.
class AppSettingsController extends Notifier<AppSettings> {
  static const _kTheme = 'settings.themeMode';
  static const _kUnit = 'settings.unit';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final theme = _prefs.getString(_kTheme);
    final unit = _prefs.getString(_kUnit);
    return AppSettings(
      themeMode: ThemeMode.values.asNameMap()[theme] ?? ThemeMode.dark,
      unit: WeightUnit.values.asNameMap()[unit] ?? WeightUnit.kg,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setUnit(WeightUnit unit) async {
    state = state.copyWith(unit: unit);
    await _prefs.setString(_kUnit, unit.name);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(AppSettingsController.new);
