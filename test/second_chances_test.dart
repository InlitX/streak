import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

final _today = AppClock.today();

DateTime _ago(int days) => _today.addDays(-days);

Habit _habit(int daysOld, Set<int> missed, {bool today = true}) => Habit(
      id: 'h',
      name: 'h',
      color: const Color(0xFF00FF00),
      order: 0,
      createdAt: _ago(daysOld),
      completions: {
        for (var i = daysOld; i >= (today ? 0 : 1); i--)
          if (!missed.contains(i))
            _ago(i).dayKey: Completion(date: _ago(i).dayKey, hour: 9, count: 1),
      },
    );

void main() {
  setUp(() => Habit.secondChances = true);
  tearDown(() => Habit.secondChances = false);

  test('a short streak still breaks on the first miss', () {
    final habit = _habit(20, {5});
    expect(habit.currentStreak, 5);
    expect(habit.chancesLeft, 0);
  });

  test('thirty days earn one chance that covers a single miss', () {
    final habit = _habit(40, {5});
    expect(habit.currentStreak, 40);
    expect(habit.savedDays.single, _ago(5));
    expect(habit.chancesLeft, 0);
  });

  test('two missed days in a row break the streak', () {
    final habit = _habit(80, {5, 6});
    expect(habit.currentStreak, 5);
  });

  test('chances pile up to three', () {
    final habit = _habit(200, {});
    expect(habit.chancesLeft, Habit.chanceCap);
    expect(habit.currentStreak, 201);
  });

  test('today not done yet does not cost a chance', () {
    final habit = _habit(40, {}, today: false);
    expect(habit.currentStreak, 40);
    expect(habit.chancesLeft, 1);
    expect(habit.savedDays, isEmpty);
  });

  test('saved days stay marked after a later break', () {
    final habit = _habit(120, {80, 10, 9});
    expect(habit.isChanceDay(_ago(80)), isTrue);
    expect(habit.isChanceDay(_ago(10)), isFalse);
    expect(habit.isChanceDay(_ago(9)), isFalse);
    expect(habit.savedDays, isEmpty);
  });

  test('turned off keeps the old rule', () {
    Habit.secondChances = false;
    final habit = _habit(40, {5});
    expect(habit.currentStreak, 5);
    expect(habit.longestStreak, 35);
  });
}
