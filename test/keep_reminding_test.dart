import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';

import 'support/app_harness.dart';

void main() {
  test('a done habit stays quiet unless it keeps reminding', () {
    final today = AppClock.today();
    final habit = testHabit(id: 'a', name: 'Water', done: [today]);
    expect(habit.silencesRemindersOn(today), isTrue);
    final keeps = habit.copyWith(keepReminding: true);
    expect(keeps.silencesRemindersOn(today), isFalse);
  });

  test('keep reminding survives the backup round trip', () {
    final habit = testHabit(id: 'a', name: 'Water').copyWith(keepReminding: true);
    expect(Habit.fromMap(habit.toMap()).keepReminding, isTrue);
    final plain = testHabit(id: 'b', name: 'Read');
    expect(plain.toMap().containsKey('keepReminding'), isFalse);
    expect(Habit.fromMap(plain.toMap()).keepReminding, isFalse);
  });
}
