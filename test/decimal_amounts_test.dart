import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';

import 'support/app_harness.dart';

void main() {
  test('whole amounts lose the decimal part', () {
    expect(formatAmount(3), '3');
    expect(formatAmount(0), '0');
    expect(formatAmount(2000), '2000');
  });

  test('fractional amounts keep only the digits they need', () {
    expect(formatAmount(1.5), '1.5');
    expect(formatAmount(0.75), '0.75');
    expect(formatAmount(2.2), '2.2');
    expect(formatAmount(1.333333), '1.33');
  });

  test('a completion round-trips a decimal count', () {
    final map = const Completion(date: '2026-08-07', count: 2.5).toMap();
    expect(Completion.fromMap(map).count, 2.5);
  });

  test('an old integer count still reads back', () {
    final completion = Completion.fromMap({
      'date': '2026-08-07',
      'numberOfCompletions': 3,
    });
    expect(completion.count, 3.0);
  });

  test('adding fractions does not drift', () {
    var habit = testHabit(
      id: 'a',
      name: 'Read',
      kind: HabitKind.quantitative,
      perDayTarget: 1,
    );
    final today = AppClock.now();

    for (var i = 0; i < 3; i++) {
      habit = habit.copyWith(
        completions: CompletionOps.addProgress(habit, today, 0.1),
      );
    }

    expect(habit.completions[today.dayKey]!.count, 0.3);
  });

  test('a habit is only complete once the decimal target is reached', () {
    final today = AppClock.now();
    var habit = testHabit(
      id: 'a',
      name: 'Study',
      kind: HabitKind.quantitative,
      perDayTarget: 1.5,
    ).copyWith(completions: const {});

    habit = habit.copyWith(
      completions: CompletionOps.addProgress(habit, today, 1),
    );
    expect(habit.isCompletedOn(today), isFalse);

    habit = habit.copyWith(
      completions: CompletionOps.addProgress(habit, today, 0.5),
    );
    expect(habit.isCompletedOn(today), isTrue);
  });
}
