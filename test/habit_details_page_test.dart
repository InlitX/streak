import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/widgets/activity_calendar.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/quantitative_progress.dart';
import 'package:streak/features/habits/widgets/streak_summary.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  testWidgets('a positive habit shows its streaks and activity',
      (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', done: lastDays(6)),
    ]);
    await pumpScreen(tester, const HabitDetailsPage(habitId: 'a'));

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('STREAKS'), findsOneWidget);
    expect(find.text('ACTIVITY'), findsOneWidget);
    expect(find.byType(StreakSummary), findsOneWidget);

    await scrollToEnd(tester);
  });

  testWidgets('a quantitative habit shows its progress', (tester) async {
    await seedHabits(tester, [
      testHabit(
        id: 'b',
        name: 'Water',
        kind: HabitKind.quantitative,
        perDayTarget: 8,
        unitLabel: 'glasses',
        done: lastDays(3),
      ),
    ]);
    await pumpScreen(tester, const HabitDetailsPage(habitId: 'b'));

    expect(find.byType(QuantitativeProgress), findsOneWidget);
    await scrollToEnd(tester);
  });

  testWidgets('a negative habit opens without a relapse', (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'c', name: 'No sugar', kind: HabitKind.negative),
    ]);
    await pumpScreen(tester, const HabitDetailsPage(habitId: 'c'));

    expect(find.text('No sugar'), findsOneWidget);
    await scrollToEnd(tester);
  });

  testWidgets('the toggle swaps calendar and heatmap', (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', done: lastDays(6)),
    ]);
    await pumpScreen(
      tester,
      const HabitDetailsPage(habitId: 'a'),
      settings: {'heatmapMode': HeatmapMode.month.index},
    );

    expect(find.byType(ActivityCalendar), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityCalendar), findsNothing);
    expect(find.byType(HabitHeatmap), findsOneWidget);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.byType(HabitHeatmap), findsOneWidget);
  });

  testWidgets('minimal draws its own header', (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', done: lastDays(6)),
    ]);
    await pumpScreen(
      tester,
      const HabitDetailsPage(habitId: 'a'),
      minimal: true,
    );

    expect(find.text('Read'), findsOneWidget);
    expect(find.byType(StreakSummary), findsOneWidget);

    await scrollToEnd(tester);
  });
}
