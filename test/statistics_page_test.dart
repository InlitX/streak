import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';
import 'package:streak/features/statistics/widgets/stat_donut.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';
import 'package:streak/features/statistics/widgets/year_heatmap.dart';

import 'support/app_harness.dart';

Future<void> _seedTwo(WidgetTester tester) => seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', order: 0, done: lastDays(9)),
      testHabit(
        id: 'b',
        name: 'Water',
        order: 1,
        kind: HabitKind.quantitative,
        perDayTarget: 8,
        done: lastDays(4),
      ),
    ]);

void main() {
  useEmptyStore();

  testWidgets('with no habits it says there is nothing yet', (tester) async {
    await pumpScreen(tester, const StatisticsPage());

    expect(find.text('No data yet'), findsOneWidget);
    expect(find.byType(YearHeatmap), findsNothing);
  });

  testWidgets('classic shows the year and the headline numbers',
      (tester) async {
    await _seedTwo(tester);
    await pumpScreen(tester, const StatisticsPage());

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.byType(YearHeatmap), findsOneWidget);
    expect(find.text('Completions'), findsOneWidget);
    expect(find.text('Best streak'), findsOneWidget);

    for (final stat in tester.widgetList<MiniStat>(find.byType(MiniStat))) {
      final size = tester.getSize(find.byWidget(stat));
      expect(size.height, greaterThan(40));
    }
  });

  testWidgets('classic draws every chart down to the bottom', (tester) async {
    await _seedTwo(tester);
    await pumpScreen(tester, const StatisticsPage());

    await scrollToEnd(tester);
    expect(find.byType(HabitDonut), findsOneWidget);
  });

  testWidgets('minimal keeps the heatmap and drops the extra charts',
      (tester) async {
    await _seedTwo(tester);
    await pumpScreen(tester, const StatisticsPage(), minimal: true);

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.byType(YearHeatmap), findsOneWidget);
    await scrollToEnd(tester);
    expect(find.byType(HabitDonut), findsNothing);
  });

  testWidgets('the year heatmap opens on the current month', (tester) async {
    await _seedTwo(tester);
    await pumpScreen(tester, const StatisticsPage());

    final scroll = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(YearHeatmap),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    final position = scroll.controller!.position;

    final today = AppClock.now().atMidnight;
    final firstOfYear = DateTime(today.year, 1, 1);
    final start = firstOfYear.subtract(Duration(days: firstOfYear.weekday - 1));
    final left = (today.difference(start).inDays ~/ 7) * 15.0;

    expect(position.maxScrollExtent, greaterThan(0));
    expect(left, greaterThanOrEqualTo(position.pixels));
    expect(
      left + 12,
      lessThanOrEqualTo(position.pixels + position.viewportDimension),
    );
  });

  testWidgets('filtering by habit keeps the page together', (tester) async {
    await _seedTwo(tester);
    await pumpScreen(tester, const StatisticsPage());

    await tester.tap(find.text('Water'));
    await tester.pumpAndSettle();

    expect(find.byType(YearHeatmap), findsOneWidget);
    await scrollToEnd(tester);
  });
}
