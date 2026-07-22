import 'package:fittnes/core/reminders/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReminderService.nextOccurrence', () {
    test('returns today when the time is still ahead', () {
      final from = DateTime(2026, 6, 10, 8, 0);
      final next = ReminderService.nextOccurrence(from, 18, 30);
      expect(next, DateTime(2026, 6, 10, 18, 30));
    });

    test('rolls over to tomorrow when the time has passed', () {
      final from = DateTime(2026, 6, 10, 20, 0);
      final next = ReminderService.nextOccurrence(from, 18, 30);
      expect(next, DateTime(2026, 6, 11, 18, 30));
    });

    test('equal time rolls to the next day', () {
      final from = DateTime(2026, 6, 10, 18, 30);
      final next = ReminderService.nextOccurrence(from, 18, 30);
      expect(next, DateTime(2026, 6, 11, 18, 30));
    });
  });
}
