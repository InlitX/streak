import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/data/focus_stats.dart';
import 'package:streak/features/focus/state/focus_controller.dart';

import 'support/app_harness.dart';

FocusSession _session(
  String id, {
  required DateTime day,
  int minutes = 25,
  String habitId = 'h1',
  int target = 25,
  int span = 0,
  int pauses = 0,
}) =>
    FocusSession(
      id: id,
      habitId: habitId,
      targetMinutes: target,
      seconds: minutes * 60,
      completed: true,
      startedAt: DateTime(day.year, day.month, day.day, 12),
      span: span,
      pauses: pauses,
    );

FocusStats _stats(List<FocusSession> sessions) => FocusStats.compute(
      sessions: sessions,
      range: FocusRange.week,
      now: DateTime.now(),
      weekStart: 1,
    );

void main() {
  useEmptyStore();

  final today = AppClock.today();

  test('the streak counts days in a row up to today or yesterday', () {
    final stats = _stats([
      _session('a', day: today.addDays(-1)),
      _session('b', day: today.addDays(-2)),
      _session('c', day: today.addDays(-4)),
    ]);
    expect(stats.streak, 2);
  });

  test('the previous period is the one right before', () {
    final stats = _stats([
      _session('a', day: today, minutes: 60),
      _session('b', day: today.addDays(-7), minutes: 30),
    ]);
    expect(stats.previousSeconds, 30 * 60);
    expect(stats.change, closeTo(1.0, 0.0001));
  });

  test('planned against real only uses sessions that were measured', () {
    final stats = _stats([
      _session('a', day: today, target: 25, span: 30 * 60, pauses: 2),
      _session('b', day: today, target: 25, span: 20 * 60),
      _session('c', day: today, target: 25),
    ]);
    expect(stats.measured, 2);
    expect(stats.overrun, closeTo(0, 0.0001));
    expect(stats.pausesPerSession, 1);
  });

  test('each bar is split by habit', () {
    final stats = _stats([
      _session('a', day: today, habitId: 'h1', minutes: 20),
      _session('b', day: today, habitId: 'h2', minutes: 10),
    ]);
    final index = stats.buckets.indexWhere((d) => d.dayKey == today.dayKey);
    expect(stats.stacks[index], {'h1': 20 * 60, 'h2': 10 * 60});
  });

  test('time is spread over the hours it covered', () {
    final stats = _stats([
      FocusSession(
        id: 'a',
        habitId: 'h1',
        targetMinutes: 60,
        seconds: 60 * 60,
        completed: true,
        startedAt: DateTime(today.year, today.month, today.day, 10, 30),
      ),
    ]);
    expect(stats.hours[10], 30 * 60);
    expect(stats.hours[11], 30 * 60);
  });

  group('the running session', () {
    FocusController controller() {
      final focus = FocusController();
      addTearDown(focus.dispose);
      return focus;
    }

    test('saves how long it really took and how often it was paused', () async {
      final focus = controller();
      final start = DateTime.now();
      focus.start(habitId: 'h1', targetMinutes: 25);
      focus.pause(at: start.add(const Duration(minutes: 5)));
      focus.resume(at: start.add(const Duration(minutes: 8)));
      final session = await focus.stop(
        completed: false,
        at: start.add(const Duration(minutes: 20)),
      );
      expect(session!.pauses, 1);
      expect(session.span, closeTo(20 * 60, 2));
      expect(session.seconds, closeTo(17 * 60, 2));
    });

    test('changing the timer keeps the time already focused', () {
      final focus = controller();
      final start = DateTime.now();
      focus.start(habitId: 'h1', targetMinutes: 25);
      focus.pause(at: start.add(const Duration(minutes: 5)));

      focus.retime(minutes: 10);
      expect(focus.targetMinutes, 10);
      expect(focus.elapsedSeconds, closeTo(5 * 60, 2));

      focus.retime(minutes: 0);
      expect(focus.isFlow, isTrue);
      expect(focus.elapsedSeconds, closeTo(5 * 60, 2));
    });
  });
}
