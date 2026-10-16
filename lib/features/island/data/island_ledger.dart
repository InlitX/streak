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

  static final Expando<_Share> _shares = Expando();

  static IslandLedger of(
    List<Habit> habits,
    List<FocusSession> sessions,
    List<Todo> todoList,
  ) {
    final counted = habits.where((habit) => !habit.tracking).toList();
    final today = AppClock.today();
    final shares = [for (final habit in counted) _shareOf(habit, today)];

    var checks = 0;
    var milestones = 0;
    final days = <int>{};
    for (final share in shares) {
      checks += share.checked.length;
      milestones += share.milestones;
      days.addAll(share.checked);
    }

    var perfect = 0;
    for (final day in days) {
      DateTime? date;
      var due = false;
      var all = true;
      for (var i = 0; i < counted.length; i++) {
        if (day > shares[i].last) continue;
        if (!shares[i].everyDay &&
            !counted[i].isScheduledOn(date ??= epochDayDate(day))) {
          continue;
        }
        due = true;
        if (!shares[i].done.contains(day)) {
          all = false;
          break;
        }
      }
      if (due && all) perfect++;
    }

    final minutes = sessions.fold(0, (sum, session) => sum + session.minutes);

    return IslandLedger(
      checks: checks,
      focusMinutes: minutes,
      perfectDays: perfect,
      todos: todoList.where((todo) => todo.done).length,
      milestones: milestones,
    );
  }

  static _Share _shareOf(Habit habit, DateTime today) {
    final cached = _shares[habit];
    if (cached != null && cached.today == today) return cached;
    var milestones = 0;
    for (final step in steps) {
      if (habit.longestStreak >= step.$1) milestones += step.$2;
    }
    final share = habit.kind == HabitKind.negative
        ? _cleanShare(habit, today, milestones)
        : _checkedShare(habit, today, milestones);
    _shares[habit] = share;
    return share;
  }

  static _Share _cleanShare(Habit habit, DateTime today, int milestones) {
    final relapses = {for (final key in habit.completions.keys) dayKeyEpoch(key)};
    final last = _lastDay(habit, today);
    final clean = <int>{
      for (var day = habit.startedAt.epochDay; day <= last; day++)
        if (!relapses.contains(day)) day,
    };
    return _Share(today, last, _everyDay(habit), milestones, clean, clean);
  }

  static _Share _checkedShare(Habit habit, DateTime today, int milestones) {
    final checked = <int>{};
    final done = <int>{};
    final last = _lastDay(habit, today);
    for (final entry in habit.completions.values) {
      final day = dayKeyEpoch(entry.date);
      if (day > last) continue;
      if (entry.count >= habit.effectiveTarget || habit.isDoneEntry(entry)) {
        checked.add(day);
      }
      if (habit.isDoneEntry(entry)) done.add(day);
    }
    return _Share(today, last, _everyDay(habit), milestones, checked, done);
  }

  static int _lastDay(Habit habit, DateTime today) {
    final archived = habit.archivedAt?.epochDay;
    return archived == null || archived > today.epochDay
        ? today.epochDay
        : archived;
  }

  static bool _everyDay(Habit habit) => switch (habit.interval) {
        HabitInterval.daily ||
        HabitInterval.weekly ||
        HabitInterval.monthly =>
          true,
        HabitInterval.weekdays || HabitInterval.everyXDays => false,
      };
}

class _Share {
  const _Share(
    this.today,
    this.last,
    this.everyDay,
    this.milestones,
    this.checked,
    this.done,
  );

  final DateTime today;
  final int last;
  final bool everyDay;
  final int milestones;
  final Set<int> checked;
  final Set<int> done;
}
