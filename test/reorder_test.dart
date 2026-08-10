import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/habit_card.dart';

import 'support/app_harness.dart';

List<String> _orderOf(WidgetTester tester) {
  final context = tester.element(find.byType(HomePage));
  final controller = Provider.of<HabitsController>(context, listen: false);
  return [for (final habit in controller.habits) habit.name];
}

Future<void> _dragFirstDownOneSlot(WidgetTester tester) async {
  await tester.longPress(find.byType(HabitCard).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reorder').last);
  await tester.pumpAndSettle();

  final card = find.byType(HabitCard).first;
  final step = tester.getSize(card).height + 20;
  final gesture = await tester.startGesture(tester.getCenter(card));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 200));
  await gesture.moveBy(Offset(0, step / 2));
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.moveBy(Offset(0, step / 2));
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  useEmptyStore();

  testWidgets('dragging a habit down keeps its new place', (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', order: 0),
      testHabit(id: 'b', name: 'Water', order: 1),
      testHabit(id: 'c', name: 'Walk', order: 2),
    ]);
    await pumpScreen(tester, const HomePage());

    await _dragFirstDownOneSlot(tester);

    expect(_orderOf(tester), ['Water', 'Read', 'Walk']);
  });

  testWidgets('a habit hidden by the today filter does not swallow the move',
      (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', order: 0),
      testHabit(
        id: 'b',
        name: 'Not today',
        order: 1,
        interval: HabitInterval.weekdays,
        scheduleWeekdays: [AppClock.now().add(const Duration(days: 1)).weekday],
      ),
      testHabit(id: 'c', name: 'Water', order: 2),
      testHabit(id: 'd', name: 'Walk', order: 3),
    ]);
    await pumpScreen(tester, const HomePage(), settings: {'todayOnly': true});

    await _dragFirstDownOneSlot(tester);

    expect(_orderOf(tester), ['Water', 'Not today', 'Read', 'Walk']);
  });
}
