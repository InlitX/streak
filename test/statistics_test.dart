import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/statistics/data/habit_stats.dart';

Habit _habit({
  required HabitKind kind,
  required DateTime createdAt,
  Map<String, Completion> completions = const {},
}) =>
    Habit(
      id: 'h',
      name: 'Test',
      color: const Color(0xFF00FF00),
      order: 0,
      kind: kind,
      completions: completions,
      createdAt: createdAt,
    );

int _expectedCleanDays(Habit habit, int year) {
  final today = DateTime.now().atMidnight;
  var day = habit.createdAt.atMidnight;
  var count = 0;
  while (!day.isAfter(today)) {
    if (day.year == year && !habit.completions.containsKey(day.dayKey)) {
      count++;
    }
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return count;
}

void main() {
  final today = DateTime.now();
  final year = today.year;

  group('HabitStats negatives', () {
    test('clean days count as completions and fill the heatmap', () {
      final createdAt = today.subtract(const Duration(days: 5));
      final habit = _habit(kind: HabitKind.negative, createdAt: createdAt);

      final stats = HabitStats.compute([habit], year);
      final expected = _expectedCleanDays(habit, year);

      expect(expected, greaterThan(0));
      expect(stats.total, expected);
      expect(stats.dailyCounts.length, expected);
      expect(stats.dailyCounts[today.dayKey], 1);
      expect(stats.monthly.fold<int>(0, (a, b) => a + b), expected);
      expect(stats.weekday.fold<int>(0, (a, b) => a + b), expected);
    });

    test('relapse days are excluded, clean neighbours are not', () {
      final createdAt = today.subtract(const Duration(days: 6));
      final relapse = today.subtract(const Duration(days: 2));
      final clean = today.subtract(const Duration(days: 1));
      final habit = _habit(
        kind: HabitKind.negative,
        createdAt: createdAt,
        completions: {relapse.dayKey: Completion(date: relapse.dayKey)},
      );

      final stats = HabitStats.compute([habit], year);

      expect(stats.dailyCounts.containsKey(relapse.dayKey), isFalse);
      expect(stats.dailyCounts[clean.dayKey], 1);
      expect(stats.total, _expectedCleanDays(habit, year));
    });

    test('days before createdAt are not counted', () {
      final createdAt = today.subtract(const Duration(days: 3));
      final habit = _habit(kind: HabitKind.negative, createdAt: createdAt);

      final stats = HabitStats.compute([habit], year);
      final before = createdAt.subtract(const Duration(days: 1));

      expect(stats.dailyCounts.containsKey(before.dayKey), isFalse);
    });

    test('an all-relapse negative habit reports zero', () {
      final createdAt = today.subtract(const Duration(days: 1));
      final habit = _habit(
        kind: HabitKind.negative,
        createdAt: createdAt,
        completions: {
          today.dayKey: Completion(date: today.dayKey),
          createdAt.dayKey: Completion(date: createdAt.dayKey),
        },
      );

      final stats = HabitStats.compute([habit], year);

      expect(stats.total, 0);
      expect(stats.dailyCounts, isEmpty);
    });
  });

  group('HabitStats positives (unchanged)', () {
    test('completions are counted with their hour', () {
      final createdAt = today.subtract(const Duration(days: 10));
      final d1 = today;
      final d2 = today.subtract(const Duration(days: 1));
      final habit = _habit(
        kind: HabitKind.positive,
        createdAt: createdAt,
        completions: {
          d1.dayKey: Completion(date: d1.dayKey, hour: 8),
          d2.dayKey: Completion(date: d2.dayKey, hour: 9),
        },
      );

      final stats = HabitStats.compute([habit], year);

      final inYear = [d1, d2].where((d) => d.year == year).length;
      expect(stats.total, inYear);
      expect(stats.hourSamples, inYear);
    });

    test('unmet target does not count', () {
      final createdAt = today.subtract(const Duration(days: 3));
      final habit = Habit(
        id: 'h',
        name: 'Test',
        color: const Color(0xFF00FF00),
        order: 0,
        perDayTarget: 3,
        createdAt: createdAt,
        completions: {
          today.dayKey: Completion(date: today.dayKey, count: 1),
        },
      );

      final stats = HabitStats.compute([habit], year);

      expect(stats.total, 0);
    });
  });

  group('totals per period', () {
    final today = DateTime.now().atMidnight;
    final weekStart = today.startOfWeek(DateTime.monday);

    test('a positive habit counts the week, the month and everything', () {
      final days = {
        today,
        weekStart,
        DateTime(today.year, today.month, 1),
        DateTime(today.year - 1, 6, 15),
      }.toList();

      final habit = _habit(
        kind: HabitKind.positive,
        createdAt: DateTime(today.year - 2),
        completions: {
          for (final day in days)
            day.dayKey: Completion(date: day.dayKey, count: 1),
        },
      );

      final stats = HabitStats.compute([habit], today.year);
      final inWeek = days.where((d) => !d.isBefore(weekStart)).length;
      final inMonth = days
          .where((d) => d.year == today.year && d.month == today.month)
          .length;
      final inYear = days.where((d) => d.year == today.year).length;

      expect(stats.weekDone, inWeek);
      expect(stats.monthDone, inMonth);
      expect(stats.total, inYear);
      expect(stats.allDone, days.length);
    });

    test('the year row follows the year you are looking at', () {
      final last = DateTime(today.year - 1, 6, 15);
      final habit = _habit(
        kind: HabitKind.positive,
        createdAt: DateTime(today.year - 2),
        completions: {
          last.dayKey: Completion(date: last.dayKey, count: 1),
        },
      );

      expect(HabitStats.compute([habit], today.year).total, 0);
      expect(HabitStats.compute([habit], today.year - 1).total, 1);
      expect(HabitStats.compute([habit], today.year).allDone, 1);
    });

    test('an avoid habit counts its clean days, not its relapses', () {
      final habit = _habit(
        kind: HabitKind.negative,
        createdAt: today.addDays(-9),
      );
      final stats = HabitStats.compute([habit], today.year);

      expect(stats.allDone, habit.cleanDays);
      expect(stats.weekDone, today.epochDay - weekStart.epochDay + 1);
      expect(stats.monthDone, today.day.clamp(0, 10));
    });

    test('nothing logged means zeros everywhere', () {
      final habit = _habit(
        kind: HabitKind.positive,
        createdAt: today.addDays(-30),
      );
      final stats = HabitStats.compute([habit], today.year);
      expect(stats.weekDone, 0);
      expect(stats.monthDone, 0);
      expect(stats.allDone, 0);
    });
  });
}
