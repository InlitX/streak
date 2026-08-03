import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/widgets/grid_habit_cards.dart';
import 'package:streak/features/habits/widgets/habit_card.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';

import 'support/app_harness.dart';

Future<void> _seedThree(WidgetTester tester) => seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', order: 0, done: lastDays(4)),
      testHabit(
        id: 'b',
        name: 'Water',
        order: 1,
        kind: HabitKind.quantitative,
        perDayTarget: 8,
        unitLabel: 'glasses',
        done: lastDays(2),
      ),
      testHabit(id: 'c', name: 'No sugar', order: 2, kind: HabitKind.negative),
    ]);

Future<void> _pumpHome(
  WidgetTester tester,
  HeatmapMode mode, {
  bool minimal = false,
}) =>
    pumpScreen(
      tester,
      const HomePage(),
      minimal: minimal,
      settings: {'heatmapMode': mode.index},
    );

const _views = [HeatmapMode.week, HeatmapMode.month, HeatmapMode.year];

void main() {
  useEmptyStore();

  group('classic', () {
    for (final mode in _views) {
      testWidgets('the ${mode.name} view builds every card', (tester) async {
        await _seedThree(tester);
        await _pumpHome(tester, mode);

        expect(find.text('Read'), findsOneWidget);

        final cards = find.byType(HabitCard);
        for (var i = 0; i < cards.evaluate().length; i++) {
          final size = tester.getSize(cards.at(i));
          expect(size.height, greaterThan(80));
          expect(size.width, greaterThan(200));
        }

        await tester.scrollUntilVisible(
          find.text('No sugar'),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('No sugar'), findsOneWidget);
      });
    }

    testWidgets('with no habits it offers to add one', (tester) async {
      await pumpScreen(tester, const HomePage());

      expect(find.byType(HabitCard), findsNothing);
      expect(find.text('Add habit'), findsOneWidget);
    });
  });

  group('minimal', () {
    testWidgets('the week view lists every habit', (tester) async {
      await _seedThree(tester);
      await _pumpHome(tester, HeatmapMode.week, minimal: true);

      expect(find.byType(GridWeekCard), findsNWidgets(3));
      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('the year view lists every habit', (tester) async {
      await _seedThree(tester);
      await _pumpHome(tester, HeatmapMode.year, minimal: true);

      expect(find.byType(GridYearCard), findsNWidgets(3));
      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('month cards keep their calendar height', (tester) async {
      await _seedThree(tester);
      await _pumpHome(tester, HeatmapMode.month, minimal: true);

      final cards = find.byType(GridMonthCard);
      expect(cards, findsNWidgets(3));

      for (var i = 0; i < 3; i++) {
        final size = tester.getSize(cards.at(i));
        expect(size.height, greaterThan(180));
        expect(size.width, greaterThan(120));
      }
    });

    testWidgets('the switcher moves between views', (tester) async {
      await _seedThree(tester);
      await _pumpHome(tester, HeatmapMode.month, minimal: true);

      await tester.tap(find.byIcon(Icons.checklist_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(GridWeekCard), findsNWidgets(3));
      expect(find.byType(GridMonthCard), findsNothing);

      await tester.tap(find.byIcon(Icons.view_agenda_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(GridYearCard), findsNWidgets(3));
    });

    testWidgets('paired month cards match in height', (tester) async {
      await _seedThree(tester);
      await _pumpHome(tester, HeatmapMode.month, minimal: true);

      final cards = find.byType(GridMonthCard);
      expect(
        tester.getSize(cards.at(0)).height,
        tester.getSize(cards.at(1)).height,
      );
    });
  });
}
