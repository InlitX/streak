import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/statistics/data/habit_stats.dart';

final _today = DateTime.now();

Habit _habit({
  required int daysOld,
  List<DateTime> done = const [],
  HabitInterval interval = HabitInterval.daily,
  List<int> scheduleWeekdays = const [],
  List<int> restDays = const [],
}) =>
    Habit(
      id: 'h',
      name: 'Test',
      color: const Color(0xFF00FF00),
      order: 0,
      interval: interval,
      scheduleWeekdays: scheduleWeekdays,
      restDays: restDays,
      createdAt: _today.subtract(Duration(days: daysOld)),
      completions: {
        for (final day in done)
          day.dayKey: Completion(date: day.dayKey, hour: 9, count: 1),
      },
    );

List<DateTime> _every(int days, bool Function(DateTime) when) => [
      for (var i = 0; i < days; i++)
        if (when(_today.subtract(Duration(days: i))))
          _today.subtract(Duration(days: i)),
    ];

void main() {
  test('a habit done every day since it was created is at 100', () {
    final habit = _habit(daysOld: 3, done: _every(4, (_) => true));

    expect(habit.consistency, 100);
    expect(HabitStats.compute([habit], _today.year).monthRate, 100);
  });

  test('days before the habit existed do not count', () {
    final young = _habit(daysOld: 2, done: _every(3, (_) => true));
    final old = _habit(daysOld: 80, done: _every(3, (_) => true));

    expect(young.consistency, 100);
    expect(old.consistency, lessThan(50));
  });

  test('only the scheduled weekdays count', () {
    final weekdays = [1, 4, 6];
    final habit = _habit(
      daysOld: 60,
      interval: HabitInterval.weekdays,
      scheduleWeekdays: weekdays,
      done: _every(61, (day) => weekdays.contains(day.weekday)),
    );

    expect(habit.consistency, 100);
    expect(HabitStats.compute([habit], _today.year).monthRate, 100);
  });

  test('rest days are neither a hit nor a miss', () {
    final rest = _today.weekday;
    final habit = _habit(
      daysOld: 60,
      restDays: [rest],
      done: _every(61, (day) => day.weekday != rest),
    );

    expect(habit.consistency, 100);
  });

  test('missing every day leaves it at zero', () {
    final habit = _habit(daysOld: 60, done: [_today.subtract(const Duration(days: 59))]);

    expect(habit.consistency, lessThan(5));
  });
}
