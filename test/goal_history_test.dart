import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

import 'support/app_harness.dart';

Habit _reading(double goal, Map<int, double> pages) {
  final today = AppClock.today();
  return testHabit(
    id: 'read',
    name: 'Read',
    kind: HabitKind.quantitative,
    perDayTarget: goal,
  ).copyWith(
    createdAt: today.addDays(-30),
    completions: {
      for (final MapEntry(key: ago, value: count) in pages.entries)
        today.addDays(-ago).dayKey:
            Completion(date: today.addDays(-ago).dayKey, count: count),
    },
  );
}

void main() {
  final today = AppClock.today();

  test('raising the goal keeps the days done under the old one', () {
    final before = _reading(20, {3: 20, 2: 20, 1: 20});
    final after = before.copyWith(perDayTarget: 30).rememberGoal(before);
    expect(after.isCompletedOn(today.addDays(-1)), isTrue);
    expect(after.currentStreak, 3);
    expect(after.goalOn(today.addDays(-1)), 20);
    expect(after.goalOn(today), 30);
  });

  test('today follows the new goal', () {
    final before = _reading(20, {1: 20, 0: 20});
    final after = before.copyWith(perDayTarget: 30).rememberGoal(before);
    expect(after.isCompletedOn(today), isFalse);
  });

  test('each change keeps its own stretch', () {
    final first = _reading(20, {5: 20, 4: 20, 3: 10, 2: 10, 1: 30});
    final store = <String, double>{
      today.addDays(-3).dayKey: 20,
      today.addDays(-1).dayKey: 10,
    };
    final habit = first.copyWith(perDayTarget: 30, pastGoals: store);
    for (var ago = 1; ago <= 5; ago++) {
      expect(habit.isCompletedOn(today.addDays(-ago)), isTrue);
    }
    expect(habit.goalOn(today.addDays(-4)), 20);
    expect(habit.goalOn(today.addDays(-2)), 10);
  });

  test('two changes on the same day keep the first goal', () {
    final before = _reading(20, {1: 20});
    final mid = before.copyWith(perDayTarget: 10).rememberGoal(before);
    final after = mid.copyWith(perDayTarget: 30).rememberGoal(mid);
    expect(after.pastGoals.values, [20]);
  });

  test('a brand new habit has no history to keep', () {
    final before = _reading(20, {});
    final fresh = before.copyWith(createdAt: today);
    final after = fresh.copyWith(perDayTarget: 30).rememberGoal(fresh);
    expect(after.pastGoals, isEmpty);
  });

  test('any amount days stay done when a goal comes back', () {
    final before = _reading(20, {1: 5}).copyWith(anyAmount: true);
    final after =
        before.copyWith(anyAmount: false).rememberGoal(before);
    expect(after.isCompletedOn(today.addDays(-1)), isTrue);
  });

  test('survives a backup', () {
    final before = _reading(20, {1: 20});
    final after = before.copyWith(perDayTarget: 30).rememberGoal(before);
    final back = Habit.fromJson(after.toJson());
    expect(back.pastGoals, after.pastGoals);
    expect(back.isCompletedOn(today.addDays(-1)), isTrue);
  });
}
