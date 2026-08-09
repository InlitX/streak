import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';

final _day = DateTime(2026, 8, 12);

Habit _habit({
  required String id,
  int start = -1,
  int duration = 0,
  int order = 0,
  HabitKind kind = HabitKind.positive,
  HabitInterval interval = HabitInterval.daily,
  List<int> scheduleWeekdays = const [],
  List<int> restDays = const [],
  DateTime? createdAt,
}) =>
    Habit(
      id: id,
      name: id,
      color: const Color(0xFF00FF00),
      order: order,
      kind: kind,
      interval: interval,
      scheduleWeekdays: scheduleWeekdays,
      restDays: restDays,
      startMinute: start,
      durationMinutes: duration,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
    );

void main() {
  test('planned habits come out sorted with the gaps between them', () {
    final plan = DayPlan.of([
      _habit(id: 'late', start: 13 * 60, duration: 30),
      _habit(id: 'early', start: 9 * 60, duration: 60),
    ], _day);

    expect(plan.slots.length, 3);
    expect(plan.slots[0].habit?.id, 'early');
    expect(plan.slots[1].isGap, isTrue);
    expect(plan.slots[1].minutes, 3 * 60);
    expect(plan.slots[2].habit?.id, 'late');
  });

  test('back to back habits leave no gap', () {
    final plan = DayPlan.of([
      _habit(id: 'a', start: 9 * 60, duration: 30),
      _habit(id: 'b', start: 9 * 60 + 30, duration: 30),
    ], _day);

    expect(plan.slots.length, 2);
    expect(plan.slots.every((s) => !s.isGap), isTrue);
  });

  test('overlapping habits never make a negative gap', () {
    final plan = DayPlan.of([
      _habit(id: 'long', start: 9 * 60, duration: 120),
      _habit(id: 'inside', start: 9 * 60 + 30, duration: 15),
      _habit(id: 'after', start: 12 * 60, duration: 30),
    ], _day);

    expect(plan.slots.where((s) => s.isGap).length, 1);
    expect(plan.slots.where((s) => s.isGap).single.minutes, 60);
    expect(plan.slots.every((s) => s.minutes >= 0), isTrue);
  });

  test('habits with no time land in the anytime list', () {
    final plan = DayPlan.of([
      _habit(id: 'planned', start: 8 * 60),
      _habit(id: 'loose'),
    ], _day);

    expect(plan.planned.map((h) => h.id), ['planned']);
    expect(plan.anytime.map((h) => h.id), ['loose']);
  });

  test('a habit that is not due that day is left out', () {
    final plan = DayPlan.of([
      _habit(
        id: 'monday',
        start: 8 * 60,
        interval: HabitInterval.weekdays,
        scheduleWeekdays: const [DateTime.monday],
      ),
      _habit(
        id: 'resting',
        start: 9 * 60,
        restDays: [_day.weekday],
      ),
      _habit(
        id: 'future',
        start: 10 * 60,
        createdAt: DateTime(2026, 9, 1),
      ),
      _habit(id: 'negative', kind: HabitKind.negative),
    ], _day);

    expect(plan.isEmpty, isTrue);
  });

  test('a duration that runs past midnight stops at the end of the day', () {
    final habit = _habit(id: 'late', start: 23 * 60 + 30, duration: 120);

    expect(habit.endMinute, Habit.dayMinutes);
    expect(minuteLabel(habit.endMinute), '00:00');
  });

  test('labels read the way a clock does', () {
    expect(minuteLabel(0), '00:00');
    expect(minuteLabel(9 * 60 + 5), '09:05');
    expect(spanLabel(45), '45m');
    expect(spanLabel(60), '1h');
    expect(spanLabel(95), '1h 35m');
  });
}
