import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/reminders/reminder_service.dart';
import 'core/settings/app_settings.dart';
import 'core/startup/startup_guard.dart';

/// Set when preferences fell back to memory, so the UI can warn once.
final prefsDegradedProvider = Provider<bool>((ref) => false);

/// Flips once the app has painted; after that an uncaught error is logged,
/// not allowed to replace a working UI with the error screen.
bool _firstFramePainted = false;

Future<void> main() async {
  // Anything that escapes before the first frame is shown on screen rather
  // than leaving a black window behind the splash. Non-fatal framework
  // reports (a font that failed to load, an overflow) go through
  // FlutterError.onError and are deliberately NOT escalated here.
  await runZonedGuarded<Future<void>>(_boot, (error, stack) {
    if (_firstFramePainted) {
      debugPrint('Uncaught: $error\n$stack');
      return;
    }
    runApp(StartupErrorApp(error: error, stackTrace: stack));
  });
}

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _firstFramePainted = true;
  });

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
