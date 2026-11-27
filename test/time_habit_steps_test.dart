import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/substep.dart';

import 'support/app_harness.dart';

void main() {
  test('a time habit drops steps left by a focus session and keeps its minutes',
      () {
    final habit = testHabit(
      id: 'detox',
      name: 'Detox',
      kind: HabitKind.quantitative,
      perDayTarget: 5,
    ).copyWith(
      quantKind: QuantKind.time,
      substeps: const [Substep(id: 's1', title: 'rest')],
    );

    final loaded = Habit.fromMap(habit.toMap());

    expect(loaded.substeps, isEmpty);
    expect(loaded.effectiveTarget, 5);
  });

  test('a check habit keeps its steps', () {
    final habit = testHabit(
      id: 'read',
      name: 'Read',
      substeps: const [Substep(id: 's1', title: 'one chapter')],
    );

    expect(Habit.fromMap(habit.toMap()).substeps, hasLength(1));
  });
}
