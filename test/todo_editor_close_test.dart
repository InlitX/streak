import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/todos/pages/todo_editor_page.dart';
import 'package:streak/features/todos/pages/todos_page.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  Future<void> openLamp(WidgetTester tester) async {
    await seedTodos(tester, [testTodo(id: 'a', text: 'Buy a lamp')]);
    await pumpScreen(tester, const TodosPage(),
        settings: {'todoPapers': false});
    await tester.tap(find.text('Buy a lamp'));
    await tester.pumpAndSettle();
    expect(find.byType(TodoEditorPage), findsOneWidget);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
  }

  testWidgets('checking a to-do off and going back asks nothing',
      (tester) async {
    await openLamp(tester);
    await tester.tap(find.byIcon(LucideIcons.checkCheck));
    await tester.pumpAndSettle();
    await back(tester);
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byType(TodoEditorPage), findsNothing);
    expect(LocalStore.readTodos().single.done, isTrue);
  });

  testWidgets('the leave warning can save and close', (tester) async {
    await openLamp(tester);
    await tester.enterText(find.byType(TextField).first, 'Buy two lamps');
    await tester.pumpAndSettle();
    await back(tester);

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(TodoEditorPage), findsNothing);
    expect(find.text('Buy two lamps'), findsOneWidget);
  });
}
