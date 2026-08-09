import 'package:flutter/foundation.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/data/focus_session.dart';

enum FocusRange { week, month, year }

@immutable
class FocusStats {
  const FocusStats({
    required this.todaySeconds,
    required this.weekSeconds,
    required this.monthSeconds,
    required this.totalSeconds,
    required this.sessionCount,
    required this.buckets,
    required this.series,
    required this.perHabit,
  });

  final int todaySeconds;
  final int weekSeconds;
  final int monthSeconds;
  final int totalSeconds;
  final int sessionCount;
  final List<DateTime> buckets;
  final List<int> series;
  final Map<String, int> perHabit;

  int get averageSeconds =>
      sessionCount == 0 ? 0 : totalSeconds ~/ sessionCount;

  int get rangeSeconds => series.fold(0, (sum, value) => sum + value);

  int get bestBucket {
    var best = 0;
    for (var i = 1; i < series.length; i++) {
      if (series[i] > series[best]) best = i;
    }
    return best;
  }

  static List<DateTime> _bucketsFor(
    FocusRange range,
    DateTime today,
    int weekStart,
  ) {
    switch (range) {
      case FocusRange.week:
        final first = today.startOfWeek(weekStart);
        return [for (var i = 0; i < 7; i++) first.add(Duration(days: i))];
      case FocusRange.month:
        final days = DateTime(today.year, today.month + 1, 0).day;
        return [
          for (var i = 1; i <= days; i++) DateTime(today.year, today.month, i),
        ];
      case FocusRange.year:
        return [for (var m = 1; m <= 12; m++) DateTime(today.year, m)];
    }
  }

  static int _bucketOf(
    FocusRange range,
    List<DateTime> buckets,
    DateTime date,
  ) {
    final day = date.atMidnight;
    if (range == FocusRange.year) {
      return day.year == buckets.first.year ? day.month - 1 : -1;
    }
    final index = day.epochDay - buckets.first.epochDay;
    return index >= 0 && index < buckets.length ? index : -1;
  }

  static FocusStats compute({
    required List<FocusSession> sessions,
    required FocusRange range,
    required DateTime now,
    required int weekStart,
    String? habitId,
  }) {
    final scoped = habitId == null
        ? sessions
        : sessions.where((s) => s.habitId == habitId).toList();

    final today = now.atMidnight;
    final weekFrom = today.startOfWeek(weekStart);
    final buckets = _bucketsFor(range, today, weekStart);
    final series = List<int>.filled(buckets.length, 0);
    final perHabit = <String, int>{};

    var todaySeconds = 0;
    var weekSeconds = 0;
    var monthSeconds = 0;
    var totalSeconds = 0;

    for (final session in scoped) {
      final day = session.startedAt.atMidnight;
      totalSeconds += session.seconds;
      if (day.isSameDay(today)) todaySeconds += session.seconds;
      final offset = day.epochDay - weekFrom.epochDay;
      if (offset >= 0 && offset < 7) weekSeconds += session.seconds;
      if (day.year == today.year && day.month == today.month) {
        monthSeconds += session.seconds;
      }

      final index = _bucketOf(range, buckets, session.startedAt);
      if (index < 0) continue;
      series[index] += session.seconds;
      perHabit[session.habitId] =
          (perHabit[session.habitId] ?? 0) + session.seconds;
    }

    return FocusStats(
      todaySeconds: todaySeconds,
      weekSeconds: weekSeconds,
      monthSeconds: monthSeconds,
      totalSeconds: totalSeconds,
      sessionCount: scoped.length,
      buckets: buckets,
      series: series,
      perHabit: perHabit,
    );
  }
}
