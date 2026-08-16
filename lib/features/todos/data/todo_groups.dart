import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/todos/data/todo.dart';

enum TodoGroup { overdue, today, tomorrow, upcoming, someday }

class TodoSection {
  const TodoSection({required this.group, required this.todos});

  final TodoGroup group;
  final List<Todo> todos;
}

List<TodoSection> groupPending(List<Todo> todos, DateTime today) {
  final buckets = <TodoGroup, List<Todo>>{};
  for (final todo in todos) {
    if (todo.done) continue;
    buckets.putIfAbsent(_groupOf(todo, today), () => []).add(todo);
  }
  for (final bucket in buckets.values) {
    bucket.sort(_byUrgency);
  }
  return [
    for (final group in TodoGroup.values)
      if (buckets[group] != null)
        TodoSection(group: group, todos: buckets[group]!),
  ];
}

List<Todo> sortCompleted(List<Todo> todos) {
  final list = todos.where((t) => t.done).toList()
    ..sort((a, b) => (b.doneAt ?? b.createdAt).compareTo(a.doneAt ?? a.createdAt));
  return list;
}

TodoGroup _groupOf(Todo todo, DateTime today) {
  final due = todo.due;
  if (due == null) return TodoGroup.someday;
  final days = due.epochDay - today.epochDay;
  if (days < 0) return TodoGroup.overdue;
  if (days == 0) return TodoGroup.today;
  if (days == 1) return TodoGroup.tomorrow;
  return TodoGroup.upcoming;
}

int _byUrgency(Todo a, Todo b) {
  final first = a.due;
  final second = b.due;
  if (first != null && second != null && !first.isSameDay(second)) {
    return first.compareTo(second);
  }
  if (a.minutes != b.minutes) {
    if (a.minutes == null || b.minutes == null) {
      return a.minutes == null ? 1 : -1;
    }
    return a.minutes!.compareTo(b.minutes!);
  }
  if (a.priority != b.priority) {
    return b.priority.index.compareTo(a.priority.index);
  }
  return b.createdAt.compareTo(a.createdAt);
}
