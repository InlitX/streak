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
    required this.perHabit,
    required this.perfectDays,
    required this.perfectStreak,
    required this.bestPerfectStreak,
    required this.total,
    required this.activeDays,
    required this.currentStreak,
    required this.bestStreak,
    required this.monthRate,
    required this.consistency,
    required this.weekDone,
    required this.monthDone,
    required this.allDone,
  });

  static const window = 90;
  static const perfectWindow = 1825;

  static final empty = HabitStats(
    dailyCounts: const {},
    monthly: List<int>.filled(12, 0),
    weekday: List<int>.filled(7, 0),
    hours: List<int>.filled(24, 0),
    hourSamples: 0,
    streakSeries: List<double>.filled(window, 0),
    perHabit: const {},
    perfectDays: 0,
    perfectStreak: 0,
    bestPerfectStreak: 0,
    total: 0,
    activeDays: 0,
    currentStreak: 0,
    bestStreak: 0,
    monthRate: 0,
    consistency: 0,
    weekDone: 0,
    monthDone: 0,
    allDone: 0,
  );

  final Map<String, int> dailyCounts;
  final List<int> monthly;
  final List<int> weekday;
  final List<int> hours;
  final int hourSamples;
  final List<double> streakSeries;
  final Map<String, int> perHabit;
  final int perfectDays;
  final int perfectStreak;
  final int bestPerfectStreak;
  final int total;
  final int activeDays;
  final int currentStreak;
  final int bestStreak;
  final int monthRate;

  final int weekDone;
  final int monthDone;
  final int allDone;
  final int consistency;

  int get bestWeekday => _argMax(weekday);
  int get bestMonth => _argMax(monthly);
  int get peakHour => _argMax(hours);

  double get perWeek => activeDays == 0 ? 0 : total / (activeDays / 7);

  static int _countFor(Habit habit, int year) {
    var count = 0;
    if (habit.kind == HabitKind.negative) {
      for (var m = 1; m <= 12; m++) {
        final daysInMonth = DateTime(year, m + 1, 0).day;
        for (var d = 1; d <= daysInMonth; d++) {
          if (habit.isCompletedOn(DateTime(year, m, d))) count++;
        }
      }
      return count;
    }
    final today = AppClock.now().atMidnight;
    for (final entry in habit.completions.values) {
      if (entry.count < habit.effectiveTarget) continue;
      final date = parseDayKey(entry.date);
      if (date.year != year || date.isAfter(today)) continue;
      count++;
    }
    return count;
  }

  static List<double> _streakSeries(List<Habit> habits, DateTime today) {
    final start = today.addDays(-(window - 1));
    final series = List<double>.filled(window, 0);

    for (final habit in habits) {
      var run = 0;
      var cursor = start.addDays(-1);
      while (habit.isCompletedOn(cursor)) {
        run++;
        cursor = cursor.addDays(-1);
      }
      for (var i = 0; i < window; i++) {
        final day = start.addDays(i);
        run = habit.isCompletedOn(day) ? run + 1 : 0;
        if (run > series[i]) series[i] = run.toDouble();
      }
    }
    return series;
  }

  static bool _isDue(Habit habit, DateTime day) =>
      !day.isBefore(habit.startedAt) &&
      habit.isScheduledOn(day) &&
      !habit.isNeutralOn(day);

  static ({int current, int best}) perfectStreakOf(
    List<Habit> habits,
    DateTime today,
  ) {
    if (habits.isEmpty) return (current: 0, best: 0);

    var floor = habits
        .map((h) => h.startedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final limit =
        today.addDays(-perfectWindow).atMidnight;
    if (floor.isBefore(limit)) floor = limit;

    final days = today.epochDay - floor.epochDay;
    if (days < 0) return (current: 0, best: 0);

    var run = 0;
    var best = 0;
    for (var i = 0; i <= days; i++) {
      final day = DateTime(floor.year, floor.month, floor.day + i);
      final due = habits.where((h) => _isDue(h, day));
      if (due.isEmpty) continue;
      if (due.every((h) => h.isCompletedOn(day))) {
        run++;
        if (run > best) best = run;
      } else if (i < days) {
        run = 0;
      }
    }
    return (current: run, best: best);
  }

  static int _argMax(List<int> values) {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }

  static List<Habit> counted(List<Habit> habits) =>
      habits.where((h) => !h.tracking).toList();

  static HabitStats compute(List<Habit> habits, int year) {
    final today = AppClock.now().atMidnight;
    final daily = <String, int>{};
    final monthly = List<int>.filled(12, 0);
    final weekday = List<int>.filled(7, 0);
    final hours = List<int>.filled(24, 0);
    var total = 0;
    var hourSamples = 0;
    var weekDone = 0;
    var monthDone = 0;
    var allDone = 0;
    final weekFloor = today.startOfWeek(DateTime.monday);

    for (final habit in habits) {
      if (habit.kind == HabitKind.negative) {
        allDone += habit.cleanDays;
        for (var i = 0; i < today.day; i++) {
          final day = today.addDays(-i);
          if (day.isBefore(habit.startedAt)) break;
          if (habit.isCompletedOn(day)) monthDone++;
        }
        for (var day = today;
            !day.isBefore(weekFloor) && !day.isBefore(habit.startedAt);
            day = day.addDays(-1)) {
          if (habit.isCompletedOn(day)) weekDone++;
        }
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
        if (date.isAfter(today)) continue;
        allDone++;
        if (date.year == today.year && date.month == today.month) monthDone++;
        if (!date.isBefore(weekFloor)) weekDone++;
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

    final streakSeries = _streakSeries(habits, today);

    final perHabit = <String, int>{};
    for (final habit in habits) {
      perHabit[habit.id] = _countFor(habit, year);
    }

    var perfectDays = 0;
    for (final key in daily.keys) {
      final date = parseDayKey(key);
      final due = habits.where((h) => h.isScheduledOn(date));
      if (due.isNotEmpty && due.every((h) => h.isCompletedOn(date))) {
        perfectDays++;
      }
    }

    var done = 0;
    var possible = 0;
    for (var i = 0; i < 30; i++) {
      final date = today.addDays(-i);
      for (final habit in habits) {
        if (date.isBefore(habit.startedAt)) continue;
        if (!habit.isScheduledOn(date) || habit.isNeutralOn(date)) continue;
        possible++;
        if (habit.isCompletedOn(date)) done++;
      }
    }
    final monthRate = possible == 0 ? 0 : (done / possible * 100).round();

    final consistency = habits.isEmpty
        ? 0
        : (habits.map((h) => h.strength).reduce((a, b) => a + b) /
                habits.length *
                100)
            .round();

    final perfect = perfectStreakOf(habits, today);

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
      perHabit: perHabit,
      perfectDays: perfectDays,
      perfectStreak: perfect.current,
      bestPerfectStreak: perfect.best,
      total: total,
      activeDays: daily.length,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      monthRate: monthRate,
      consistency: consistency,
      weekDone: weekDone,
      monthDone: monthDone,
      allDone: allDone,
    );
  }
}
