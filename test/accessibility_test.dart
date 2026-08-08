import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/app/home_shell.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/settings/pages/settings_page.dart';

import 'support/app_harness.dart';

Future<void> _seed(WidgetTester tester) => seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', order: 0, done: lastDays(3)),
      testHabit(
        id: 'b',
        name: 'Water',
        order: 1,
        kind: HabitKind.quantitative,
        perDayTarget: 8,
        unitLabel: 'glasses',
      ),
      testHabit(id: 'c', name: 'No sugar', order: 2, kind: HabitKind.negative),
    ]);

void main() {
  useEmptyStore();

  testWidgets('classic names every check button', (tester) async {
    await _seed(tester);
    await pumpScreen(tester, const HomePage());

    expect(find.bySemanticsLabel('Mark Read as not done'), findsOneWidget);
    expect(find.bySemanticsLabel('Add to Water'), findsOneWidget);
    expect(find.bySemanticsLabel('Log a relapse for No sugar'), findsOneWidget);
  });

  testWidgets('minimal names the check buttons and the cards', (tester) async {
    await _seed(tester);
    await pumpScreen(
      tester,
      const HomePage(),
      minimal: true,
      settings: {'heatmapMode': HeatmapMode.week.index},
    );

    expect(find.bySemanticsLabel(RegExp('^Read')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Add to Water')), findsWidgets);
  });

  testWidgets('the week cells say the day and its state', (tester) async {
    await _seed(tester);
    await pumpScreen(
      tester,
      const HomePage(),
      settings: {'heatmapMode': HeatmapMode.week.index},
    );

    expect(find.bySemanticsLabel(RegExp(r', not done$')), findsWidgets);
  });

  testWidgets('the nav bar marks the selected tab', (tester) async {
    await _seed(tester);
    await pumpScreen(tester, const HomeShell());

    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Stats')),
      matchesSemantics(
        label: 'Stats',
        isButton: true,
        hasTapAction: true,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the habit form names its pickers', (tester) async {
    await pumpScreen(tester, const HabitFormPage());

    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Normal')),
      matchesSemantics(
        label: 'Normal',
        isButton: true,
        hasTapAction: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
    expect(find.bySemanticsLabel('Add step'), findsOneWidget);

    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -300),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('dumbbell'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('settings rows read as buttons', (tester) async {
    await pumpScreen(tester, const SettingsPage());

    expect(find.bySemanticsLabel('Change photo'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Appearance')), findsOneWidget);
  });

  testWidgets('the year grid stays out of the way', (tester) async {
    await _seed(tester);
    await pumpScreen(
      tester,
      const HomePage(),
      settings: {'heatmapMode': HeatmapMode.year.index},
    );

    expect(find.bySemanticsLabel(RegExp(r', not done$')), findsNothing);
  });
}
