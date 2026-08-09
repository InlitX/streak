import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/day_timeline_page.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/day_timeline_parts.dart';

import 'support/app_harness.dart';

Future<void> _waitFor(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 80; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    if (done()) return;
  }
}

HabitsController _controller(WidgetTester tester) =>
    Provider.of<HabitsController>(
      tester.element(find.byType(DayTimelinePage)),
      listen: false,
    );

void main() {
  useEmptyStore();

  testWidgets('with nothing planned it explains what to do', (tester) async {
    await pumpScreen(tester, const DayTimelinePage());

    expect(find.text('Nothing planned for this day'), findsOneWidget);
    expect(find.byType(TimelineBlock), findsNothing);
  });

  testWidgets('planned habits are drawn in order with the free time between',
      (tester) async {
    await seedHabits(tester, [
      testHabit(
        id: 'b',
        name: 'Run',
        order: 1,
        startMinute: 13 * 60,
        durationMinutes: 30,
      ),
      testHabit(
        id: 'a',
        name: 'Read',
        order: 0,
        startMinute: 9 * 60,
        durationMinutes: 60,
      ),
      testHabit(id: 'c', name: 'Water', order: 2),
    ]);
    await pumpScreen(tester, const DayTimelinePage());

    expect(find.byType(TimelineBlock), findsNWidgets(2));
    expect(find.byType(TimelineGap), findsOneWidget);
    expect(find.text('3h free'), findsOneWidget);
    expect(find.text('09:00 - 10:00  ·  1h'), findsOneWidget);
    expect(find.text('13:00 - 13:30  ·  30m'), findsOneWidget);

    final blocks = tester.widgetList<TimelineBlock>(find.byType(TimelineBlock));
    expect(blocks.map((b) => b.habit.name), ['Read', 'Run']);

    expect(find.text('ANYTIME'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
  });

  testWidgets('the check marks the habit for that day', (tester) async {
    await seedHabits(tester, [
      testHabit(
        id: 'a',
        name: 'Read',
        startMinute: 9 * 60,
        durationMinutes: 60,
      ),
    ]);
    await pumpScreen(tester, const DayTimelinePage());

    final controller = _controller(tester);
    expect(controller.byId('a')!.isCompletedOn(AppClock.now()), isFalse);

    await tester.runAsync(() => tester.tap(find.byType(TimelineCheck)));
    await _waitFor(
      tester,
      () => controller.byId('a')!.isCompletedOn(AppClock.now()),
    );

    expect(controller.byId('a')!.isCompletedOn(AppClock.now()), isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('a focus only habit asks for a session instead of ticking',
      (tester) async {
    await seedHabits(tester, [
      testHabit(
        id: 'a',
        name: 'Study',
        startMinute: 9 * 60,
        durationMinutes: 45,
        focusOnly: true,
      ),
    ]);
    await pumpScreen(tester, const DayTimelinePage());

    final controller = _controller(tester);
    await tester.tap(find.byType(TimelineCheck));
    await tester.pumpAndSettle();

    expect(controller.byId('a')!.isCompletedOn(AppClock.now()), isFalse);
    expect(find.byType(TimelineBlock), findsOneWidget);
  });

  testWidgets('Today hides the day button until planning is on',
      (tester) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
    await pumpScreen(tester, const HomePage());

    expect(find.byIcon(LucideIcons.calendarClock), findsNothing);
  });

  testWidgets('Today shows the day button once planning is on',
      (tester) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
    await pumpScreen(
      tester,
      const HomePage(),
      settings: {'planningEnabled': true},
    );

    expect(find.byIcon(LucideIcons.calendarClock), findsOneWidget);
  });

  testWidgets('a habit measured in amounts adds one tap at a time',
      (tester) async {
    await seedHabits(tester, [
      testHabit(
        id: 'a',
        name: 'Water',
        kind: HabitKind.quantitative,
        perDayTarget: 8,
        unitLabel: 'glasses',
        startMinute: 9 * 60,
        durationMinutes: 30,
      ),
    ]);
    await pumpScreen(tester, const DayTimelinePage());

    final controller = _controller(tester);
    expect(find.text('0/8 glasses'), findsOneWidget);

    await tester.runAsync(() => tester.tap(find.byType(TimelineCheck)));
    await _waitFor(
      tester,
      () =>
          (controller.byId('a')!.completions[AppClock.now().dayKey]?.count ??
              0) >
          0,
    );

    expect(controller.byId('a')!.isCompletedOn(AppClock.now()), isFalse);
    expect(find.text('1/8 glasses'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('the week arrows move the day and nothing is done yet',
      (tester) async {
    await seedHabits(tester, [
      testHabit(
        id: 'a',
        name: 'Read',
        startMinute: 9 * 60,
        durationMinutes: 30,
        daysOld: 400,
      ),
    ]);
    await pumpScreen(tester, const DayTimelinePage());

    expect(find.byType(TimelineBlock), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.chevronRight));
    await tester.pumpAndSettle();

    expect(find.byType(TimelineBlock), findsOneWidget);
    final block = tester.widget<TimelineBlock>(find.byType(TimelineBlock));
    expect(block.done, isFalse);
    expect(find.byIcon(LucideIcons.calendarCheck), findsOneWidget);
  });
}
