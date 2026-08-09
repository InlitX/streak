import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/focus/pages/focus_setup_page.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/day_timeline_page.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/settings/pages/settings_page.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  Future<void> seed(WidgetTester tester) => seedHabits(tester, [
        testHabit(
          id: 'a',
          name: 'Read a chapter',
          order: 0,
          done: lastDays(4),
          startMinute: 9 * 60,
          durationMinutes: 60,
        ),
        testHabit(
          id: 'b',
          name: 'Drink water',
          order: 1,
          kind: HabitKind.quantitative,
          perDayTarget: 8,
          unitLabel: 'glasses',
          category: 'health',
          done: lastDays(2),
        ),
        testHabit(id: 'c', name: 'No sugar', order: 2, kind: HabitKind.negative),
      ]);

  final screens = <String, Widget>{
    'today': const HomePage(),
    'stats': const StatisticsPage(),
    'settings': const SettingsPage(),
    'form': const HabitFormPage(),
    'focus': const FocusSetupPage(),
    'details': const HabitDetailsPage(habitId: 'a'),
    'timeline': const DayTimelinePage(),
  };

  for (final entry in screens.entries) {
    for (final minimal in [false, true]) {
      testWidgets('${entry.key} ${minimal ? "minimal" : "classic"} fits',
          (tester) async {
        await seed(tester);
        await pumpScreen(tester, entry.value, minimal: minimal, textScale: 2);
        await scrollToEnd(tester, drags: 6);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the activity tabs are not cut off', (tester) async {
    await seed(tester);
    await pumpScreen(
      tester,
      const HabitDetailsPage(habitId: 'a'),
      textScale: 2,
    );
    tester.view.devicePixelRatio = 3;
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Week'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    for (final label in ['Week', 'Month', 'Year']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
    }
  });

  testWidgets('the minimal week card keeps the name readable', (tester) async {
    await seed(tester);
    await pumpScreen(
      tester,
      const HomePage(),
      minimal: true,
      textScale: 2,
      settings: {'heatmapMode': HeatmapMode.week.index},
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Read a chapter'), findsOneWidget);
    final name = tester.getSize(find.text('Read a chapter'));
    expect(name.width, greaterThan(80));
  });
}
