import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/widgets/scrolling_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

HeatmapMode _openingMode(WidgetTester tester) => tester
    .widgetList<HabitHeatmap>(find.byType(HabitHeatmap))
    .firstWhere((h) => h.mode != HeatmapMode.mini)
    .mode;

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

    testWidgets('by default it opens on the view you left', (tester) async {
      await _seedThree(tester);
      await _pumpHome(tester, HeatmapMode.month);

      expect(_openingMode(tester), HeatmapMode.month);
    });

    testWidgets('a fixed start view beats the one you left', (tester) async {
      await _seedThree(tester);
      await pumpScreen(
        tester,
        const HomePage(),
        settings: {
          'heatmapMode': HeatmapMode.year.index,
          'startView': HeatmapMode.week.index + 1,
        },
      );

      expect(_openingMode(tester), HeatmapMode.week);
    });

    testWidgets('with no habits it offers to add one', (tester) async {
      await pumpScreen(tester, const HomePage());

      expect(find.byType(HabitCard), findsNothing);
      expect(find.text('Add habit'), findsOneWidget);
    });

    testWidgets('hiding the activity drops the grids and the view selector',
        (tester) async {
      await _seedThree(tester);
      await pumpScreen(
        tester,
        const HomePage(),
        settings: {
          'heatmapMode': HeatmapMode.week.index,
          'cardActivity': false,
        },
      );

      expect(find.byType(HabitCard), findsNWidgets(3));
      expect(find.byType(HabitHeatmap), findsNothing);
      expect(find.text('Week'), findsNothing);
    });

    testWidgets('the week strip stamps every day with its date', (tester) async {
      await _seedThree(tester);
      await _pumpHome(tester, HeatmapMode.week);

      final start = AppClock.now().startOfWeek(1);
      for (var i = 0; i < 7; i++) {
        expect(
          find.text('${start.add(Duration(days: i)).day}'),
          findsWidgets,
          reason: 'day ${i + 1}',
        );
      }
    });

    testWidgets('every day in the strip can be logged on its own',
        (tester) async {
      final handle = tester.ensureSemantics();
      await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
      await _pumpHome(tester, HeatmapMode.week);

      expect(
        tester.widget<HabitHeatmap>(find.byType(HabitHeatmap).first).onToggle,
        isNotNull,
      );
      final today = AppClock.now();
      expect(
        find.bySemanticsLabel(RegExp('${today.day}.*not done')),
        findsWidgets,
      );
      handle.dispose();
    });

    testWidgets('the collapse button is there to shrink the cards',
        (tester) async {
      await _seedThree(tester);
      await _pumpHome(tester, HeatmapMode.week);

      expect(find.byIcon(LucideIcons.chevronsDownUp), findsOneWidget);
      expect(find.byType(HabitHeatmap), findsWidgets);
    });

    testWidgets('collapsed cards shrink and join into one block',
        (tester) async {
      await _seedThree(tester);
      await pumpScreen(
        tester,
        const HomePage(),
        settings: {
          'heatmapMode': HeatmapMode.week.index,
          'compactCards': true,
        },
      );

      expect(find.byType(HabitHeatmap), findsNothing);
      expect(find.byIcon(LucideIcons.chevronsUpDown), findsOneWidget);

      final cards = tester.widgetList<HabitCard>(find.byType(HabitCard));
      expect(tester.getSize(find.byType(HabitCard).first).height, lessThan(80));
      expect(cards.first.corners!.topLeft.x, greaterThan(15));
      expect(cards.first.corners!.bottomLeft.x, lessThan(15));
      expect(cards.last.corners!.bottomLeft.x, greaterThan(15));
    });

  });

  group('minimal', () {
    testWidgets('the week view lists every habit', (tester) async {
      await _seedThree(tester);
      await _pumpHome(tester, HeatmapMode.week, minimal: true);

      expect(find.byType(GridWeekCard), findsNWidgets(3));
      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('the week card keeps the name on one line with the days',
        (tester) async {
      await _seedThree(tester);
      await _pumpHome(tester, HeatmapMode.week, minimal: true);

      final card = find.ancestor(
        of: find.text('Read'),
        matching: find.byType(GridWeekCard),
      );
      final name = tester.getRect(
        find.descendant(of: card, matching: find.byType(ScrollingText)),
      );

      expect(tester.getSize(card).height, lessThan(90));
      expect(find.text('${AppClock.now().day}'), findsNothing);
      expect(name.width, greaterThan(60));
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
