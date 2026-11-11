import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/services/home_widget_service.dart';

final _today = AppClock.today();

Habit _habit(int daysOld, {Set<int> done = const {}}) => Habit(
      id: 'h',
      name: 'h',
      color: const Color(0xFF00FF00),
      order: 0,
      createdAt: _today.addDays(-daysOld),
      completions: {
        for (final i in done)
          _today.addDays(-i).dayKey:
              Completion(date: _today.addDays(-i).dayKey, hour: 9, count: 1),
      },
    );

void main() {
  test('days before a new habit existed are not scheduled', () {
    final habit = _habit(0);
    expect(HomeWidgetService.scheduledOn(habit, _today), isTrue);
    expect(HomeWidgetService.scheduledOn(habit, _today.addDays(-1)), isFalse);
    expect(HomeWidgetService.scheduledOn(habit, _today.addDays(-6)), isFalse);
  });

  test('days after creation stay scheduled', () {
    final habit = _habit(3);
    expect(HomeWidgetService.scheduledOn(habit, _today.addDays(-3)), isTrue);
    expect(HomeWidgetService.scheduledOn(habit, _today.addDays(-4)), isFalse);
  });

  test('a day done before the creation date keeps counting', () {
    final habit = _habit(1, done: {5});
    expect(HomeWidgetService.scheduledOn(habit, _today.addDays(-5)), isTrue);
  });
}
