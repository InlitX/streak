import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_groups.dart';

Todo _todo(
  String id, {
  DateTime? due,
  int? minutes,
  TodoPriority priority = TodoPriority.none,
  bool done = false,
  int createdMinutesAgo = 0,
}) =>
    Todo(
      id: id,
      text: id,
      done: done,
      date: due?.dayKey ?? '',
      minutes: minutes,
      priority: priority,
      createdAt: DateTime(2026, 8, 10, 12).subtract(
        Duration(minutes: createdMinutesAgo),
      ),
      doneAt: done ? DateTime(2026, 8, 10, 12) : null,
    );

void main() {
  final today = DateTime(2026, 8, 10);
  final tomorrow = today.add(const Duration(days: 1));

  test('a to-do lands in the group its date asks for', () {
    final sections = groupPending([
      _todo('late', due: today.subtract(const Duration(days: 2))),
      _todo('now', due: today),
      _todo('next', due: tomorrow),
      _todo('soon', due: today.add(const Duration(days: 4))),
      _todo('loose'),
    ], today);

    expect(
      sections.map((s) => s.group).toList(),
      [
        TodoGroup.overdue,
        TodoGroup.today,
        TodoGroup.tomorrow,
        TodoGroup.upcoming,
        TodoGroup.someday,
      ],
    );
    expect(sections.first.todos.single.id, 'late');
    expect(sections.last.todos.single.id, 'loose');
  });

  test('empty groups are left out', () {
    final sections = groupPending([_todo('loose')], today);

    expect(sections.length, 1);
    expect(sections.single.group, TodoGroup.someday);
  });

  test('completed to-dos never reach the pending groups', () {
    final sections = groupPending([
      _todo('open', due: today),
      _todo('closed', due: today, done: true),
    ], today);

    expect(sections.single.todos.map((t) => t.id), ['open']);
  });

  test('inside a group the nearest date wins, then priority, then the newest',
      () {
    final sections = groupPending([
      _todo('far', due: today.add(const Duration(days: 9))),
      _todo('near', due: today.add(const Duration(days: 3))),
    ], today);

    expect(sections.single.todos.map((t) => t.id), ['near', 'far']);

    final sameDay = groupPending([
      _todo('plain', due: today, createdMinutesAgo: 30),
      _todo('urgent', due: today, priority: TodoPriority.high),
      _todo('older', due: today, createdMinutesAgo: 90),
    ], today);

    expect(
      sameDay.single.todos.map((t) => t.id),
      ['urgent', 'plain', 'older'],
    );
  });

  test('on the same day the hour decides, and the timed ones go first', () {
    final sections = groupPending([
      _todo('loose', due: today, priority: TodoPriority.high),
      _todo('evening', due: today, minutes: 20 * 60),
      _todo('morning', due: today, minutes: 8 * 60),
    ], today);

    expect(
      sections.single.todos.map((t) => t.id),
      ['morning', 'evening', 'loose'],
    );
  });

  test('an hour without a date is never asked to sort', () {
    final todo = _todo('timed', due: today, minutes: 9 * 60);

    expect(todo.dueAt, DateTime(2026, 8, 10, 9));
    expect(_todo('plain', due: today).dueAt, today);
    expect(_todo('loose').dueAt, isNull);
  });

  test('undated to-dos keep the newest on top', () {
    final sections = groupPending([
      _todo('old', createdMinutesAgo: 120),
      _todo('fresh'),
      _todo('mid', createdMinutesAgo: 60),
    ], today);

    expect(sections.single.todos.map((t) => t.id), ['fresh', 'mid', 'old']);
  });

  test('completed to-dos come back newest first', () {
    final list = sortCompleted([
      Todo(
        id: 'first',
        text: 'first',
        done: true,
        createdAt: DateTime(2026, 8, 1),
        doneAt: DateTime(2026, 8, 2),
      ),
      Todo(
        id: 'last',
        text: 'last',
        done: true,
        createdAt: DateTime(2026, 8, 1),
        doneAt: DateTime(2026, 8, 9),
      ),
      _todo('open'),
    ]);

    expect(list.map((t) => t.id), ['last', 'first']);
  });

  test('a to-do survives a round trip through its map', () {
    final todo = _todo(
      'trip',
      due: tomorrow,
      minutes: 7 * 60 + 45,
      priority: TodoPriority.medium,
    ).copyWith(photos: const ['/a.jpg']);
    final back = Todo.fromMap(todo.toMap());

    expect(back.id, todo.id);
    expect(back.date, todo.date);
    expect(back.minutes, 7 * 60 + 45);
    expect(back.priority, TodoPriority.medium);
    expect(back.photos, ['/a.jpg']);
    expect(back.doneAt, isNull);
  });

  test('clearing the hour survives copyWith', () {
    final todo = _todo('trip', due: tomorrow, minutes: 600);

    expect(todo.copyWith(clearMinutes: true).minutes, isNull);
    expect(todo.copyWith(minutes: 60).minutes, 60);
  });
}
