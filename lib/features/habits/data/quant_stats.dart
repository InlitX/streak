import 'package:flutter/foundation.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

enum QuantRange { week, month, year }

typedef QuantTotals = ({
  double total,
  double average,
  double best,
  int loggedDays,
  int goalDays,
});

@immutable
class QuantStats {
  const QuantStats({
    required this.totals,
    required this.today,
    required this.week,
    required this.month,
    required this.buckets,
    required this.series,
  });

  final QuantTotals totals;
  final double today;
  final double week;
  final double month;
  final List<DateTime> buckets;
  final List<double> series;

  double get rangeTotal =>
      roundAmount(series.fold(0, (sum, value) => sum + value));

  static List<DateTime> _bucketsFor(
    QuantRange range,
    DateTime today,
    int weekStart,
  ) {
    switch (range) {
      case QuantRange.week:
        final first = today.startOfWeek(weekStart);
        return [for (var i = 0; i < 7; i++) first.add(Duration(days: i))];
      case QuantRange.month:
        final days = DateTime(today.year, today.month + 1, 0).day;
        return [
          for (var i = 1; i <= days; i++) DateTime(today.year, today.month, i),
        ];
      case QuantRange.year:
        return [for (var m = 1; m <= 12; m++) DateTime(today.year, m)];
    }
  }

  static int _bucketOf(
    QuantRange range,
    List<DateTime> buckets,
    DateTime day,
  ) {
    if (range == QuantRange.year) {
      return day.year == buckets.first.year ? day.month - 1 : -1;
    }
    final index = day.epochDay - buckets.first.epochDay;
    return index >= 0 && index < buckets.length ? index : -1;
  }

  static bool _counts(Completion entry, DateTime day, DateTime today) =>
      entry.count > 0 && !day.isAfter(today);

  static QuantTotals totalsOf(Habit habit, DateTime now) {
    final today = now.atMidnight;
    var total = 0.0;
    var best = 0.0;
    var loggedDays = 0;
    var goalDays = 0;

    for (final entry in habit.completions.values) {
      if (!_counts(entry, parseDayKey(entry.date), today)) continue;
      total += entry.count;
      loggedDays++;
      if (entry.count >= habit.perDayTarget) goalDays++;
      if (entry.count > best) best = entry.count;
    }

    return (
      total: roundAmount(total),
      average: loggedDays == 0 ? 0 : roundAmount(total / loggedDays),
      best: roundAmount(best),
      loggedDays: loggedDays,
      goalDays: goalDays,
    );
  }

  static QuantStats compute({
    required Habit habit,
    required QuantRange range,
    required DateTime now,
    required int weekStart,
  }) {
    final today = now.atMidnight;
    final weekFrom = today.startOfWeek(weekStart);
    final buckets = _bucketsFor(range, today, weekStart);
    final series = List<double>.filled(buckets.length, 0);

    var todayAmount = 0.0;
    var week = 0.0;
    var month = 0.0;

    for (final entry in habit.completions.values) {
      final day = parseDayKey(entry.date);
      if (!_counts(entry, day, today)) continue;

      if (day.isSameDay(today)) todayAmount += entry.count;

      final offset = day.epochDay - weekFrom.epochDay;
      if (offset >= 0 && offset < 7) week += entry.count;
      if (day.year == today.year && day.month == today.month) {
        month += entry.count;
      }

      final index = _bucketOf(range, buckets, day);
      if (index >= 0) series[index] += entry.count;
    }

    return QuantStats(
      totals: totalsOf(habit, now),
      today: roundAmount(todayAmount),
      week: roundAmount(week),
      month: roundAmount(month),
      buckets: buckets,
      series: series,
    );
  }
}
