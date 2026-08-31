import 'package:flutter/foundation.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/todos/data/todo.dart';

@immutable
class IslandLedger {
  const IslandLedger({
    required this.checks,
    required this.focusMinutes,
    required this.perfectDays,
    required this.todos,
    required this.milestones,
  });

  static const int perCheck = 10;
  static const int perFocusMinute = 1;
  static const int focusCapPerDay = 60;
  static const int perPerfectDay = 25;
  static const int perTodo = 4;

  static const List<(int, int)> steps = [
    (7, 30),
    (30, 150),
    (100, 600),
    (365, 2500),
  ];

  static const IslandLedger empty = IslandLedger(
    checks: 0,
    focusMinutes: 0,
    perfectDays: 0,
    todos: 0,
    milestones: 0,
  );

  final int checks;
  final int focusMinutes;
  final int perfectDays;
  final int todos;
  final int milestones;

  int get earned =>
      checks * perCheck +
      focusMinutes * perFocusMinute +
      perfectDays * perPerfectDay +
      todos * perTodo +
      milestones;

  static IslandLedger of(
    List<Habit> habits,
    List<FocusSession> sessions,
    List<Todo> todoList,
  ) {
    final counted = habits.where((habit) => !habit.tracking).toList();
    final today = AppClock.today();

    var checks = 0;
    var milestones = 0;
    final days = <String>{};
    for (final habit in counted) {
      for (final step in steps) {
        if (habit.longestStreak >= step.$1) milestones += step.$2;
      }
      if (habit.kind == HabitKind.negative) {
        var cursor = habit.createdAt.atMidnight;
        while (!cursor.isAfter(today)) {
          if (habit.isCompletedOn(cursor)) {
            checks++;
            days.add(cursor.dayKey);
          }
          cursor = cursor.add(const Duration(days: 1));
        }
        continue;
      }
      for (final entry in habit.completions.values) {
        if (entry.count < habit.effectiveTarget) continue;
        checks++;
        days.add(entry.date);
      }
    }

    var perfect = 0;
    for (final key in days) {
      final date = parseDayKey(key);
      final due = counted.where((habit) => habit.isScheduledOn(date));
      if (due.isNotEmpty && due.every((habit) => habit.isCompletedOn(date))) {
        perfect++;
      }
    }

    final perDay = <String, int>{};
    for (final session in sessions) {
      final key = session.startedAt.dayKey;
      perDay[key] = (perDay[key] ?? 0) + session.minutes;
    }
    var minutes = 0;
    for (final value in perDay.values) {
      minutes += value > focusCapPerDay ? focusCapPerDay : value;
    }

    return IslandLedger(
      checks: checks,
      focusMinutes: minutes,
      perfectDays: perfect,
      todos: todoList.where((todo) => todo.done).length,
      milestones: milestones,
    );
  }
}
