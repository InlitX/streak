import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/data/focus_stats.dart';

final _now = DateTime(2026, 8, 12, 18, 30);

FocusSession _session({
  required String habitId,
  required DateTime startedAt,
  required int minutes,
}) =>
    FocusSession(
      id: '$habitId-${startedAt.toIso8601String()}',
      habitId: habitId,
      targetMinutes: minutes,
      seconds: minutes * 60,
      completed: true,
      startedAt: startedAt,
    );

FocusStats _stats(
  List<FocusSession> sessions, {
  FocusRange range = FocusRange.week,
  int weekStart = DateTime.monday,
  String? habitId,
  int offset = 0,
}) =>
    FocusStats.compute(
      sessions: sessions,
      range: range,
      now: _now,
      weekStart: weekStart,
      habitId: habitId,
      offset: offset,
    );

void main() {
  test('today, week, month and total are separate windows', () {
    final stats = _stats([
      _session(habitId: 'a', startedAt: _now, minutes: 30),
      _session(
        habitId: 'a',
        startedAt: DateTime(2026, 8, 10, 9),
        minutes: 60,
      ),
      _session(habitId: 'a', startedAt: DateTime(2026, 8, 3, 9), minutes: 45),
      _session(habitId: 'a', startedAt: DateTime(2026, 6, 1, 9), minutes: 20),
    ]);

    expect(stats.todaySeconds, 30 * 60);
    expect(stats.weekSeconds, 90 * 60);
    expect(stats.monthSeconds, 135 * 60);
    expect(stats.totalSeconds, 155 * 60);
    expect(stats.sessionCount, 4);
  });

  test('the week starts on the day the user picked', () {
    final sunday = DateTime(2026, 8, 9, 20);
    final monFirst = _stats([
      _session(habitId: 'a', startedAt: sunday, minutes: 25),
    ]);
    final sunFirst = _stats(
      [_session(habitId: 'a', startedAt: sunday, minutes: 25)],
      weekStart: DateTime.sunday,
    );

    expect(monFirst.weekSeconds, 0);
    expect(sunFirst.weekSeconds, 25 * 60);
  });

  test('the series buckets sessions by day inside the week', () {
    final stats = _stats([
      _session(habitId: 'a', startedAt: DateTime(2026, 8, 10, 9), minutes: 60),
      _session(habitId: 'a', startedAt: DateTime(2026, 8, 10, 20), minutes: 30),
      _session(habitId: 'a', startedAt: _now, minutes: 15),
    ]);

    expect(stats.series.length, 7);
    expect(stats.series[0], 90 * 60);
    expect(stats.series[2], 15 * 60);
    expect(stats.rangeSeconds, 105 * 60);
    expect(stats.bestBucket, 0);
  });

  test('the year range buckets by month', () {
    final stats = _stats(
      [
        _session(habitId: 'a', startedAt: DateTime(2026, 2, 3, 9), minutes: 50),
        _session(habitId: 'a', startedAt: _now, minutes: 10),
        _session(habitId: 'a', startedAt: DateTime(2025, 8, 3, 9), minutes: 90),
      ],
      range: FocusRange.year,
    );

    expect(stats.series.length, 12);
    expect(stats.series[1], 50 * 60);
    expect(stats.series[7], 10 * 60);
    expect(stats.rangeSeconds, 60 * 60);
    expect(stats.totalSeconds, 150 * 60);
  });

  test('time per habit only counts the selected range', () {
    final stats = _stats([
      _session(habitId: 'a', startedAt: _now, minutes: 30),
      _session(habitId: 'b', startedAt: DateTime(2026, 8, 11, 9), minutes: 20),
      _session(habitId: 'b', startedAt: DateTime(2026, 5, 1, 9), minutes: 90),
      _session(habitId: '', startedAt: _now, minutes: 10),
    ]);

    expect(stats.perHabit['a'], 30 * 60);
    expect(stats.perHabit['b'], 20 * 60);
    expect(stats.perHabit[''], 10 * 60);
  });

  test('filtering by habit ignores every other session', () {
    final stats = _stats(
      [
        _session(habitId: 'a', startedAt: _now, minutes: 30),
        _session(habitId: 'b', startedAt: _now, minutes: 90),
      ],
      habitId: 'a',
    );

    expect(stats.totalSeconds, 30 * 60);
    expect(stats.sessionCount, 1);
    expect(stats.averageSeconds, 30 * 60);
  });

  test('an empty history reports zeros instead of dividing by it', () {
    final stats = _stats([]);

    expect(stats.averageSeconds, 0);
    expect(stats.rangeSeconds, 0);
    expect(stats.bestBucket, 0);
  });

  test('the offset walks whole weeks, months and years', () {
    final sessions = [
      _session(habitId: 'a', startedAt: _now, minutes: 30),
      _session(
        habitId: 'a',
        startedAt: _now.subtract(const Duration(days: 7)),
        minutes: 40,
      ),
      _session(habitId: 'a', startedAt: DateTime(2026, 7, 3), minutes: 50),
      _session(habitId: 'a', startedAt: DateTime(2025, 5, 9), minutes: 60),
    ];

    expect(_stats(sessions).rangeSeconds, 30 * 60);
    expect(_stats(sessions, offset: -1).rangeSeconds, 40 * 60);
    expect(_stats(sessions, offset: -1).rangeCount, 1);

    final lastMonth = _stats(sessions, range: FocusRange.month, offset: -1);
    expect(lastMonth.buckets.first, DateTime(2026, 7, 1));
    expect(lastMonth.rangeSeconds, 50 * 60);

    final lastYear = _stats(sessions, range: FocusRange.year, offset: -1);
    expect(lastYear.buckets.first.year, 2025);
    expect(lastYear.rangeSeconds, 60 * 60);
    expect(lastYear.series[4], 60 * 60);
  });

  test('a period with nothing in it reports zeros, not the whole history', () {
    final stats = _stats(
      [_session(habitId: 'a', startedAt: _now, minutes: 30)],
      offset: -3,
    );

    expect(stats.rangeSeconds, 0);
    expect(stats.rangeCount, 0);
    expect(stats.totalSeconds, 30 * 60);
  });
}
