import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

Habit _habit({
  required HabitInterval interval,
  required int frequency,
  List<DateTime> done = const [],
  int daysOld = 90,
  List<int> restDays = const [],
}) =>
    Habit(
      id: 'h',
      name: 'Gym',
      color: const Color(0xFF00FF00),
      order: 0,
      interval: interval,
      targetFrequency: frequency,
      restDays: restDays,
      createdAt: AppClock.now().addDays(-daysOld),
      completions: {
        for (final day in done)
          day.dayKey: Completion(date: day.dayKey, count: 1, hour: 9),
      },
    );

void main() {
  final today = AppClock.now().atMidnight;
  final monday = today.startOfWeek(DateTime.monday);

  group('a week that already met its target', () {
    test('the days left over are covered, the done ones are not', () {
      final habit = _habit(
        interval: HabitInterval.weekly,
        frequency: 3,
        done: [monday, monday.addDays(1), monday.addDays(2)],
      );

      expect(habit.isCoveredOn(monday), isFalse, reason: 'ese dia si se hizo');
      expect(habit.isCompletedOn(monday), isTrue);
      for (var i = 3; i < 7; i++) {
        final day = monday.addDays(i);
        if (day.isAfter(today)) continue;
        expect(habit.isCoveredOn(day), isTrue, reason: 'dia $i');
      }
    });

    test('one short of the target covers nothing', () {
      final habit = _habit(
        interval: HabitInterval.weekly,
        frequency: 3,
        done: [monday, monday.addDays(1)],
      );
      for (var i = 0; i < 7; i++) {
        expect(habit.isCoveredOn(monday.addDays(i)), isFalse, reason: 'dia $i');
      }
    });

    test('a week of its own does not cover the next one', () {
      final last = monday.addDays(-7);
      final habit = _habit(
        interval: HabitInterval.weekly,
        frequency: 2,
        done: [last, last.addDays(1)],
      );
      expect(habit.isCoveredOn(last.addDays(3)), isTrue);
      expect(habit.isCoveredOn(monday), isFalse);
    });

    test('it never reaches into days that have not arrived', () {
      final habit = _habit(
        interval: HabitInterval.weekly,
        frequency: 1,
        done: [today],
      );
      expect(habit.isCoveredOn(today.addDays(1)), isFalse);
    });

    test('a monthly habit counts its own month', () {
      final first = DateTime(today.year, today.month);
      final days = [for (var i = 0; i < 2; i++) first.addDays(i)];
      final habit = _habit(
        interval: HabitInterval.monthly,
        frequency: 2,
        done: days,
        daysOld: 400,
      );
      expect(habit.isCoveredOn(today), today != days.first && today != days[1]);
      expect(
        habit.isCoveredOn(first.addDays(-1)),
        isFalse,
        reason: 'el mes anterior no se cubre',
      );
    });

    test('a daily habit is never covered', () {
      final habit = _habit(
        interval: HabitInterval.daily,
        frequency: 1,
        done: [monday, monday.addDays(1), monday.addDays(2)],
      );
      for (var i = 0; i < 7; i++) {
        expect(habit.isCoveredOn(monday.addDays(i)), isFalse);
      }
    });

    test('a rest day stays a rest day, not a covered one', () {
      final habit = _habit(
        interval: HabitInterval.weekly,
        frequency: 1,
        done: [monday],
        restDays: [DateTime.sunday],
      );
      final sunday = monday.addDays(6);
      expect(habit.isCoveredOn(sunday), isFalse);
    });
  });

  group('what a covered day means for the rest of the app', () {
    test('nothing is pending today once the target is met', () {
      final habit = _habit(
        interval: HabitInterval.weekly,
        frequency: 1,
        done: [monday],
      );
      if (today == monday) return;
      expect(habit.isCoveredOn(today), isTrue);
      expect(habit.isDoneForNow, isTrue);
    });

    test('the streak still only counts weeks that met the target', () {
      final habit = _habit(
        interval: HabitInterval.weekly,
        frequency: 3,
        done: [monday, monday.addDays(1), monday.addDays(2)],
      );
      expect(habit.currentStreak, 1);
    });
  });
}
