import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_groups.dart';
import 'package:streak/services/notification_service.dart';
import 'package:streak/services/todos_widget_service.dart';
import 'package:uuid/uuid.dart';

class TodosController extends ChangeNotifier {
  TodosController() {
    _todos = LocalStore.readTodos();
    unawaited(_notifications.rescheduleTodos(_todos));
  }

  final _notifications = NotificationService();

  late List<Todo> _todos;

  List<Todo> get all => List.unmodifiable(_todos);

  List<TodoSection> get sections => groupPending(_todos, AppClock.today());

  List<Todo> get completed => sortCompleted(_todos);

  int get pendingCount => _todos.where((t) => !t.done).length;

  int get dueTodayCount {
    final today = AppClock.today().epochDay;
    return _todos.where((t) {
      final due = t.due;
      return !t.done && due != null && due.epochDay <= today;
    }).length;
  }

  void reload() {
    _todos = LocalStore.readTodos();
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
  }

  Future<Todo> create({
    required String text,
    String date = '',
    int? minutes,
    TodoPriority priority = TodoPriority.none,
    List<String> photos = const [],
    List<String> tags = const [],
    String project = '',
    List<TodoStep> steps = const [],
  }) async {
    final todo = Todo(
      id: const Uuid().v4(),
      text: text.trim(),
      date: date,
      minutes: minutes,
      priority: priority,
      photos: photos,
      tags: tags,
      project: project,
      steps: steps,
      createdAt: DateTime.now(),
    );
    _todos.add(todo);
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await LocalStore.writeTodo(todo);
    await _notifications.scheduleTodo(todo);
    return todo;
  }

  Future<void> update(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index == -1) return;
    final dropped =
        _todos[index].photos.where((p) => !todo.photos.contains(p)).toList();
    _todos[index] = todo;
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await LocalStore.writeTodo(todo);
    await _notifications.scheduleTodo(todo);
    await CoverStorage.forgetAll(dropped);
  }

  Future<void> toggle(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final done = !_todos[index].done;
    final updated = _todos[index].copyWith(
      done: done,
      doneAt: done ? DateTime.now() : null,
      clearDoneAt: !done,
    );
    _todos[index] = updated;
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await LocalStore.writeTodo(updated);
    await _notifications.scheduleTodo(updated);
  }

  Future<void> toggleStep(String id, String stepId) async {
    final todo = _todos.where((t) => t.id == id).firstOrNull;
    if (todo == null) return;
    await update(
      todo.copyWith(
        steps: [
          for (final step in todo.steps)
            step.id == stepId ? step.copyWith(done: !step.done) : step,
        ],
      ),
    );
  }

  Future<void> remove(String id) async {
    final photos = [
      for (final todo in _todos.where((t) => t.id == id)) ...todo.photos,
    ];
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await _notifications.cancelTodo(id);
    await LocalStore.removeTodo(id);
    await CoverStorage.forgetAll(photos);
  }

  Future<void> forgetTag(String tagId) async {
    final touched = _todos.where((t) => t.tags.contains(tagId)).toList();
    if (touched.isEmpty) return;
    for (final todo in touched) {
      final updated = todo.copyWith(
        tags: [...todo.tags]..remove(tagId),
      );
      _todos[_todos.indexWhere((t) => t.id == todo.id)] = updated;
      await LocalStore.writeTodo(updated);
    }
    notifyListeners();
  }

  Future<void> forgetProject(String projectId) async {
    final touched = _todos.where((t) => t.project == projectId).toList();
    if (touched.isEmpty) return;
    for (final todo in touched) {
      final updated = todo.copyWith(project: '');
      _todos[_todos.indexWhere((t) => t.id == todo.id)] = updated;
      await LocalStore.writeTodo(updated);
    }
    notifyListeners();
  }

  bool _inProject(Todo todo, String? project) => switch (project) {
        null => true,
        '' => todo.project.isEmpty,
        final id => todo.project == id,
      };

  int countFor(String tagId, {String? project}) => _todos
      .where((t) => !t.done && t.tags.contains(tagId) && _inProject(t, project))
      .length;

  int untaggedCount({String? project}) => _todos
      .where((t) => !t.done && t.tags.isEmpty && _inProject(t, project))
      .length;

  int projectCount(String projectId) =>
      _todos.where((t) => !t.done && t.project == projectId).length;

  int get looseCount => _todos.where((t) => !t.done && t.project.isEmpty).length;

  Future<void> clearCompleted() async {
    final done = _todos.where((t) => t.done).toList();
    if (done.isEmpty) return;
    final photos = [for (final todo in done) ...todo.photos];
    _todos.removeWhere((t) => t.done);
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await LocalStore.removeTodos(done.map((t) => t.id));
    await CoverStorage.forgetAll(photos);
  }
}
