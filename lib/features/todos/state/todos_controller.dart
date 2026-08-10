import 'package:flutter/foundation.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_groups.dart';
import 'package:uuid/uuid.dart';

class TodosController extends ChangeNotifier {
  TodosController() {
    _todos = LocalStore.readTodos();
  }

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
  }

  Future<Todo> create({
    required String text,
    String date = '',
    TodoPriority priority = TodoPriority.none,
    List<String> photos = const [],
  }) async {
    final todo = Todo(
      id: const Uuid().v4(),
      text: text.trim(),
      date: date,
      priority: priority,
      photos: photos,
      createdAt: DateTime.now(),
    );
    _todos.add(todo);
    notifyListeners();
    await LocalStore.writeTodo(todo);
    return todo;
  }

  Future<void> update(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index == -1) return;
    _todos[index] = todo;
    notifyListeners();
    await LocalStore.writeTodo(todo);
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
    await LocalStore.writeTodo(updated);
  }

  Future<void> remove(String id) async {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
    await LocalStore.removeTodo(id);
  }

  Future<void> clearCompleted() async {
    final ids = _todos.where((t) => t.done).map((t) => t.id).toList();
    if (ids.isEmpty) return;
    _todos.removeWhere((t) => t.done);
    notifyListeners();
    await LocalStore.removeTodos(ids);
  }
}
