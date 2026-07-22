import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/reminders/reminder_service.dart';
import 'core/settings/app_settings.dart';

Future<void> main() async {
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

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Initialise reminders and (re)schedule if enabled.
  final reminders = container.read(reminderServiceProvider);
  await reminders.init();
  final settings = container.read(appSettingsProvider);
  if (settings.remindersEnabled) {
    await reminders.scheduleDaily(
      settings.reminderHour,
      settings.reminderMinute,
    );
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FittnesApp(),
    ),
  );
}
