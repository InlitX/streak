import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/todos/data/todo.dart';

class WidgetActionService {
  const WidgetActionService._();

  static const _queueKey = 'pending_actions';

  static Future<bool> drain(
    Map<String, Habit> habits, {
    List<Todo> todos = const [],
  }) async {
    final pending = await _read();
    if (pending.isEmpty) return false;

    final touched = <String>{};
    final ticked = <Todo>[];
    for (final raw in pending) {
      try {
        final uri = Uri.parse(raw);
        if (uri.queryParameters.containsKey('todoId')) {
          final todo = _applyTodo(todos, uri);
          if (todo != null) ticked.add(todo);
          continue;
        }
        final id = _apply(habits, uri);
        if (id != null) touched.add(id);
      } catch (e) {
        debugPrint('Widget action skipped ($raw): $e');
      }
    }

    for (final id in touched) {
      final habit = habits[id];
      if (habit != null) await LocalStore.writeHabit(habit);
    }
    for (final todo in ticked) {
      await LocalStore.writeTodo(todo);
    }
    await _clear(pending.length);
    return touched.isNotEmpty || ticked.isNotEmpty;
  }

  static Todo? _applyTodo(List<Todo> todos, Uri uri) {
    final id = uri.queryParameters['todoId'];
    if (id == null) return null;
    final index = todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return null;

    final done = !todos[index].done;
    final updated = todos[index].copyWith(
      done: done,
      doneAt: done ? DateTime.now() : null,
      clearDoneAt: !done,
    );
    todos[index] = updated;
    return updated;
  }

  static Future<List<String>> _read() async {
    try {
      final raw = await HomeWidget.getWidgetData<String>(_queueKey);
      if (raw == null || raw.isEmpty) return const [];
      return (json.decode(raw) as List).cast<String>();
    } catch (e) {
      debugPrint('Could not read widget action queue: $e');
      return const [];
    }
  }

  static Future<void> _clear(int applied) async {
    try {
      final current = await _read();
      final rest = current.length > applied ? current.sublist(applied) : const <String>[];
      await HomeWidget.saveWidgetData<String>(
        _queueKey,
        rest.isEmpty ? '' : json.encode(rest),
      );
    } catch (e) {
      debugPrint('Could not clear widget action queue: $e');
    }
  }

  static DateTime? _dayOf(Uri uri) {
    final day = uri.queryParameters['day'];
    if (day != null && day.length == 10) {
      try {
        return parseDayKey(day);
      } catch (e) {
        return null;
      }
    }
    final index = int.tryParse(uri.queryParameters['dayIndex'] ?? '');
    if (index == null) return null;
    return AppClock.now().subtract(Duration(days: 6 - index)).atMidnight;
  }

  static String? _apply(Map<String, Habit> habits, Uri uri) {
    final habitId = uri.queryParameters['habitId'];
    if (habitId == null) return null;

    final habit = habits[habitId];
    if (habit == null) return null;

    final target = _dayOf(uri);
    if (target == null) return null;
    final delta = double.tryParse(uri.queryParameters['delta'] ?? '') ??
        habit.incrementAmount;

    final action = uri.queryParameters['action'] ?? 'toggle';
    if (action == 'toggle' && habit.blocksManualCheck(target)) return null;

    final completions = switch (action) {
      'relapse' => habit.completions.containsKey(target.dayKey)
          ? CompletionOps.clearRelapse(habit, target)
          : CompletionOps.logRelapse(habit, target),
      'progress' => CompletionOps.addProgress(habit, target, delta),
      _ => CompletionOps.toggle(habit, target),
    };

    habits[habitId] = habit.copyWith(completions: completions);
    return habitId;
  }
}
