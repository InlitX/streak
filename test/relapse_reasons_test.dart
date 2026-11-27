import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/miss_reasons.dart';

import 'support/app_harness.dart';

Habit _avoid() {
  final habit = testHabit(id: 'scroll', name: 'Doomscrolling', kind: HabitKind.negative);
  final slip = AppClock.today().addDays(-2);
  return habit.copyWith(completions: CompletionOps.logRelapse(habit, slip));
}

void main() {
  test('a relapse day can get a reason, a clean day cannot', () {
    final habit = _avoid();
    final today = AppClock.today();

    expect(canMissOn(habit, today.addDays(-2)), isTrue);
    expect(canMissOn(habit, today.addDays(-1)), isFalse);
    expect(canMissOn(habit, today.addDays(1)), isFalse);
  });

  test('a relapse logged today can get a reason too', () {
    final base = testHabit(id: 'scroll', name: 'Doomscrolling', kind: HabitKind.negative);
    final habit = base.copyWith(
      completions: CompletionOps.logRelapse(base, AppClock.today()),
    );

    expect(canMissOn(habit, AppClock.today()), isTrue);
  });

  test('relapse reasons are counted, and a cleared relapse drops its reason', () {
    final slip = AppClock.today().addDays(-2).dayKey;
    var habit = _avoid().copyWith(missReasons: {slip: 'Stress'});

    expect(missedTally(habit), {'Stress': 1});

    habit = habit.copyWith(completions: const {});
    expect(missedTally(habit), isEmpty);
  });

  test('positive habits still work as before', () {
    final habit = testHabit(id: 'read', name: 'Read');
    final yesterday = AppClock.today().addDays(-1);

    expect(canMissOn(habit, yesterday), isTrue);
    expect(canMissOn(habit, AppClock.today()), isFalse);
  });
}
