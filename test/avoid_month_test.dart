import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/avoid_month.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';

void main() {
  final today = AppClock.today();
  final month = DateTime(today.year, today.month - 1);
  final created = DateTime(month.year, month.month, 10);
  final lastDay = DateTime(month.year, month.month + 1, 0).day;

  Habit avoid(Map<String, Completion> completions) => Habit(
        id: 'a',
        name: 'Alcohol',
        color: const Color(0xFF7C5CFF),
        order: 0,
        kind: HabitKind.negative,
        dailyCost: 10,
        trackSpent: true,
        cleanGoal: 7,
        createdAt: created,
        completions: completions,
      );

  final twelfth = DateTime(month.year, month.month, 12);
  final twentieth = DateTime(month.year, month.month, 20);
  final habit = avoid({
    twelfth.dayKey: Completion(date: twelfth.dayKey, count: 2, spent: 15),
    twentieth.dayKey: Completion(date: twentieth.dayKey, spent: 5),
  });

  test('a past month counts from the day the habit started', () {
    final data = AvoidMonth.of(habit, month);
    final clean = lastDay - 10 + 1 - 2;
    expect(data.cleanDays, clean);
    expect(data.relapses, 3);
    expect(data.saved, clean * 10);
    expect(data.spent, 20);
  });

  test('a month before the habit existed is empty', () {
    final data = AvoidMonth.of(habit, DateTime(month.year, month.month - 1));
    expect(data.cleanDays, 0);
    expect(data.relapses, 0);
    expect(data.spent, 0);
  });

  test('the current month stops at today', () {
    final data = AvoidMonth.of(habit, today);
    expect(data.cleanDays, today.day);
  });

  test('a relapse takes the cost per day unless told otherwise', () {
    final logged = CompletionOps.logRelapse(habit, today);
    expect(logged[today.dayKey]!.spent, 10);
    final typed = CompletionOps.logRelapse(habit, today, spent: 42);
    expect(typed[today.dayKey]!.spent, 42);
    final stored = Completion.fromMap(typed[today.dayKey]!.toMap());
    expect(stored.spent, 42);
    expect(Habit.fromMap(habit.toMap()).cleanGoal, 7);
    expect(Habit.fromMap(habit.toMap()).trackSpent, isTrue);
  });
}
