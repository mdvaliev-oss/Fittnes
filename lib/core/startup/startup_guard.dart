import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How long `main()` is willing to wait for the preferences plugin before it
/// gives up and starts the app on an in-memory store.
const Duration kPrefsTimeout = Duration(seconds: 4);

/// Result of [openPreferences]: the store to inject, and whether it is the
/// real on-device one.
class PreferencesHandle {
  const PreferencesHandle(this.prefs, {required this.degraded});

  final SharedPreferences prefs;

  /// True when the platform plugin hung or threw and an in-memory fallback is
  /// in use — settings will not survive a restart, but the app opens.
  final bool degraded;
}

/// Opens [SharedPreferences] without ever blocking startup indefinitely.
///
/// A native plugin that never answers (as `shared_preferences_android` 2.5.0
/// did on a real phone) must not keep `runApp` from being called; a working
/// app that forgets its settings beats a black screen.
Future<PreferencesHandle> openPreferences({
  Future<SharedPreferences> Function()? open,
  Duration timeout = kPrefsTimeout,
}) async {
  try {
    final prefs =
        await (open ?? SharedPreferences.getInstance)().timeout(timeout);
    return PreferencesHandle(prefs, degraded: false);
  } catch (_) {
    // The only public way to (a) drop the poisoned singleton completer that a
    // hung getInstance() leaves behind and (b) swap in the in-memory store.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(const {});
    return PreferencesHandle(
      await SharedPreferences.getInstance(),
      degraded: true,
    );
  }
}

/// Shown instead of a black screen when startup itself throws — the error
/// text is on screen and copyable, so it can be reported without adb.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  String get _report => '$error\n\n${stackTrace ?? ''}'.trim();

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0F);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF5C5C),
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Приложение не смогло запуститься',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Скопируй текст ошибки ниже и отправь разработчику.',
                  style: TextStyle(color: Color(0xFFA0A0B0)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _report,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: _report)),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать ошибку'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
