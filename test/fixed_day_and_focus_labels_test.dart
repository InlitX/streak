import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/data/focus_stats.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/services/reminder_schedule.dart';

Habit _monthly(DateTime start, {int every = 1}) => Habit(
      id: 'bill',
      name: 'Pay the bill',
      color: const Color(0xFF00FF00),
      order: 0,
      interval: HabitInterval.everyXDays,
      scheduleUnit: ScheduleUnit.months,
      scheduleEvery: every,
      scheduleStart: start,
      createdAt: start,
    );

FocusSession _session(String id, {String label = '', int minutes = 30}) =>
    FocusSession(
      id: id,
      habitId: 'study',
      targetMinutes: minutes,
      seconds: minutes * 60,
      completed: true,
      startedAt: DateTime(2026, 8, 12, 10),
      label: label,
    );

void main() {
  group('a habit on a fixed day of the month', () {
    test('every month on the 15th is due only on the 15th', () {
      final habit = _monthly(DateTime(2026, 1, 15));
      expect(habit.isScheduledOn(DateTime(2026, 2, 15)), isTrue);
      expect(habit.isScheduledOn(DateTime(2026, 3, 15)), isTrue);
      expect(habit.isScheduledOn(DateTime(2026, 2, 14)), isFalse);
      expect(habit.isScheduledOn(DateTime(2026, 2, 16)), isFalse);
    });

    test('the 31st falls on the last day of shorter months', () {
      final habit = _monthly(DateTime(2026, 1, 31));
      expect(habit.isScheduledOn(DateTime(2026, 2, 28)), isTrue);
      expect(habit.isScheduledOn(DateTime(2026, 4, 30)), isTrue);
      expect(habit.isScheduledOn(DateTime(2026, 5, 31)), isTrue);
      expect(habit.isScheduledOn(DateTime(2026, 5, 30)), isFalse);
    });
  });

  group('reminders that follow the habit days', () {
    test('a monthly habit rings once a month at the reminder time', () {
      final habit = _monthly(DateTime(2026, 1, 15));
      final moments = ReminderSchedule.onHabitDays(
        from: DateTime(2026, 1, 20, 12),
        due: (day) => !habit.isOffDay(day),
        slots: const [9 * 60 + 30],
        limit: 3,
      );
      expect(moments, [
        DateTime(2026, 2, 15, 9, 30),
        DateTime(2026, 3, 15, 9, 30),
        DateTime(2026, 4, 15, 9, 30),
      ]);
    });

    test('a slot that already passed today waits for the next due day', () {
      final habit = _monthly(DateTime(2026, 1, 15));
      final moments = ReminderSchedule.onHabitDays(
        from: DateTime(2026, 2, 15, 10),
        due: (day) => !habit.isOffDay(day),
        slots: const [9 * 60, 18 * 60],
        limit: 2,
      );
      expect(moments, [
        DateTime(2026, 2, 15, 18),
        DateTime(2026, 3, 15, 9),
      ]);
    });

    test('a schedule with no due days in reach gives no reminders', () {
      final moments = ReminderSchedule.onHabitDays(
        from: DateTime(2026, 1, 1),
        due: (_) => false,
        slots: const [600],
        limit: 5,
      );
      expect(moments, isEmpty);
    });
  });

  group('focus labels', () {
    test('a label survives a backup, and old sessions have none', () {
      final map = _session('a', label: 'Maths').toMap();
      expect(FocusSession.fromMap(map).label, 'Maths');
      expect(FocusSession.fromMap(map..remove('label')).label, '');
    });

    test('a session cut at midnight keeps its label on every piece', () {
      final late = FocusSession(
        id: 'night',
        habitId: '',
        targetMinutes: 0,
        seconds: 2 * 3600,
        completed: true,
        startedAt: DateTime(2026, 8, 12, 23),
        label: 'Reading',
      );
      final pieces = late.split();
      expect(pieces.length, 2);
      expect(pieces.every((piece) => piece.label == 'Reading'), isTrue);
    });

    test('a session started less than a second before midnight still splits',
        () {
      final edge = FocusSession(
        id: 'edge',
        habitId: '',
        targetMinutes: 50,
        seconds: 50 * 60,
        completed: true,
        startedAt: DateTime(2026, 10, 8, 23, 59, 59, 500),
      );
      final pieces = edge.split();
      expect(pieces.fold(0, (sum, piece) => sum + piece.seconds), 50 * 60);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('time adds up per label and unlabelled sessions stay out', () {
      final stats = FocusStats.compute(
        sessions: [
          _session('a', label: 'Maths', minutes: 30),
          _session('b', label: 'Physics', minutes: 50),
          _session('c', label: 'Maths', minutes: 40),
          _session('d', minutes: 20),
        ],
        range: FocusRange.week,
        now: DateTime(2026, 8, 12, 18),
        weekStart: DateTime.monday,
      );
      expect(stats.perLabel, {'Maths': 70 * 60, 'Physics': 50 * 60});
      expect(stats.labelRanking.first.key, 'Maths');
    });
  });
}
