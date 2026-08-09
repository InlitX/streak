import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/statistics/data/habit_stats.dart';

final _today = DateTime.now().atMidnight;

DateTime _ago(int days) => _today.subtract(Duration(days: days));

Habit _habit({
  required String id,
  required int daysOld,
  List<DateTime> done = const [],
  HabitInterval interval = HabitInterval.daily,
  List<int> scheduleWeekdays = const [],
  List<int> restDays = const [],
  HabitKind kind = HabitKind.positive,
}) =>
    Habit(
      id: id,
      name: id,
      color: const Color(0xFF00FF00),
      order: 0,
      kind: kind,
      interval: interval,
      scheduleWeekdays: scheduleWeekdays,
      restDays: restDays,
      createdAt: _ago(daysOld),
      completions: {
        for (final day in done)
          day.dayKey: Completion(date: day.dayKey, hour: 9, count: 1),
      },
    );

({int current, int best}) _streak(List<Habit> habits) =>
    HabitStats.perfectStreakOf(habits, _today);

void main() {
  test('every habit done every day keeps the streak', () {
    final days = [for (var i = 0; i <= 4; i++) _ago(i)];
    final streak = _streak([
      _habit(id: 'a', daysOld: 4, done: days),
      _habit(id: 'b', daysOld: 4, done: days),
    ]);

    expect(streak.current, 5);
    expect(streak.best, 5);
  });

  test('one habit missing breaks the day for everyone', () {
    final all = [for (var i = 0; i <= 4; i++) _ago(i)];
    final streak = _streak([
      _habit(id: 'a', daysOld: 4, done: all),
      _habit(
        id: 'b',
        daysOld: 4,
        done: all.where((d) => d != _ago(2)).toList(),
      ),
    ]);

    expect(streak.current, 2);
    expect(streak.best, 2);
  });

  test('today still pending does not break the streak', () {
    final streak = _streak([
      _habit(id: 'a', daysOld: 4, done: [_ago(1), _ago(2), _ago(3)]),
    ]);

    expect(streak.current, 3);
  });

  test('days where nothing was due are skipped, not broken', () {
    final mondays = [
      for (var i = 0; i <= 21; i++)
        if (_ago(i).weekday == DateTime.monday) _ago(i),
    ];
    final streak = _streak([
      _habit(
        id: 'a',
        daysOld: 21,
        interval: HabitInterval.weekdays,
        scheduleWeekdays: const [DateTime.monday],
        done: mondays,
      ),
    ]);

    expect(streak.current, mondays.length);
  });

  test('rest days do not break the streak', () {
    final habit = _habit(
      id: 'a',
      daysOld: 6,
      restDays: [_ago(2).weekday],
      done: [
        for (var i = 0; i <= 6; i++)
          if (_ago(i).weekday != _ago(2).weekday) _ago(i),
      ],
    );

    expect(_streak([habit]).current, 6);
  });

  test('a habit that did not exist yet does not break the day', () {
    final streak = _streak([
      _habit(id: 'old', daysOld: 5, done: [for (var i = 0; i <= 5; i++) _ago(i)]),
      _habit(id: 'new', daysOld: 1, done: [_ago(0), _ago(1)]),
    ]);

    expect(streak.current, 6);
  });

  test('the best streak survives a later break', () {
    final done = [
      for (var i = 2; i <= 8; i++) _ago(i),
    ]..removeWhere((day) => day == _ago(4));
    final streak = _streak([_habit(id: 'a', daysOld: 8, done: done)]);

    expect(streak.best, 4);
    expect(streak.current, 0);
  });

  test('an old habit with nothing logged stays inside the window', () {
    final streak = _streak([
      _habit(id: 'a', daysOld: 3650, kind: HabitKind.negative),
    ]);

    expect(streak.current, greaterThan(1800));
    expect(streak.current, lessThan(1830));
  });
}
