import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/home_shell.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/settings/pages/settings_page.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';
import 'package:streak/features/todos/pages/todos_page.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  testWidgets('classic holds the three tabs and the floating bar',
      (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', done: lastDays(5)),
    ]);
    await pumpScreen(tester, const HomeShell());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    await tester.tap(find.byIcon(LucideIcons.chartColumn).last);
    await tester.pumpAndSettle();
    expect(find.text('Stats'), findsOneWidget);
    expect(find.byType(StatisticsPage), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.settings).last);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('the to-do tab stays hidden while the setting is off',
      (tester) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
    await pumpScreen(tester, const HomeShell());

    expect(find.byIcon(LucideIcons.listChecks), findsNothing);
    expect(find.byType(TodosPage), findsNothing);
  });

  testWidgets('switching to-dos on adds the tab', (tester) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
    await pumpScreen(
      tester,
      const HomeShell(),
      settings: {'todosEnabled': true},
    );

    await tester.tap(find.byIcon(LucideIcons.listChecks));
    await tester.pumpAndSettle();
    expect(find.byType(TodosPage), findsOneWidget);
  });

  testWidgets('swiping walks from Today to the next tab', (tester) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
    await pumpScreen(
      tester,
      const HomeShell(),
      settings: {'todosEnabled': true},
    );

    await tester.fling(find.byType(HomePage), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('To-Do'), findsWidgets);
  });

  testWidgets('minimal drops the bar and keeps only the home', (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', done: lastDays(5)),
    ]);
    await pumpScreen(tester, const HomeShell(), minimal: true);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(StatisticsPage), findsNothing);
    expect(find.byType(SettingsPage), findsNothing);
  });
}
