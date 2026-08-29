import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';

import 'support/app_harness.dart';

Habit _timeHabit({double target = 60}) => testHabit(
      id: 'study',
      name: 'Study',
      kind: HabitKind.quantitative,
      perDayTarget: target,
    ).copyWith(quantKind: QuantKind.time, unitLabel: 'min');

double _minutes(Habit habit) =>
    habit.completions[AppClock.now().dayKey]?.count ?? 0;

Habit _addSession(Habit habit, int seconds) => habit.copyWith(
      completions:
          CompletionOps.addProgress(habit, AppClock.now(), seconds / 60),
    );

void main() {
  group('focus filling a time habit', () {
    test('a habit with the Time preset is the one that gets fed', () {
      expect(_timeHabit().isTimeAmount, isTrue);
      expect(testHabit(id: 'a', name: 'A').isTimeAmount, isFalse);
      expect(
        testHabit(id: 'b', name: 'B', kind: HabitKind.quantitative)
            .isTimeAmount,
        isFalse,
      );
    });

    test('the real minutes of a session land on the day', () {
      final after = _addSession(_timeHabit(), 25 * 60);
      expect(_minutes(after), 25);
    });

    test('two sessions in a day add up', () {
      var habit = _addSession(_timeHabit(), 30 * 60);
      habit = _addSession(habit, 30 * 60);

      expect(_minutes(habit), 60);
      expect(habit.isCompletedOn(AppClock.now()), isTrue);
    });

    test('a session cut short banks what it did, and misses the goal', () {
      final after = _addSession(_timeHabit(), 17 * 60);

      expect(_minutes(after), 17);
      expect(after.isCompletedOn(AppClock.now()), isFalse);
    });

    test('going over the goal keeps the real number, not the goal', () {
      final after = _addSession(_timeHabit(target: 30), 40 * 60);

      expect(_minutes(after), 40);
      expect(after.isCompletedOn(AppClock.now()), isTrue);
    });

    test('typing minutes by hand still adds on top', () {
      var habit = _addSession(_timeHabit(), 20 * 60);
      habit = habit.copyWith(
        completions: CompletionOps.addProgress(habit, AppClock.now(), 5),
      );
      expect(_minutes(habit), 25);
    });
  });
}
