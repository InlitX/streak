import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/services/reminder_schedule.dart';

Habit _habit({
  HabitInterval interval = HabitInterval.daily,
  List<int> weekdays = const [],
  List<int> restDays = const [],
}) =>
    Habit(
      id: 'h',
      name: 'Test',
      color: const Color(0xFF00FF00),
      order: 0,
      interval: interval,
      scheduleWeekdays: weekdays,
      restDays: restDays,
    );

void main() {
  group('which weekdays a reminder may ring on', () {
    test('a habit on Mon, Wed and Fri stays quiet the other days', () {
      final habit = _habit(
        interval: HabitInterval.weekdays,
        weekdays: [1, 3, 5],
      );
      expect([for (var d = 1; d <= 7; d++) habit.ringsOnWeekday(d)],
          [true, false, true, false, true, false, false]);
    });

    test('a daily habit rings any day, minus its rest days', () {
      final habit = _habit(restDays: [6, 7]);
      expect([for (var d = 1; d <= 7; d++) habit.ringsOnWeekday(d)],
          [true, true, true, true, true, false, false]);
    });

    test('a habit with no chosen weekdays is not silenced', () {
      final habit = _habit(interval: HabitInterval.weekdays);
      expect([for (var d = 1; d <= 7; d++) habit.ringsOnWeekday(d)],
          List.filled(7, true));
    });
  });

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

  group('hourlySlots', () {
    test('it repeats from the start time until the day ends', () {
      final slots = ReminderSchedule.hourlySlots(
        hour: 18,
        minute: 30,
        everyMinutes: 120,
      );

      expect(slots, [18 * 60 + 30, 20 * 60 + 30, 22 * 60 + 30]);
    });

    test('it never crosses into the next day', () {
      final slots = ReminderSchedule.hourlySlots(
        hour: 23,
        minute: 0,
        everyMinutes: 180,
      );

      expect(slots, [23 * 60]);
    });

    test('every hour fills the whole day when it rings daily', () {
      final slots = ReminderSchedule.hourlySlots(
        hour: 0,
        minute: 0,
        everyMinutes: 60,
        cap: ReminderSchedule.hourlyCap(1),
      );

      expect(slots.length, 24);
    });

    test('it stops at the until time, counting that hour', () {
      final slots = ReminderSchedule.hourlySlots(
        hour: 9,
        minute: 0,
        everyMinutes: 60,
        until: 17 * 60,
      );

      expect(slots.first, 9 * 60);
      expect(slots.last, 17 * 60);
      expect(slots.length, 9);
    });

    test('an until before the start means the end of the day', () {
      final slots = ReminderSchedule.hourlySlots(
        hour: 20,
        minute: 0,
        everyMinutes: 60,
        until: 8 * 60,
      );

      expect(slots, [20 * 60, 21 * 60, 22 * 60, 23 * 60]);
    });

    test('the cap shares the slots between the chosen days', () {
      expect(ReminderSchedule.hourlyCap(5), 12);
      expect(ReminderSchedule.hourlyCap(7), 9);
      final slots = ReminderSchedule.hourlySlots(
        hour: 0,
        minute: 0,
        everyMinutes: 60,
        cap: ReminderSchedule.hourlyCap(5),
      );

      expect(slots.length, 12);
    });

    test('without hours it keeps the single time', () {
      expect(
        ReminderSchedule.hourlySlots(hour: 9, minute: 5, everyMinutes: 0),
        [9 * 60 + 5],
      );
    });

    test('every slot of every day gets its own id, and none overflow', () {
      final cap = ReminderSchedule.hourlyCap(7);
      final ids = <int>{
        for (var day = 0; day < 7; day++)
          for (var slot = 0; slot < cap; slot++)
            ReminderSchedule.notificationId('habit-1', 'rem-1', day * cap + slot),
      };
      final other = ReminderSchedule.notificationId('habit-1', 'rem-2', 0);

      expect(ids.length, 7 * cap);
      expect(7 * cap <= ReminderSchedule.slotsPerReminder, true);
      expect(ids.contains(other), false);
    });
  });

  group('todo reminders', () {
    final now = DateTime(2026, 8, 18, 10);

    test('a to-do with a time in the future fires at that time', () {
      expect(
        ReminderSchedule.todoFireAt(
          now: now,
          done: false,
          due: DateTime(2026, 8, 18),
          minutes: 18 * 60 + 30,
        ),
        DateTime(2026, 8, 18, 18, 30),
      );
    });

    test('nothing fires for a to-do that is done, late or has no time', () {
      final due = DateTime(2026, 8, 18);
      expect(
        ReminderSchedule.todoFireAt(
            now: now, done: true, due: due, minutes: 18 * 60),
        isNull,
      );
      expect(
        ReminderSchedule.todoFireAt(
            now: now, done: false, due: due, minutes: 8 * 60),
        isNull,
      );
      expect(
        ReminderSchedule.todoFireAt(now: now, done: false, due: due),
        isNull,
      );
      expect(
        ReminderSchedule.todoFireAt(now: now, done: false, minutes: 18 * 60),
        isNull,
      );
    });

    test('to-do ids are stable and stay clear of the habit ids', () {
      final first = ReminderSchedule.todoNotificationId('todo-1');

      expect(first, ReminderSchedule.todoNotificationId('todo-1'));
      expect(first == ReminderSchedule.todoNotificationId('todo-2'), false);
      expect(first > ReminderSchedule.todoIdBase - 1, true);
      expect(
        ReminderSchedule.notificationId('habit-1', 'rem-1', 63) <
            ReminderSchedule.todoIdBase,
        true,
      );
    });
  });
}
