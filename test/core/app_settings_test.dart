import 'package:fittnes/core/settings/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('settings JSON round-trips including the rest default', () {
    const s = AppSettings(unit: WeightUnit.lb, defaultRestSeconds: 90);
    final back = AppSettings.fromJson(s.toJson());
    expect(back.unit, WeightUnit.lb);
    expect(back.defaultRestSeconds, 90);
  });

  test('missing or absurd rest values fall back / clamp', () {
    expect(
      AppSettings.fromJson(const {}).defaultRestSeconds,
      AppSettings.kDefaultRestSeconds,
    );
    expect(
      AppSettings.fromJson(const {'defaultRestSeconds': 5}).defaultRestSeconds,
      AppSettings.minRestSeconds,
    );
    expect(
      AppSettings.fromJson(const {'defaultRestSeconds': 9999})
          .defaultRestSeconds,
      AppSettings.maxRestSeconds,
    );
  });

  test('controller persists the rest default and clamps it', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(appSettingsProvider.notifier);
    await notifier.setDefaultRestSeconds(75);
    expect(container.read(appSettingsProvider).defaultRestSeconds, 75);
    await notifier.setDefaultRestSeconds(0);
    expect(
      container.read(appSettingsProvider).defaultRestSeconds,
      AppSettings.minRestSeconds,
    );

    // A fresh container reads the stored value back.
    final again = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(again.dispose);
    expect(
      again.read(appSettingsProvider).defaultRestSeconds,
      AppSettings.minRestSeconds,
    );
  });
}
