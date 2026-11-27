import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/scale_faces.dart';

import 'support/app_harness.dart';

Habit _mood({double? level}) {
  final today = AppClock.today();
  return testHabit(
    id: 'mood',
    name: 'Mood',
    kind: HabitKind.quantitative,
    perDayTarget: 0,
  ).copyWith(
    quantKind: QuantKind.scale,
    tracking: true,
    completions: {
      if (level != null)
        today.dayKey: Completion(date: today.dayKey, count: level),
    },
  );
}

void main() {
  final today = AppClock.today();

  test('a scale habit is an amount habit with its own kind', () {
    expect(_mood().isScale, isTrue);
    expect(_mood().acceptsAnyAmount, isTrue);
    expect(_mood().isTimeAmount, isFalse);
  });

  test('any face logs the day, none leaves it empty', () {
    expect(_mood().isCompletedOn(today), isFalse);
    expect(_mood(level: 1).isCompletedOn(today), isTrue);
    expect(_mood(level: 5).isCompletedOn(today), isTrue);
  });

  test('levels read as out of five', () {
    expect(_mood().amountText(4), '4/5');
  });

  test('levels stay between none and five', () {
    expect(scaleLevelOf(0), 0);
    expect(scaleLevelOf(3), 3);
    expect(scaleLevelOf(9), 5);
    expect(scaleLevelOf(-2), 0);
  });

  test('scale survives a backup round trip', () {
    final back = Habit.fromMap(_mood(level: 2).toMap());
    expect(back.isScale, isTrue);
    expect(back.completions[today.dayKey]?.count, 2);
  });
}
