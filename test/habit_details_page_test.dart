import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/activity_calendar.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/day_actions_sheet.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/quantitative_progress.dart';
import 'package:streak/features/habits/widgets/minimal_detail_parts.dart';
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
    expect(find.byType(MinimalStreakTiles), findsOneWidget);

    await scrollToEnd(tester);
  });

  testWidgets('a past day can have its checklist edited from the day sheet',
      (tester) async {
    await seedHabits(tester, [
      testHabit(
        id: 'd',
        name: 'No junk',
        substeps: const [
          Substep(id: 's1', title: 'No chocolate'),
          Substep(id: 's2', title: 'No cookies'),
        ],
      ),
    ]);
    await pumpScreen(tester, const HabitDetailsPage(habitId: 'd'));

    final element = tester.element(find.byType(HabitDetailsPage));
    final habits = element.read<HabitsController>();
    final yesterday = AppClock.now().subtract(const Duration(days: 1));

    showDayActionsSheet(
      element,
      habit: habits.byId('d')!,
      date: yesterday,
      notesEnabled: false,
    );
    await tester.pumpAndSettle();

    final inSheet = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('No chocolate'),
    );
    expect(inSheet, findsOneWidget);

    await tester.tap(inSheet);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 800));

    final entry = habits.byId('d')!.completions[yesterday.dayKey];
    expect(entry, isNotNull);
    expect(entry!.steps, contains('s1'));

    await tester.tap(inSheet);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 800));

    final cleared = habits.byId('d')!.completions[yesterday.dayKey];
    expect(cleared?.steps ?? const <String>{}, isNot(contains('s1')));
    expect(habits.byId('d')!.isCompletedOn(yesterday), isFalse);

    for (final title in ['No chocolate', 'No cookies']) {
      await tester.tap(find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(title),
      ));
      await tester.pumpAndSettle();
    }
    await tester.pump(const Duration(milliseconds: 800));

    expect(habits.byId('d')!.isCompletedOn(yesterday), isTrue);
    expect(habits.byId('d')!.isCompletedOn(AppClock.now()), isFalse);
  });
}
