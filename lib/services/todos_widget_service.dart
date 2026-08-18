import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_groups.dart';

class TodosWidgetService {
  const TodosWidgetService._();

  static const _provider = 'TodosWidgetProvider';

  static const _maxTodos = 40;

  static const _maxDone = 10;

  static Timer? _pendingSync;

  static void syncSoon(List<Todo> todos) {
    _pendingSync?.cancel();
    _pendingSync = Timer(const Duration(milliseconds: 700), () {
      _pendingSync = null;
      sync(todos);
    });
  }

  static Future<void> sync(List<Todo> todos) async {
    _pendingSync?.cancel();
    _pendingSync = null;
    try {
      await HomeWidget.saveWidgetData<String>('todos_data', _encode(todos));
      await HomeWidget.updateWidget(androidName: _provider);
    } catch (e) {
      debugPrint('To-do widget sync failed: $e');
    }
  }

  static String _encode(List<Todo> todos) {
    final today = AppClock.today();
    final listed = [
      for (final section in groupPending(todos, today)) ...section.todos,
    ].take(_maxTodos).toList()
      ..addAll(
        sortCompleted(todos)
            .where((todo) => todo.doneAt?.atMidnight == today)
            .take(_maxDone),
      );

    return json.encode({
      'epochDay': today.epochDay,
      'todos': [
        for (final todo in listed)
          {
            'id': todo.id,
            'title': todo.title,
            'day': todo.due?.epochDay ?? -1,
            'priority': todo.priority.index,
            if (todo.done) 'done': true,
            if (todo.minutes != null) 'minutes': todo.minutes,
          },
      ],
    });
  }
}
