import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/home_page.dart';

import 'support/app_harness.dart';

const _warning = 'Day not scheduled';

int get _today => AppClock.now().weekday;

int get _otherWeekday => _today == 1 ? 2 : 1;

Finder _button(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    );

Future<void> _tapCheck(WidgetTester tester) async {
  await tester.tap(_button('Mark Read as done'));
  await tester.pumpAndSettle();
}

Future<void> _pumpWith(WidgetTester tester, Habit habit) async {
  await seedHabits(tester, [habit]);
  await pumpScreen(tester, const HomePage());
}

void main() {
  useEmptyStore();

  testWidgets('a weekday outside the schedule warns first', (tester) async {
    await _pumpWith(
      tester,
      testHabit(
        id: 'a',
        name: 'Read',
        interval: HabitInterval.weekdays,
        scheduleWeekdays: [_otherWeekday],
      ),
    );

    await _tapCheck(tester);
    expect(find.text(_warning), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text(_warning), findsNothing);
  });

  testWidgets('a rest day warns too', (tester) async {
    await _pumpWith(
      tester,
      testHabit(id: 'a', name: 'Read', restDays: [_today]),
    );

    await _tapCheck(tester);
    expect(find.text(_warning), findsOneWidget);
    expect(find.text('Log anyway'), findsOneWidget);
  });

  testWidgets('a scheduled day logs straight away', (tester) async {
    await _pumpWith(tester, testHabit(id: 'a', name: 'Read'));

    await _tapCheck(tester);
    expect(find.text(_warning), findsNothing);
  });

  testWidgets('an already logged day does not warn again', (tester) async {
    await _pumpWith(
      tester,
      testHabit(
        id: 'a',
        name: 'Read',
        restDays: [_today],
        done: lastDays(1),
      ),
    );

    await tester.tap(_button('Mark Read as not done'));
    await tester.pumpAndSettle();
    expect(find.text(_warning), findsNothing);
  });
}
