import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

import 'support/app_harness.dart';

Habit _habit(List<int> restDays, {int ago = 28}) {
  final today = AppClock.today();
  final start = today.addDays(-ago);
  return testHabit(id: 'run', name: 'Run').copyWith(
    createdAt: start,
    restDays: restDays,
    completions: {
      for (var day = start; day.isBefore(today); day = day.addDays(1))
        if (!restDays.contains(day.weekday))
          day.dayKey: Completion(date: day.dayKey),
    },
  );
}

void main() {
  final today = AppClock.today();

  test('changing rest days keeps the old ones in the past', () {
    final before = _habit([DateTime.tuesday, DateTime.thursday]);
    final streak = before.currentStreak;
    final after = before
        .copyWith(restDays: [DateTime.saturday, DateTime.sunday])
        .rememberRestDays(before);
    final pastTuesday = [
      for (var ago = 1; ago <= 7; ago++) today.addDays(-ago),
    ].firstWhere((d) => d.weekday == DateTime.tuesday);
    expect(after.isRestDay(pastTuesday), isTrue);
    expect(after.currentStreak, streak);
    expect(after.longestStreak, before.longestStreak);
  });

  test('new rest days count from today', () {
    final before = _habit([DateTime.tuesday]);
    final after = before
        .copyWith(restDays: [DateTime.saturday])
        .rememberRestDays(before);
    final nextSaturday = [
      for (var ahead = 0; ahead < 7; ahead++) today.addDays(ahead),
    ].firstWhere((d) => d.weekday == DateTime.saturday);
    final lastSaturday = nextSaturday.addDays(-7);
    expect(after.isRestDay(nextSaturday), isTrue);
    expect(after.isRestDay(lastSaturday), isFalse);
  });

  test('two changes on the same day keep the first list', () {
    final before = _habit([DateTime.tuesday]);
    final mid =
        before.copyWith(restDays: [DateTime.friday]).rememberRestDays(before);
    final after =
        mid.copyWith(restDays: [DateTime.sunday]).rememberRestDays(mid);
    expect(after.pastRestDays.values.single, [DateTime.tuesday]);
  });

  test('same days in another order change nothing', () {
    final before = _habit([DateTime.tuesday, DateTime.thursday]);
    final after = before
        .copyWith(restDays: [DateTime.thursday, DateTime.tuesday])
        .rememberRestDays(before);
    expect(after.pastRestDays, isEmpty);
  });

  test('a brand new habit has no history to keep', () {
    final fresh = _habit([DateTime.tuesday], ago: 0);
    final after =
        fresh.copyWith(restDays: [DateTime.sunday]).rememberRestDays(fresh);
    expect(after.pastRestDays, isEmpty);
  });

  test('survives a backup', () {
    final before = _habit([DateTime.tuesday, DateTime.thursday]);
    final after = before
        .copyWith(restDays: [DateTime.saturday])
        .rememberRestDays(before);
    final back = Habit.fromJson(after.toJson());
    expect(back.pastRestDays, after.pastRestDays);
    expect(back.currentStreak, after.currentStreak);
  });
}
