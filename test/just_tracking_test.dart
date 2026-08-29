import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/statistics/data/habit_stats.dart';

import 'support/app_harness.dart';

Habit _tracked() =>
    testHabit(id: 'soda', name: 'Coke zero', done: lastDays(3))
        .copyWith(tracking: true);

Habit _normal() => testHabit(id: 'run', name: 'Run', done: lastDays(3));

void main() {
  group('a just tracking habit', () {
    test('is off by default, so nothing changes for anyone', () {
      expect(testHabit(id: 'a', name: 'A').tracking, isFalse);
    });

    test('a habit already marked keeps its switch even if the option is off',
        () {
      expect(_tracked().tracking, isTrue);
    });

    test('survives a backup round trip', () {
      final map = json.decode(json.encode(_tracked().toMap()));
      expect(Habit.fromMap(Map<String, dynamic>.from(map)).tracking, isTrue);
    });

    test('an old backup without the field reads as a normal habit', () {
      final map = _normal().toMap()..remove('tracking');
      expect(Habit.fromMap(map).tracking, isFalse);
    });

    test('keeps its own streak and its own days', () {
      final habit = _tracked();
      expect(habit.currentStreak, greaterThan(0));
      expect(habit.completions, hasLength(3));
    });

    test('it is left out of what the shared numbers are built from', () {
      final counted = HabitStats.counted([_normal(), _tracked()]);
      expect(counted.map((h) => h.id), ['run']);
    });

    test('so the shared numbers read as if it were not there', () {
      final together =
          HabitStats.compute(HabitStats.counted([_normal(), _tracked()]), 2026);
      final alone = HabitStats.compute([_normal()], 2026);

      expect(together.consistency, alone.consistency);
      expect(together.perHabit.length, alone.perHabit.length);
      expect(together.currentStreak, alone.currentStreak);
    });

    test('on its own it still has full statistics', () {
      final stats = HabitStats.compute([_tracked()], 2026);
      expect(stats.perHabit, hasLength(1));
      expect(stats.currentStreak, greaterThan(0));
    });

    test('a page of nothing but tracked habits does not blow up', () {
      final stats = HabitStats.compute(const [], 2026);
      expect(stats.consistency, 0);
      expect(stats.currentStreak, 0);
      expect(stats.perHabit, isEmpty);
    });
  });
}
