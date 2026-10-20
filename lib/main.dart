import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/reminders/reminder_service.dart';
import 'core/settings/app_settings.dart';
import 'core/startup/startup_guard.dart';

/// Set when preferences fell back to memory, so the UI can warn once.
final prefsDegradedProvider = Provider<bool>((ref) => false);

Future<void> main() async {
  // Anything that escapes before the first frame is shown on screen rather
  // than leaving a black window behind the splash.
  await runZonedGuarded<Future<void>>(_boot, (error, stack) {
    runApp(StartupErrorApp(error: error, stackTrace: stack));
  });
}

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      Zone.current.handleUncaughtError(
        details.exception,
        details.stack ?? StackTrace.empty,
      );
    }
  };

  // Edge-to-edge, transparent system bars — required for the glass look.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Never let a plugin hold the first frame hostage.
  final handle = await openPreferences();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(handle.prefs),
      prefsDegradedProvider.overrideWithValue(handle.degraded),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FittnesApp(),
    ),
  );

  // Reminders are not needed for the first frame — initialise them after the
  // app is on screen, and never let them break startup.
  unawaited(_initReminders(container));
}

Future<void> _initReminders(ProviderContainer container) async {
  try {
    final reminders = container.read(reminderServiceProvider);
    await reminders.init();
    final settings = container.read(appSettingsProvider);
    if (settings.remindersEnabled) {
      await reminders.scheduleDaily(
        settings.reminderHour,
        settings.reminderMinute,
      );
    }
  } catch (_) {
    // Notifications unavailable — the app works without them.
  }
}
