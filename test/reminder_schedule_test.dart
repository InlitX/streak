import 'package:flutter_test/flutter_test.dart';
import 'package:streak/services/reminder_schedule.dart';

void main() {
  group('notificationId', () {
    test('a habit keeps its ids when the reminder time changes', () {
      final monday = ReminderSchedule.notificationId('habit-1', 'rem-1', 1);
      final again = ReminderSchedule.notificationId('habit-1', 'rem-1', 1);
      expect(again, monday);
    });

    test('every weekday gets its own id', () {
      final ids = {
        for (var day = 1; day <= 7; day++)
          ReminderSchedule.notificationId('habit-1', 'rem-1', day),
      };
      expect(ids.length, 7);
    });

    test('two reminders of the same habit never collide', () {
      final first = {
        for (var day = 1; day <= 7; day++)
          ReminderSchedule.notificationId('habit-1', 'rem-1', day),
      };
      final second = {
        for (var day = 1; day <= 7; day++)
          ReminderSchedule.notificationId('habit-1', 'rem-2', day),
      };
      expect(first.intersection(second), isEmpty);
    });

    test('ids stay inside the 32 bit range Android needs', () {
      final id = ReminderSchedule.notificationId(
        'a-very-long-habit-identifier-uuid-like',
        'another-long-reminder-identifier',
        7,
      );
      expect(id, lessThan(2147483647));
      expect(id, greaterThanOrEqualTo(0));
    });
  });

  group('nextWeekly', () {
    test('today counts when the time has not passed yet', () {
      final now = DateTime(2026, 8, 1, 10, 0);
      final next = ReminderSchedule.nextWeekly(
        now: now,
        weekday: DateTime.saturday,
        hour: 18,
        minute: 21,
      );
      expect(next, DateTime(2026, 8, 1, 18, 21));
    });

    test('a time already gone today lands next week', () {
      final now = DateTime(2026, 8, 1, 19, 0);
      final next = ReminderSchedule.nextWeekly(
        now: now,
        weekday: DateTime.saturday,
        hour: 18,
        minute: 21,
      );
      expect(next, DateTime(2026, 8, 8, 18, 21));
    });

    test('every day of the week resolves inside the next seven days', () {
      final now = DateTime(2026, 8, 1, 12, 0);
      for (var day = 1; day <= 7; day++) {
        final next = ReminderSchedule.nextWeekly(
          now: now,
          weekday: day,
          hour: 18,
          minute: 21,
        );
        expect(next.weekday, day);
        expect(next.isAfter(now), isTrue);
        expect(next.difference(now).inDays, lessThan(8));
      }
    });

    test('moving a reminder one minute forward keeps the same day', () {
      final now = DateTime(2026, 8, 1, 18, 0);
      final before = ReminderSchedule.nextWeekly(
        now: now,
        weekday: DateTime.saturday,
        hour: 18,
        minute: 21,
      );
      final after = ReminderSchedule.nextWeekly(
        now: now,
        weekday: DateTime.saturday,
        hour: 18,
        minute: 22,
      );
      expect(after.day, before.day);
      expect(after.difference(before), const Duration(minutes: 1));
    });
  });
}
