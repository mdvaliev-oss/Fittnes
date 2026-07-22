import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules a daily "time to train" local notification.
///
/// All plugin calls are guarded (skipped on web / wrapped in try-catch) so the
/// app degrades gracefully where notifications aren't available.
class ReminderService {
  static const int _notificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> scheduleDaily(int hour, int minute) async {
    if (kIsWeb || !_ready) return;
    try {
      await _plugin.cancel(_notificationId);
      await _plugin.zonedSchedule(
        _notificationId,
        'Пора на тренировку 💪',
        'Не пропусти сегодняшнюю сессию.',
        _nextInstance(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_reminders',
            'Напоминания о тренировке',
            channelDescription: 'Ежедневные напоминания о тренировке',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Scheduling unavailable on this platform — ignore.
    }
  }

  Future<void> cancel() async {
    if (kIsWeb || !_ready) return;
    try {
      await _plugin.cancel(_notificationId);
    } catch (_) {}
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Pure, testable: the next occurrence of [hour]:[minute] at/after [from].
  static DateTime nextOccurrence(DateTime from, int hour, int minute) {
    var s = DateTime(from.year, from.month, from.day, hour, minute);
    if (!s.isAfter(from)) s = s.add(const Duration(days: 1));
    return s;
  }
}

final reminderServiceProvider =
    Provider<ReminderService>((ref) => ReminderService());
