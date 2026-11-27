import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/desk_island/desk_island_app.dart';
import 'package:streak/features/desk_island/desk_island_kit.dart';
import 'package:streak/features/desk_island/desk_island_shape.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';

import 'support/app_harness.dart';

Future<void> pumpIsland(WidgetTester tester) async {
  await pumpScreen(tester, const DeskIsland());
  tester.view.physicalSize = IslandShape.window;
  tester.view.devicePixelRatio = 1;
  await tester.pumpAndSettle();
}

void main() {
  useEmptyStore();

  test('the island shape hangs from the top edge and its region wraps it', () {
    final shape = IslandShape.centered(const Size(212, 34), 17);
    expect(shape.body.top, 0);
    expect(shape.body.center.dx, IslandShape.window.width / 2);
    expect(shape.path().contains(shape.body.center), isTrue);

    final region = shape.region(1.5);
    expect(region.length.isEven, isTrue);
    for (var i = 0; i < region.length; i += 2) {
      expect(region[i], inInclusiveRange(0, IslandShape.window.width * 1.5));
      expect(region[i + 1], inInclusiveRange(-3, 36 * 1.5));
    }
  });

  test('a typed time is read the way people write it', () {
    expect(parseClock('12:34'), 12 * 60 + 34);
    expect(parseClock('9'), 9 * 60);
    expect(parseClock('930'), 9 * 60 + 30);
    expect(parseClock('1745'), 17 * 60 + 45);
    expect(parseClock('8.5'), 8 * 60 + 50);
    expect(parseClock('18h'), 18 * 60);
    expect(parseClock('25:00'), isNull);
    expect(parseClock('7:61'), isNull);
    expect(parseClock(''), isNull);
  });

  testWidgets('the pill counts today and a tap on a habit checks it', (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read'),
      testHabit(id: 'b', name: 'Walk', order: 1),
    ]);
    await pumpIsland(tester);

    expect(find.text('0/2'), findsOneWidget);
    await tester.tapAt(const Offset(340, 16));
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Walk'), findsOneWidget);
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();

    final habits = tester.element(find.byType(DeskIsland)).read<HabitsController>();
    expect(habits.byId('a')!.isCompletedOn(AppClock.now()), isTrue);
    expect(habits.byId('b')!.isCompletedOn(AppClock.now()), isFalse);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('checking the last habit of the day shows the perfect day card', (tester) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
    await pumpIsland(tester);
    expect(find.text('All done today!'), findsNothing);

    final habits = tester.element(find.byType(DeskIsland)).read<HabitsController>();
    habits.toggle('a', AppClock.now());
    await tester.pumpAndSettle();
    expect(find.text('All done today!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('All done today!'), findsNothing);
  });

  testWidgets('a to-do typed on the island lands on today', (tester) async {
    await pumpIsland(tester);
    await tester.tapAt(const Offset(340, 16));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.squareCheckBig));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Buy milk');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final todos = tester.element(find.byType(DeskIsland)).read<TodosController>();
    final todo = todos.all.single;
    expect(todo.text, 'Buy milk');
    expect(todo.date, AppClock.today().dayKey);
    expect(find.text('Buy milk'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a to-do can go to tomorrow at a time', (tester) async {
    await pumpIsland(tester);
    await tester.tapAt(const Offset(340, 16));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.squareCheckBig));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.chevronRight).first);
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow'), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.chevronRight).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Call the bank');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final todo = tester.element(find.byType(DeskIsland)).read<TodosController>().all.single;
    expect(todo.date, AppClock.today().addDays(1).dayKey);
    expect(todo.minutes, isNotNull);
    expect(todo.minutes! % 30, 0);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('the time of a to-do can be typed', (tester) async {
    await pumpIsland(tester);
    await tester.tapAt(const Offset(340, 16));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.squareCheckBig));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Dentist');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final todo = tester.element(find.byType(DeskIsland)).read<TodosController>().all.single;
    expect(todo.minutes, 12 * 60 + 34);
    expect(todo.date, AppClock.today().dayKey);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a free focus session starts from the island', (tester) async {
    await pumpIsland(tester);
    await tester.tapAt(const Offset(340, 16));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.timer));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.play).first);
    await tester.pump();

    final focus = tester.element(find.byType(DeskIsland)).read<FocusController>();
    expect(focus.isActive, isTrue);
    expect(focus.isRunning, isTrue);
    focus.pause();
    await focus.stop(completed: false);
    await tester.pumpAndSettle();
  });
}
