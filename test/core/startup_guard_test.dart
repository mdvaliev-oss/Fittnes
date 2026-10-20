import 'dart:async';

import 'package:fittnes/core/settings/app_settings.dart';
import 'package:fittnes/core/startup/startup_guard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a plugin that never answers falls back to in-memory prefs', () async {
    final handle = await openPreferences(
      open: () => Completer<SharedPreferences>().future, // hangs forever
      timeout: const Duration(milliseconds: 50),
    );
    expect(handle.degraded, isTrue);

    // The fallback still drives settings normally.
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(handle.prefs)],
    );
    addTearDown(container.dispose);
    await container.read(appSettingsProvider.notifier).setUnit(WeightUnit.lb);
    expect(container.read(appSettingsProvider).unit, WeightUnit.lb);
  });

  test('a plugin that throws also falls back', () async {
    final handle = await openPreferences(
      open: () async => throw StateError('jni init failed'),
    );
    expect(handle.degraded, isTrue);
  });

  test('a healthy plugin is used as-is', () async {
    SharedPreferences.setMockInitialValues(const {'k': 'v'});
    final handle = await openPreferences(
      open: SharedPreferences.getInstance,
    );
    expect(handle.degraded, isFalse);
    expect(handle.prefs.getString('k'), 'v');
  });

  testWidgets('StartupErrorApp shows the error text instead of a black screen',
      (tester) async {
    await tester.pumpWidget(
      StartupErrorApp(
        error: StateError('boom at startup'),
        stackTrace: StackTrace.fromString('#0 main (main.dart:1)'),
      ),
    );
    expect(find.text('Приложение не смогло запуститься'), findsOneWidget);
    expect(find.textContaining('boom at startup'), findsOneWidget);
    expect(find.text('Скопировать ошибку'), findsOneWidget);
  });
}
