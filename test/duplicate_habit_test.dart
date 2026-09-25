import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/habit_card.dart';

import 'support/app_harness.dart';

HabitsController _controller(WidgetTester tester) =>
    Provider.of<HabitsController>(
      tester.element(find.byType(HomePage)),
      listen: false,
    );

List<String> _names(WidgetTester tester) => [
  for (final habit in _controller(tester).habits) habit.name,
];

/// Opens the bottom sheet the way a user does: a long press on the card, then
/// the "Duplicate habit" action. The tap runs its callback outside the fake
/// async zone, because duplicating a habit writes to Hive.
Future<void> _duplicateFirstHabit(WidgetTester tester) async {
  await tester.longPress(find.byType(HabitCard).first);
  await tester.pumpAndSettle();
  await _tapSheetAction(tester, 'Duplicate habit');
}

/// Taps a bottom sheet action. The sheet is dismissed by the action itself, so
/// the callback runs after the route is gone and must be awaited outside the
/// fake async zone. Everything — the write and the snackbar it shows — is
/// settled here, so no timer is left pending when the test ends.
Future<void> _tapSheetAction(WidgetTester tester, String label) async {
  final tile = tester.widget<ListTile>(
    find.ancestor(of: find.text(label), matching: find.byType(ListTile)).first,
  );
  await tester.runAsync(() async {
    tile.onTap!();
    // Give the write enough time to land, including the debounced home-widget
    // sync the duplicate triggers.
    await Future<void>.delayed(const Duration(milliseconds: 900));
  });
  await tester.pumpAndSettle();
}

/// Taps the undo action on the snackbar left behind by a duplicate.
Future<void> _tapUndo(WidgetTester tester) async {
  final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
  await tester.runAsync(() async {
    action.onPressed();
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

/// Clears any snackbar a duplicate left behind, so its dismissal timer never
/// fires after the test has finished. Two duplicates queue two snackbars, so
/// the messenger is drained until it runs dry.
Future<void> _dismissSnackbar(WidgetTester tester) async {
  for (var round = 0; round < 5; round++) {
    final messenger = find.byType(ScaffoldMessenger);
    if (messenger.evaluate().isEmpty) return;
    tester.state<ScaffoldMessengerState>(messenger.first).clearSnackBars();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    if (find.byType(SnackBar).evaluate().isEmpty) return;
  }
}

Habit _scheduled() =>
    testHabit(
      id: 'a',
      name: 'Run',
      order: 0,
      kind: HabitKind.quantitative,
      perDayTarget: 5,
      unitLabel: 'km',
      category: 'Fitness',
      startMinute: 7 * 60,
      durationMinutes: 30,
      substeps: const [Substep(id: 's1', title: 'Stretch')],
      done: lastDays(3),
    ).copyWith(
      icon: 'run',
      description: 'Before breakfast',
      interval: HabitInterval.weekdays,
      scheduleWeekdays: const [1, 3, 5],
      reminders: const [
        Reminder(id: 'r1', hour: 7, minute: 0, days: [1, 3, 5]),
      ],
      restDays: const [6, 7],
      difficulty: 2,
    );

void main() {
  useEmptyStore();

  testWidgets('duplicating a habit copies its settings but not its history', (
    tester,
  ) async {
    await seedHabits(tester, [_scheduled()]);
    await pumpScreen(tester, const HomePage());

    await _duplicateFirstHabit(tester);

    final habits = _controller(tester).habits;
    expect(habits.length, 2);
    final source = habits.first;
    final copy = habits.last;

    expect(copy.id, isNot(source.id));
    expect(copy.name, 'Run (2)');
    expect(copy.icon, source.icon);
    expect(copy.color, source.color);
    expect(copy.category, source.category);
    expect(copy.description, source.description);
    expect(copy.kind, source.kind);
    expect(copy.perDayTarget, source.perDayTarget);
    expect(copy.unitLabel, source.unitLabel);
    expect(copy.interval, source.interval);
    expect(copy.scheduleWeekdays, source.scheduleWeekdays);
    expect(copy.startMinute, source.startMinute);
    expect(copy.durationMinutes, source.durationMinutes);
    expect(copy.difficulty, source.difficulty);
    expect(copy.restDays, source.restDays);
    expect(copy.reminders.length, source.reminders.length);
    expect(
      [for (final step in copy.substeps) step.title],
      [for (final step in source.substeps) step.title],
    );

    // A copy starts from nothing, it never inherits the streak.
    expect(copy.completions, isEmpty);
    expect(source.completions.length, 3);
    await _dismissSnackbar(tester);
  });

  testWidgets('the copy lands at the bottom of the list', (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Run', order: 0),
      testHabit(id: 'b', name: 'Water', order: 1),
    ]);
    await pumpScreen(tester, const HomePage());

    await _duplicateFirstHabit(tester);

    expect(_names(tester), ['Run', 'Water', 'Run (2)']);
    await _dismissSnackbar(tester);
  });

  testWidgets('duplicating the same habit twice never collides', (
    tester,
  ) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Run')]);
    await pumpScreen(tester, const HomePage());

    await _duplicateFirstHabit(tester);
    // Clear the first snackbar before duplicating again, otherwise the second
    // one hides a snackbar whose timer is still running.
    await _dismissSnackbar(tester);
    await _duplicateFirstHabit(tester);

    expect(_names(tester), ['Run', 'Run (2)', 'Run (3)']);
    await _dismissSnackbar(tester);
  });

  testWidgets('undo removes the copy', (tester) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Run')]);
    await pumpScreen(tester, const HomePage());

    await _duplicateFirstHabit(tester);
    expect(_names(tester).length, 2);

    await _tapUndo(tester);

    expect(_names(tester), ['Run']);
  });

  testWidgets('the copy is written to the store, without the history', (
    tester,
  ) async {
    await seedHabits(tester, [_scheduled()]);
    await pumpScreen(tester, const HomePage());

    await _duplicateFirstHabit(tester);

    // The copy reached the store, not just the in-memory controller.
    final stored = LocalStore.readHabits().values
        .where((habit) => habit.name == 'Run (2)')
        .toList();
    expect(stored.length, 1);
    expect(stored.single.completions, isEmpty);
    expect(stored.single.scheduleWeekdays, const [1, 3, 5]);
    expect(stored.single.reminders.length, 1);
  });
}
