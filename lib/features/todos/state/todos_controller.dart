import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_groups.dart';
import 'package:streak/features/todos/data/todo_repeat.dart';
import 'package:streak/services/notification_service.dart';
import 'package:streak/services/todos_widget_service.dart';
import 'package:uuid/uuid.dart';

class TodosController extends ChangeNotifier {
  TodosController() {
    _todos = LocalStore.readTodos();
    if (!NotificationService.armedToday('todoRemindersArmedOn')) {
      unawaited(_notifications.rescheduleTodos(_todos));
    }
  }

  final _notifications = NotificationService();

  late List<Todo> _todos;
  bool _lowFirst = LocalStore.setting('todoLowFirst', false);

  List<Todo>? _view;
  List<TodoSection>? _sections;
  List<Todo>? _completed;
  _Tally? _tally;
  int _sectionsDay = 0;

  List<Todo> get all => _view ??= List.unmodifiable(_todos);

  _Tally get _counts => _tally ??= _Tally.of(_todos);

  @override
  void notifyListeners() {
    _view = null;
    _sections = null;
    _completed = null;
    _tally = null;
    super.notifyListeners();
  }

  Todo? byId(String id) {
    final index = _counts.at[id];
    return index == null ? null : _todos[index];
  }

  List<TodoSection> get sections {
    final today = AppClock.today();
    if (_sections == null || _sectionsDay != today.epochDay) {
      _sectionsDay = today.epochDay;
      _sections = groupPending(_todos, today, lowFirst: _lowFirst);
    }
    return _sections!;
  }

  bool get lowFirst => _lowFirst;

  Future<void> setLowFirst(bool value) async {
    if (_lowFirst == value) return;
    _lowFirst = value;
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await LocalStore.writeSetting('todoLowFirst', value);
  }

  List<Todo> get completed => _completed ??= sortCompleted(_todos);

  int get pendingCount => _counts.pending;

  int get doneCount => _counts.done;

  void reload() {
    _todos = LocalStore.readTodos();
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
  }

  Future<void> refresh() async {
    if (!LocalStore.todosChangedElsewhere) return;
    await LocalStore.reloadTodos();
    reload();
  }

  Future<Todo> create({
    required String text,
    String date = '',
    int? minutes,
    int? estimate,
    TodoPriority priority = TodoPriority.none,
    List<String> photos = const [],
    List<String> tags = const [],
    String project = '',
    List<TodoStep> steps = const [],
    int paper = -1,
    String cover = '',
    bool pinned = false,
    TodoRepeat? repeat,
  }) async {
    final todo = Todo(
      id: const Uuid().v4(),
      text: text.trim(),
      date: date,
      minutes: minutes,
      estimate: estimate,
      priority: priority,
      photos: photos,
      tags: tags,
      project: project,
      steps: steps,
      paper: paper,
      cover: cover,
      pinned: pinned,
      repeat: repeat,
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
    final index = _counts.at[todo.id];
    if (index == null) return;
    final before = _todos[index];
    final dropped = [
      ...before.photos.where((p) => !todo.photos.contains(p)),
      if (before.cover.isNotEmpty && before.cover != todo.cover) before.cover,
    ];
    _todos[index] = todo;
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await LocalStore.writeTodo(todo);
    if (_remindsDifferently(before, todo)) await _notifications.scheduleTodo(todo);
    if (dropped.isNotEmpty) await CoverStorage.forgetAll(dropped);
  }

  static bool _remindsDifferently(Todo a, Todo b) =>
      a.date != b.date ||
      a.minutes != b.minutes ||
      a.done != b.done ||
      a.text != b.text;

  Future<void> toggle(String id) async {
    final index = _counts.at[id];
    if (index == null) return;
    if (!_todos[index].done && _todos[index].repeats) {
      return _finishRepeating(index);
    }
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

  Future<void> _finishRepeating(int index) async {
    final todo = _todos[index];
    final next = todo.nextTime(AppClock.today());
    final record = todo.doneRecord(const Uuid().v4(), DateTime.now());
    _todos[index] = next;
    _todos.add(record);
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await LocalStore.writeTodo(next);
    await LocalStore.writeTodo(record);
    await _notifications.scheduleTodo(next);
  }

  Future<void> toggleStep(String id, String stepId) async {
    final todo = byId(id);
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
    final todo = byId(id);
    if (todo == null) return;
    final photos = [...todo.photos, if (todo.cover.isNotEmpty) todo.cover];
    _todos.remove(todo);
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await _notifications.cancelTodo(id);
    await LocalStore.removeTodo(id);
    await CoverStorage.forgetAll(photos);
  }

  Future<void> discard(String id) async {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await _notifications.cancelTodo(id);
    await LocalStore.removeTodo(id);
  }

  Future<void> restore(Todo todo) async {
    if (byId(todo.id) != null) return;
    _todos.add(todo);
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await LocalStore.writeTodo(todo);
    await _notifications.scheduleTodo(todo);
  }

  Future<void> forgetTag(String tagId) => _rewrite(
        (todo) => todo.tags.contains(tagId),
        (todo) => todo.copyWith(tags: [...todo.tags]..remove(tagId)),
      );

  Future<void> forgetProject(String projectId) => _rewrite(
        (todo) => todo.project == projectId,
        (todo) => todo.copyWith(project: ''),
      );

  Future<void> _rewrite(
    bool Function(Todo todo) touches,
    Todo Function(Todo todo) change,
  ) async {
    final changed = <Todo>[];
    for (var i = 0; i < _todos.length; i++) {
      if (!touches(_todos[i])) continue;
      _todos[i] = change(_todos[i]);
      changed.add(_todos[i]);
    }
    if (changed.isEmpty) return;
    notifyListeners();
    await LocalStore.writeTodos(changed);
  }

  int countFor(String tagId, {String? project}) =>
      _counts.tagged[(project, tagId)] ?? 0;

  int untaggedCount({String? project}) => _counts.untagged[project] ?? 0;

  int projectCount(String projectId) => _counts.projects[projectId] ?? 0;

  int get looseCount => _counts.projects[''] ?? 0;

  List<Todo> dueOn(DateTime day) => _counts.days[day.epochDay] ?? const [];

  Future<void> clearCompleted() async {
    final done = _todos.where((t) => t.done).toList();
    if (done.isEmpty) return;
    final photos = [
      for (final todo in done) ...[
        ...todo.photos,
        if (todo.cover.isNotEmpty) todo.cover,
      ],
    ];
    _todos.removeWhere((t) => t.done);
    notifyListeners();
    TodosWidgetService.syncSoon(_todos);
    await LocalStore.removeTodos(done.map((t) => t.id));
    await CoverStorage.forgetAll(photos);
  }
}

class _Tally {
  _Tally.of(List<Todo> todos) {
    for (final (index, todo) in todos.indexed) {
      at[todo.id] = index;
      if (todo.due case final due?) {
        (days[due.epochDay] ??= []).add(todo);
      }
      if (todo.done) {
        done++;
        continue;
      }
      pending++;
      _bump(projects, todo.project);
      for (final scope in [null, todo.project]) {
        if (todo.tags.isEmpty) _bump(untagged, scope);
        for (final tag in todo.tags) {
          _bump(tagged, (scope, tag));
        }
      }
    }
  }

  final at = <String, int>{};
  final days = <int, List<Todo>>{};
  final projects = <String, int>{};
  final untagged = <String?, int>{};
  final tagged = <(String?, String), int>{};
  int pending = 0;
  int done = 0;

  static void _bump<K>(Map<K, int> counts, K key) =>
      counts[key] = (counts[key] ?? 0) + 1;
}
