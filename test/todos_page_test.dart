import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/todos/pages/todos_page.dart';
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

    expect(find.byType(TodoTile), findsOneWidget);
    expect(find.text('SOMEDAY'), findsOneWidget);
    expect(find.text('Book the flight'), findsOneWidget);
  });
}
