import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/quant_stats.dart';

final _now = DateTime(2026, 8, 12, 18, 30);

Habit _habit(Map<DateTime, double> log, {double target = 60}) => Habit(
      id: 'h',
      name: 'Read',
      color: const Color(0xFF00FF00),
      order: 0,
      kind: HabitKind.quantitative,
      unitLabel: 'min',
      perDayTarget: target,
      createdAt: DateTime(2025, 1, 1),
      completions: {
        for (final entry in log.entries)
          entry.key.dayKey: Completion(
            date: entry.key.dayKey,
            count: entry.value,
          ),
      },
    );

QuantStats _stats(
  Habit habit, {
  QuantRange range = QuantRange.week,
  int weekStart = DateTime.monday,
}) =>
    QuantStats.compute(
      habit: habit,
      range: range,
      now: _now,
      weekStart: weekStart,
    );

void main() {
  final habit = _habit({
    _now: 25,
    DateTime(2026, 8, 10): 90,
    DateTime(2026, 8, 3): 45,
    DateTime(2026, 6, 1): 20,
    DateTime(2025, 8, 3): 30,
  });

  test('today, week, month and total are separate windows', () {
    final stats = _stats(habit);

    expect(stats.today, 25);
    expect(stats.week, 115);
    expect(stats.month, 160);
    expect(stats.totals.total, 210);
  });

  test('a day below the goal still adds up', () {
    final stats = _stats(habit);

    expect(stats.totals.loggedDays, 5);
    expect(stats.totals.goalDays, 1);
    expect(stats.totals.best, 90);
    expect(stats.totals.average, 42);
  });

  test('the average divides by the days with a record', () {
    final stats = _stats(_habit({_now: 25, DateTime(2026, 8, 10): 90}));

    expect(stats.totals.loggedDays, 2);
    expect(stats.totals.average, 57.5);
  });

  test('the week starts on the day the user picked', () {
    final sunday = _habit({DateTime(2026, 8, 9): 25});

    expect(_stats(sunday).week, 0);
    expect(_stats(sunday, weekStart: DateTime.sunday).week, 25);
  });

  test('the series buckets the amount by day inside the week', () {
    final stats = _stats(habit);

    expect(stats.series.length, 7);
    expect(stats.series[0], 90);
    expect(stats.series[2], 25);
    expect(stats.rangeTotal, 115);
  });

  test('the year range buckets by month and drops other years', () {
    final stats = _stats(habit, range: QuantRange.year);

    expect(stats.series.length, 12);
    expect(stats.series[5], 20);
    expect(stats.series[7], 160);
    expect(stats.rangeTotal, 180);
  });

  test('days ahead of today and empty records do not count', () {
    final stats = _stats(_habit({
      _now: 25,
      DateTime(2026, 8, 11): 0,
      DateTime(2026, 8, 14): 50,
    }));

    expect(stats.totals.total, 25);
    expect(stats.totals.loggedDays, 1);
    expect(stats.series[4], 0);
  });

  test('a habit with no records reports zeros instead of dividing by them', () {
    final stats = _stats(_habit(const {}));

    expect(stats.totals.total, 0);
    expect(stats.totals.average, 0);
    expect(stats.totals.best, 0);
    expect(stats.rangeTotal, 0);
  });

  test('the total behind the link leaves out the days ahead', () {
    final today = DateTime.now();
    final habit = _habit({
      today.subtract(const Duration(days: 1)): 5,
      today.add(const Duration(days: 1)): 7,
    });

    expect(QuantStats.totalsOf(habit, today).total, 5);
  });
}
