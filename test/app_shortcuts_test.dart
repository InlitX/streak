import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/app/home_shell.dart';
import 'package:streak/core/shortcuts/app_shortcuts.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/settings/pages/settings_page.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';
import 'package:streak/features/todos/pages/todo_editor_page.dart';
import 'package:streak/features/todos/pages/todos_page.dart';

import 'support/app_harness.dart';

Future<void> chord(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool control = true,
  bool shift = false,
}) async {
  if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  useEmptyStore();

  setUp(AppShortcuts.install);
  tearDown(AppShortcuts.reset);

  Future<void> shell(WidgetTester tester) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
    await pumpScreen(tester, const HomeShell());
  }

  testWidgets('number keys jump between tabs and the settings key opens them',
      (tester) async {
    await shell(tester);
    expect(find.byType(HomePage), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.digit2);
    expect(find.byType(TodosPage), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.digit1);
    expect(find.byType(HomePage), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.comma);
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('control tab walks the tabs and wraps around both ways',
      (tester) async {
    await shell(tester);

    await chord(tester, LogicalKeyboardKey.tab, shift: true);
    expect(find.byType(SettingsPage), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.tab);
    expect(find.byType(HomePage), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.pageDown);
    await chord(tester, LogicalKeyboardKey.pageUp);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('a tab number that does not exist is ignored', (tester) async {
    await shell(tester);
    await chord(tester, LogicalKeyboardKey.digit5);
    await chord(tester, LogicalKeyboardKey.digit4);
    expect(find.byType(StatisticsPage), findsOneWidget);
  });

  testWidgets('new opens the habit form and save closes it with the habit',
      (tester) async {
    await shell(tester);

    await chord(tester, LogicalKeyboardKey.keyN);
    expect(find.byType(HabitFormPage), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.keyN);
    expect(find.byType(HabitFormPage), findsOneWidget,
        reason: 'no apila otro formulario');

    await chord(tester, LogicalKeyboardKey.keyS);
    expect(find.byType(HabitFormPage), findsOneWidget,
        reason: 'sin nombre no guarda');

    await tester.enterText(find.byType(TextField).first, 'Stretch');
    await chord(tester, LogicalKeyboardKey.keyS);
    await settle(tester);
    expect(find.byType(HabitFormPage), findsNothing);
    expect(find.text('Stretch'), findsOneWidget);
  });

  testWidgets('new in the to-do tab opens the editor, save keeps the to-do',
      (tester) async {
    await shell(tester);
    await chord(tester, LogicalKeyboardKey.digit2);

    await chord(tester, LogicalKeyboardKey.keyN);
    expect(find.byType(TodoEditorPage), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.keyN);
    expect(find.byType(TodoEditorPage), findsOneWidget,
        reason: 'no apila otro editor');

    await tester.enterText(find.byType(TextField).first, 'Buy a lamp');
    await tester.pumpAndSettle();
    await chord(tester, LogicalKeyboardKey.keyS);
    await settle(tester);
    expect(find.byType(TodoEditorPage), findsNothing);
    expect(find.text('Buy a lamp'), findsOneWidget);
  });

  testWidgets('escape closes an open editor', (tester) async {
    await shell(tester);
    await chord(tester, LogicalKeyboardKey.digit2);
    await chord(tester, LogicalKeyboardKey.keyN);
    expect(find.byType(TodoEditorPage), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.escape, control: false);
    expect(find.byType(TodoEditorPage), findsNothing);
  });

  testWidgets('find opens the to-do search and escape closes it again',
      (tester) async {
    await shell(tester);
    await chord(tester, LogicalKeyboardKey.digit2);

    await chord(tester, LogicalKeyboardKey.keyF);
    expect(find.byType(TextField), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.escape, control: false);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TodosPage), findsOneWidget);
  });

  testWidgets('F1 shows the list and shortcuts stay quiet behind it',
      (tester) async {
    await shell(tester);

    await chord(tester, LogicalKeyboardKey.f1, control: false);
    expect(find.text('Keyboard shortcuts'), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.digit2);
    expect(find.byType(TodosPage), findsNothing);

    await chord(tester, LogicalKeyboardKey.f1, control: false);
    expect(find.text('Keyboard shortcuts'), findsNothing);

    await chord(tester, LogicalKeyboardKey.slash);
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    await chord(tester, LogicalKeyboardKey.escape, control: false);
    expect(find.text('Keyboard shortcuts'), findsNothing);
  });

  testWidgets('plain letters and shift alone are never taken',
      (tester) async {
    await shell(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pumpAndSettle();
    expect(find.byType(HabitFormPage), findsNothing);
    expect(find.byType(TodosPage), findsNothing);
  });
}
