import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/data/focus_session.dart';
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

  group('a session that crosses the day', () {
    FocusSession session(DateTime startedAt, int seconds) => FocusSession(
          id: 'night',
          habitId: 'study',
          targetMinutes: seconds ~/ 60,
          seconds: seconds,
          completed: true,
          startedAt: startedAt,
        );

    test('splits where the day changes and keeps every second', () {
      final pieces =
          session(DateTime(2026, 9, 14, 21), 8 * 3600).split();

      expect(pieces.length, 2);
      expect(pieces.first.startedAt, DateTime(2026, 9, 14, 21));
      expect(pieces.first.seconds, 3 * 3600);
      expect(pieces.last.startedAt, DateTime(2026, 9, 15));
      expect(pieces.last.seconds, 5 * 3600);
      expect(pieces.first.countedOn.dayKey, DateTime(2026, 9, 14).dayKey);
      expect(pieces.last.countedOn.dayKey, DateTime(2026, 9, 15).dayKey);
    });

    test('only the last piece counts as completed', () {
      final pieces = session(DateTime(2026, 9, 14, 23), 2 * 3600).split();

      expect(pieces.map((piece) => piece.completed), [false, true]);
      expect(pieces.map((piece) => piece.id), ['night', 'night-2']);
    });

    test('crossing by a few seconds stays in one piece', () {
      final pieces = session(DateTime(2026, 9, 14, 23, 59), 70).split();

      expect(pieces.length, 1);
      expect(pieces.single.seconds, 70);
    });

    test('a session inside one day is left alone', () {
      final pieces = session(DateTime(2026, 9, 14, 9), 3600).split();

      expect(pieces.single.id, 'night');
    });
  });
}
