import 'package:flutter/foundation.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';

@immutable
class HabitStats {
  const HabitStats({
    required this.dailyCounts,
    required this.monthly,
    required this.weekday,
    required this.hours,
    required this.hourSamples,
    required this.streakSeries,
    required this.total,
    required this.activeDays,
    required this.currentStreak,
    required this.bestStreak,
    required this.monthRate,
  });

  final Map<String, int> dailyCounts;
  final List<int> monthly;
  final List<int> weekday;
  final List<int> hours;
  final int hourSamples;
  final List<double> streakSeries;
  final int total;
  final int activeDays;
  final int currentStreak;
  final int bestStreak;
  final int monthRate;

  static HabitStats compute(List<Habit> habits, int year) {
    final daily = <String, int>{};
    final monthly = List<int>.filled(12, 0);
    final weekday = List<int>.filled(7, 0);
    final hours = List<int>.filled(24, 0);
    var total = 0;
    var hourSamples = 0;

    for (final habit in habits) {
      if (habit.kind == HabitKind.negative) {
        for (var m = 1; m <= 12; m++) {
          final daysInMonth = DateTime(year, m + 1, 0).day;
          for (var d = 1; d <= daysInMonth; d++) {
            final date = DateTime(year, m, d);
            if (!habit.isCompletedOn(date)) continue;
            daily[date.dayKey] = (daily[date.dayKey] ?? 0) + 1;
            monthly[m - 1]++;
            weekday[date.weekday - 1]++;
            total++;
          }
        }
        continue;
      }
      for (final entry in habit.completions.values) {
        if (entry.count < habit.effectiveTarget) continue;
        final date = parseDayKey(entry.date);
        if (date.year != year) continue;
        daily[entry.date] = (daily[entry.date] ?? 0) + 1;
        monthly[date.month - 1]++;
        weekday[date.weekday - 1]++;
        total++;
        if (entry.hour != null) {
          hours[entry.hour!.clamp(0, 23)]++;
          hourSamples++;
        }
      }
    }

    final today = DateTime.now().atMidnight;
    var running = 0;
    final streakSeries = List<double>.generate(90, (i) {
      final date = today.subtract(Duration(days: 89 - i));
      for (final habit in habits) {
        if (habit.isCompletedOn(date)) running++;
      }
      return running.toDouble();
    });

    var done = 0;
    for (var i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      for (final habit in habits) {
        if (habit.isCompletedOn(date)) done++;
      }
    }
    final possible = habits.length * 30;
    final monthRate = possible == 0 ? 0 : (done / possible * 100).round();

    final currentStreak = habits
        .map((h) => h.currentStreak)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final bestStreak = habits
        .map((h) => h.longestStreak)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return HabitStats(
      dailyCounts: daily,
      monthly: monthly,
      weekday: weekday,
      hours: hours,
      hourSamples: hourSamples,
      streakSeries: streakSeries,
      total: total,
      activeDays: daily.length,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      monthRate: monthRate,
    );
  }
}
