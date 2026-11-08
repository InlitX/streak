import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/widgets/today_week_strip.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  final today = AppClock.today();

  Future<void> seed(WidgetTester tester) => seedHabits(tester, [
        testHabit(id: 'a', name: 'Read', done: [today.subtract(const Duration(days: 1))]),
        testHabit(id: 'b', name: 'Stretch'),
      ]);

  testWidgets('the week strip is off until it is turned on', (tester) async {
    await seed(tester);
    await pumpScreen(tester, const HomePage());
    expect(find.byType(TodayWeekStrip), findsNothing);
  });

  testWidgets('it shows the seven days of the week with today first-class',
      (tester) async {
    await seed(tester);
    await pumpScreen(
      tester,
      const HomePage(),
      settings: {'todayWeekStrip': true, 'weekStart': 1},
    );

    expect(find.byType(TodayWeekStrip), findsOneWidget);
    final first = today.startOfWeek(1);
    for (var i = 0; i < 7; i++) {
      expect(
        find.descendant(
          of: find.byType(TodayWeekStrip),
          matching: find.text('${first.addDays(i).day}'),
        ),
        findsWidgets,
      );
    }
  });

  testWidgets('tapping today lists its habits and checking one counts it',
      (tester) async {
    await seed(tester);
    await pumpScreen(
      tester,
      const HomePage(),
      settings: {'todayWeekStrip': true, 'weekStart': 1},
    );

    await tester.tap(
      find.descendant(
        of: find.byType(TodayWeekStrip),
        matching: find.text('${today.day}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 / 2'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Read'),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('days still to come cannot be opened', (tester) async {
    await seed(tester);
    await pumpScreen(
      tester,
      const HomePage(),
      settings: {'todayWeekStrip': true, 'weekStart': 1},
    );
    final first = today.startOfWeek(1);
    final ahead = [
      for (var i = 0; i < 7; i++)
        if (first.addDays(i).isAfter(today)) first.addDays(i),
    ];
    if (ahead.isEmpty) return;

    await tester.tap(
      find.descendant(
        of: find.byType(TodayWeekStrip),
        matching: find.text('${ahead.first.day}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('the week starts where the setting says', (tester) async {
    await seed(tester);
    await pumpScreen(
      tester,
      const HomePage(),
      settings: {'todayWeekStrip': true, 'weekStart': 7},
    );
    final first = today.startOfWeek(7);
    final texts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(TodayWeekStrip),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .toList();
    expect(texts.contains('${first.day}'), isTrue);
    expect(first.weekday, DateTime.sunday);
  });
}
