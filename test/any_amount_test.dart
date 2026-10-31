import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/substep.dart';

import 'support/app_harness.dart';

Habit _sleep({required bool anyAmount, double logged = 465}) {
  final today = AppClock.today();
  return testHabit(
    id: 'sleep',
    name: 'Sleep',
    kind: HabitKind.quantitative,
    perDayTarget: 480,
  ).copyWith(
    anyAmount: anyAmount,
    completions: {
      today.dayKey: Completion(date: today.dayKey, count: logged),
    },
  );
}

void main() {
  final today = AppClock.today();

  test('without the switch the goal still has to be reached', () {
    expect(_sleep(anyAmount: false).isCompletedOn(today), isFalse);
  });

  test('with the switch any amount marks the day as done', () {
    final habit = _sleep(anyAmount: true);
    expect(habit.isCompletedOn(today), isTrue);
    expect(habit.progressFor(465).reachedGoal, isTrue);
    expect(habit.currentStreak, 1);
  });

  test('with the switch an empty day is still not done', () {
    expect(_sleep(anyAmount: true, logged: 0).isCompletedOn(today), isFalse);
  });

  test('the switch only means something for amount habits', () {
    final run = testHabit(id: 'run', name: 'Run', perDayTarget: 3).copyWith(
      anyAmount: true,
      completions: {today.dayKey: Completion(date: today.dayKey, count: 1)},
    );
    expect(run.isCompletedOn(today), isFalse);
  });

  test('survives a backup, and an old backup reads it as off', () {
    final map = _sleep(anyAmount: true).toMap();
    expect(Habit.fromMap(map).anyAmount, isTrue);
    expect(Habit.fromMap(map..remove('anyAmount')).anyAmount, isFalse);
  });

  Habit calories(double logged) => testHabit(
        id: 'kcal',
        name: 'Calories',
        kind: HabitKind.quantitative,
        perDayTarget: 1800,
      ).copyWith(
        atMost: true,
        completions: {
          today.dayKey: Completion(date: today.dayKey, count: logged),
        },
      );

  test('a limit is done at or under it and broken over it', () {
    expect(calories(1500).isCompletedOn(today), isTrue);
    expect(calories(1800).isCompletedOn(today), isTrue);
    expect(calories(1900).isCompletedOn(today), isFalse);
    expect(calories(0).isCompletedOn(today), isFalse);
    expect(calories(1500).currentStreak, 1);
    expect(calories(1500).progressFor(1500).reachedGoal, isTrue);
    expect(calories(1900).progressFor(1900).reachedGoal, isFalse);
  });

  test('a limit survives a backup', () {
    expect(Habit.fromMap(calories(1500).toMap()).atMost, isTrue);
    expect(Habit.fromMap(_sleep(anyAmount: false).toMap()).atMost, isFalse);
  });

  Habit workout({required bool anySteps}) => testHabit(
        id: 'gym',
        name: 'Workout',
        substeps: const [
          Substep(id: 'legs', title: 'Legs'),
          Substep(id: 'arms', title: 'Arms'),
        ],
      ).copyWith(
        anySteps: anySteps,
        completions: {
          today.dayKey: Completion(date: today.dayKey, count: 1, steps: {'legs'}),
        },
      );

  test('without the switch every step is still needed', () {
    expect(workout(anySteps: false).isCompletedOn(today), isFalse);
  });

  test('with the switch one step marks the day as done', () {
    final habit = workout(anySteps: true);
    expect(habit.isCompletedOn(today), isTrue);
    expect(habit.totalCompletions, 1);
  });
}
