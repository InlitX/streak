import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

Habit _habit({
  required HabitKind kind,
  required int daysOld,
  double dailyCost = 8,
  List<DateTime> relapses = const [],
}) =>
    Habit(
      id: 'h',
      name: 'Smoke',
      color: const Color(0xFF00FF00),
      order: 0,
      kind: kind,
      dailyCost: dailyCost,
      createdAt: AppClock.now().subtract(Duration(days: daysOld)),
      completions: {
        for (final day in relapses)
          day.dayKey: Completion(date: day.dayKey, count: 1),
      },
    );

void main() {
  final today = AppClock.now();

  test('the day it was created already counts as clean', () {
    expect(_habit(kind: HabitKind.negative, daysOld: 0).cleanDays, 1);
  });

  test('every day without a relapse pays', () {
    final habit = _habit(kind: HabitKind.negative, daysOld: 9);

    expect(habit.cleanDays, 10);
    expect(habit.moneySaved, 80);
  });

  test('a relapse does not pay', () {
    final habit = _habit(
      kind: HabitKind.negative,
      daysOld: 9,
      relapses: [today.subtract(const Duration(days: 2)), today],
    );

    expect(habit.cleanDays, 8);
    expect(habit.moneySaved, 64);
  });

  test('a relapse older than the habit pulls its start back', () {
    final habit = _habit(
      kind: HabitKind.negative,
      daysOld: 3,
      relapses: [today.subtract(const Duration(days: 40))],
    );

    expect(habit.cleanDays, 40);
    expect(habit.moneySaved, 320);
  });

  test('without a cost there is nothing to show', () {
    final habit = _habit(kind: HabitKind.negative, daysOld: 9, dailyCost: 0);

    expect(habit.hasCost, false);
    expect(habit.moneySaved, 0);
  });

  test('only avoid habits save money', () {
    final habit = _habit(kind: HabitKind.positive, daysOld: 9);

    expect(habit.hasCost, false);
    expect(habit.cleanDays, 0);
    expect(habit.moneySaved, 0);
  });
}
