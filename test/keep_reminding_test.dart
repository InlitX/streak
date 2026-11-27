import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/data/focus_session.dart';
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

  test('a weekly habit that met its goal stays quiet for the rest of the week', () {
    final today = AppClock.today();
    final weekStart = today.startOfWeek(Habit.weekStart);
    final habit = testHabit(
      id: 'w',
      name: 'Clean',
      interval: HabitInterval.weekly,
      done: [weekStart],
    );
    for (var day = weekStart; day.isBefore(weekStart.addDays(7)); day = day.addDays(1)) {
      expect(habit.silencesRemindersOn(day), isTrue);
    }
    expect(habit.silencesRemindersOn(weekStart.addDays(7)), isFalse);
    expect(habit.copyWith(keepReminding: true).silencesRemindersOn(today), isFalse);
    final twice = habit.copyWith(targetFrequency: 2);
    expect(twice.silencesRemindersOn(weekStart.addDays(1)), isFalse);
  });

  test('a focus session that crosses midnight counts on the day it started', () {
    final late = FocusSession(
      id: 'late',
      habitId: 'a',
      targetMinutes: 20,
      seconds: 20 * 60,
      completed: true,
      startedAt: DateTime(2026, 11, 18, 23, 45),
    );
    expect(late.countedOn.dayKey, DateTime(2026, 11, 18).dayKey);
  });
}
