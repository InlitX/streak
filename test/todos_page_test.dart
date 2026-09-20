import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_tag.dart';
import 'package:streak/features/todos/pages/todos_page.dart';
import 'package:streak/features/todos/widgets/todo_tag_sheet.dart';
import 'package:streak/features/todos/widgets/todo_tile.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  final today = AppClock.now();

  Future<void> seedFour(WidgetTester tester) => seedTodos(tester, [
        testTodo(id: 'a', text: 'Call the plumber', due: today),
        testTodo(
          id: 'b',
          text: 'Pay the bill',
          due: today.subtract(const Duration(days: 3)),
        ),
        testTodo(id: 'c', text: 'Buy a lamp'),
        testTodo(id: 'd', text: 'Water the plants', done: true),
      ]);

  testWidgets('the list splits into the groups their dates ask for',
      (tester) async {
    await seedFour(tester);
    await pumpScreen(tester, const TodosPage());

    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('SOMEDAY'), findsOneWidget);
    expect(find.text('Completed (1)'), findsOneWidget);
    expect(find.byType(TodoTile), findsNWidgets(3));
  });

  testWidgets('completed to-dos stay folded until you open them',
      (tester) async {
    await seedFour(tester);
    await pumpScreen(tester, const TodosPage());

    expect(find.text('Water the plants'), findsNothing);

    await tester.tap(find.text('Completed (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Water the plants'), findsOneWidget);
  });

  testWidgets('checking a to-do moves it down to completed', (tester) async {
    final handle = tester.ensureSemantics();
    await seedFour(tester);
    await pumpScreen(tester, const TodosPage());

    await tester.tap(find.bySemanticsLabel('Mark Buy a lamp as done'));
    await tester.pumpAndSettle();

    expect(find.text('Completed (2)'), findsOneWidget);
    expect(find.text('SOMEDAY'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    handle.dispose();
  });

  testWidgets('choosing a date opens the calendar and leaves it open',
      (tester) async {
    await pumpScreen(tester, const TodosPage());

    await tester.tap(find.widgetWithIcon(FilledButton, LucideIcons.plus));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.calendar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick a date'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('an hour picked for a to-do reaches its tile', (tester) async {
    await seedTodos(tester, [
      testTodo(id: 'a', text: 'Call the plumber', due: today, minutes: 9 * 60),
    ]);
    await pumpScreen(tester, const TodosPage());

    expect(find.text('Today · 9:00 AM'), findsOneWidget);
  });

  testWidgets('writing a to-do adds it to the list', (tester) async {
    await pumpScreen(tester, const TodosPage());

    expect(find.text('Nothing on the list'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(FilledButton, LucideIcons.plus));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Book the flight');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.arrowUp));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(TodoTile), findsOneWidget);
    expect(find.text('SOMEDAY'), findsOneWidget);
    expect(find.text('Book the flight'), findsOneWidget);
  });

  testWidgets('the search box keeps only what matches, done ones included',
      (tester) async {
    await seedTodos(tester, [
      testTodo(id: 'a', text: 'Call the plumber', due: today),
      testTodo(id: 'b', text: 'Buy new running shoes'),
      testTodo(id: 'c', text: 'Buy milk', done: true),
    ]);
    await pumpScreen(tester, const TodosPage());

    await tester.tap(find.byIcon(LucideIcons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'buy');
    await tester.pumpAndSettle();

    expect(find.text('Buy new running shoes'), findsOneWidget);
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Call the plumber'), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(find.text('Call the plumber'), findsOneWidget);
  });

  Future<void> seedProjects(WidgetTester tester) => tester.runAsync(() async {
        const names = ['One', 'Two', 'Three', 'Four'];
        for (final (index, name) in names.indexed) {
          await LocalStore.writeTodoTag(
            TodoTag(
              id: 'p$index',
              name: name,
              color: const Color(0xFF7C5CFC),
              order: index,
              kind: TodoTagKind.project,
            ),
          );
        }
      });

  List<String> onScreen(WidgetTester tester) {
    final found = <(Offset, String)>[
      for (final name in const ['One', 'Two', 'Three', 'Four'])
        (tester.getCenter(find.text(name)), name),
    ];
    found.sort((a, b) {
      final row = (a.$1.dy ~/ 40).compareTo(b.$1.dy ~/ 40);
      return row != 0 ? row : a.$1.dx.compareTo(b.$1.dx);
    });
    return [for (final entry in found) entry.$2];
  }

  testWidgets('the menu opens the arranging mode and the drag sticks',
      (tester) async {
    await seedProjects(tester);
    await pumpScreen(tester, const TodosPage());

    expect(onScreen(tester), ['One', 'Two', 'Three', 'Four']);

    await tester.tap(find.byIcon(LucideIcons.ellipsis).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rearrange'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Done'), findsOneWidget);

    final start = tester.getCenter(find.text('One'));
    final target = tester.getCenter(find.text('Three'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(onScreen(tester), ['Two', 'Three', 'One', 'Four']);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('inside a project the bar only offers that project tags',
      (tester) async {
    await tester.runAsync(() async {
      for (final tag in const [
        TodoTag(id: 'p1', name: 'School', color: Color(0xFF7C5CFC),
            kind: TodoTagKind.project),
        TodoTag(id: 'p2', name: 'Work', color: Color(0xFF34C759), order: 1,
            kind: TodoTagKind.project),
        TodoTag(id: 't1', name: 'urgent', color: Color(0xFFFF3B30)),
        TodoTag(id: 't2', name: 'later', color: Color(0xFF5AC8FA), order: 1),
      ]) {
        await LocalStore.writeTodoTag(tag);
      }
      for (final todo in [
        Todo(id: 'a', text: 'Maths homework', project: 'p1',
            tags: const ['t1'], createdAt: AppClock.now()),
        Todo(id: 'b', text: 'Send the invoice', project: 'p2',
            tags: const ['t2'], createdAt: AppClock.now()),
      ]) {
        await LocalStore.writeTodo(todo);
      }
    });
    await pumpScreen(tester, const TodosPage());

    await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.list));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TodoTagChip, 'urgent'), findsOneWidget);
    expect(find.widgetWithText(TodoTagChip, 'later'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.folder));
    await tester.pumpAndSettle();
    await tester.tap(find.text('School'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TodoTagChip, 'urgent'), findsOneWidget);
    expect(find.widgetWithText(TodoTagChip, 'later'), findsNothing);
    expect(find.text('Send the invoice'), findsNothing);
  });
}
