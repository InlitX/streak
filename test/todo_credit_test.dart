import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/todo_credit.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_tag.dart';
import 'package:streak/features/todos/pages/todos_page.dart';
import 'package:streak/features/todos/state/todos_controller.dart';

import 'support/app_harness.dart';

Todo _todo(String id, {String project = '', List<String> tags = const [], bool done = false}) =>
    Todo(
      id: id,
      text: id,
      project: project,
      tags: tags,
      done: done,
      doneAt: done ? AppClock.wallNow() : null,
      createdAt: AppClock.wallNow(),
    );

Habit _linked(String link, {HabitKind kind = HabitKind.positive, bool focusOnly = false}) =>
    testHabit(
      id: 'h',
      name: 'Read one book',
      kind: kind,
      perDayTarget: kind == HabitKind.quantitative ? 3 : 1,
      focusOnly: focusOnly,
    ).copyWith(todoLink: link);

Todo _check(Todo todo) => todo.copyWith(done: true, doneAt: AppClock.wallNow());

void main() {
  final today = AppClock.today();

  test('checking a to-do in the linked project checks the habit', () {
    final habits = {'h': _linked('books')};
    final todo = _todo('a', project: 'books');
    final touched = TodoCredit.apply(habits, [todo], before: todo, after: _check(todo));

    expect(touched, {'h'});
    expect(habits['h']!.isCompletedOn(today), isTrue);
  });

  test('a to-do with the linked tag counts too', () {
    final habits = {'h': _linked('reading')};
    final todo = _todo('a', tags: ['reading']);
    TodoCredit.apply(habits, [todo], before: todo, after: _check(todo));

    expect(habits['h']!.isCompletedOn(today), isTrue);
  });

  test('a to-do from somewhere else leaves the habit alone', () {
    final habits = {'h': _linked('books')};
    final todo = _todo('a', project: 'work');
    final touched = TodoCredit.apply(habits, [todo], before: todo, after: _check(todo));

    expect(touched, isEmpty);
    expect(habits['h']!.isCompletedOn(today), isFalse);
  });

  test('unchecking the to-do unchecks the habit', () {
    final habits = {'h': _linked('books')};
    final todo = _todo('a', project: 'books');
    final done = _check(todo);
    TodoCredit.apply(habits, [done], before: todo, after: done);
    TodoCredit.apply(habits, [todo], before: done, after: todo);

    expect(habits['h']!.isCompletedOn(today), isFalse);
  });

  test('the habit stays checked while another linked to-do is done', () {
    final habits = {'h': _linked('books')};
    final first = _todo('a', project: 'books');
    final second = _check(_todo('b', project: 'books'));
    final done = _check(first);
    TodoCredit.apply(habits, [done, second], before: first, after: done);
    TodoCredit.apply(habits, [first, second], before: done, after: first);

    expect(habits['h']!.isCompletedOn(today), isTrue);
  });

  test('an amount habit adds one per to-do and takes it back', () {
    final habits = {'h': _linked('books', kind: HabitKind.quantitative)};
    final a = _todo('a', project: 'books');
    final b = _todo('b', project: 'books');
    TodoCredit.apply(habits, [a, b], before: a, after: _check(a));
    TodoCredit.apply(habits, [a, b], before: b, after: _check(b));
    expect(habits['h']!.completions[today.dayKey]!.count, 2);

    TodoCredit.apply(habits, [a, b], before: _check(b), after: b);
    expect(habits['h']!.completions[today.dayKey]!.count, 1);
  });

  test('a repeating to-do counts through its done record', () {
    final habits = {'h': _linked('books')};
    final record = _todo('r', project: 'books', done: true);
    TodoCredit.apply(habits, [record], after: record);

    expect(habits['h']!.isCompletedOn(today), isTrue);
  });

  test('a focus only habit is never checked by a to-do', () {
    final habits = {'h': _linked('books', focusOnly: true)};
    final todo = _todo('a', project: 'books');
    final touched = TodoCredit.apply(habits, [todo], before: todo, after: _check(todo));

    expect(touched, isEmpty);
  });

  test('the link survives a save and a load', () {
    final habit = _linked('books');
    expect(Habit.fromMap(habit.toMap()).todoLink, 'books');
    expect(testHabit(id: 'x', name: 'x').toMap().containsKey('todoLink'), isFalse);
  });

  group('in the app', () {
    useEmptyStore();

    Future<void> seedBooks(WidgetTester tester) => tester.runAsync(() async {
          await LocalStore.writeTodoTag(
            const TodoTag(
              id: 'books',
              name: 'Books I want to read',
              color: Color(0xFF7C5CFC),
              kind: TodoTagKind.project,
            ),
          );
        });

    testWidgets('ticking the to-do in the list checks the habit',
        (tester) async {
      await seedBooks(tester);
      await seedHabits(tester, [_linked('books')]);
      await seedTodos(tester, [_todo('Dune', project: 'books')]);
      await pumpScreen(tester, const TodosPage(), settings: {'todoPapers': false});

      final context = tester.element(find.byType(TodosPage));
      final habits = context.read<HabitsController>();
      final todos = context.read<TodosController>();
      todos.onDone = habits.creditTodo;

      unawaited(todos.toggle('Dune'));
      await tester.pump(const Duration(seconds: 2));
      expect(habits.byId('h')!.isCompletedOn(today), isTrue);

      unawaited(todos.toggle('Dune'));
      await tester.pump(const Duration(seconds: 2));
      expect(habits.byId('h')!.isCompletedOn(today), isFalse);
      await tester.pump(const Duration(seconds: 5));
    });

    for (final (style, name) in [(0, 'classic'), (1, 'minimal'), (2, 'express')]) {
    testWidgets('the $name habit form links a project', (tester) async {
      await seedBooks(tester);
      await pumpScreen(tester, const HabitFormPage(), settings: {'appStyle': style});

      await tester.enterText(find.byType(TextField).first, 'Read one book');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Count to-dos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Count to-dos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Books I want to read').last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'Books I want to read'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      final saved = LocalStore.readHabits().values.single;
      expect(saved.todoLink, 'books');
    });
    }
  });
}
