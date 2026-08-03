import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/pages/focus_history_page.dart';
import 'package:streak/features/focus/pages/focus_setup_page.dart';
import 'package:streak/features/habits/pages/journey_page.dart';
import 'package:streak/features/habits/pages/notes_page.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  testWidgets('focus setup lists the habits and the start button',
      (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', order: 0),
      testHabit(id: 'b', name: 'Walk', order: 1),
    ]);
    await pumpScreen(tester, const FocusSetupPage());

    expect(find.text('What are you focusing on?'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text('Start session'), findsOneWidget);

    await tester.tap(find.text('Walk'));
    await tester.pumpAndSettle();
    expect(find.text('Start session'), findsOneWidget);
  });

  testWidgets('focus history says when there is nothing', (tester) async {
    await pumpScreen(tester, const FocusHistoryPage());

    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('notes list the day and its cards', (tester) async {
    final today = AppClock.now();
    await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
    await seedNotes(tester, [
      testNote(id: 'n1', habitId: 'a', day: today, text: 'First page'),
      testNote(id: 'n2', habitId: 'a', day: today, text: 'Second page'),
    ]);

    await pumpScreen(
      tester,
      NotesPage(habitId: 'a', date: today, accent: const Color(0xFF7C5CFF)),
    );

    expect(find.byType(NoteCard), findsNWidgets(2));
    expect(find.text('First page'), findsOneWidget);

    for (final card in tester.widgetList<NoteCard>(find.byType(NoteCard))) {
      expect(tester.getSize(find.byWidget(card)).height, greaterThan(30));
    }
  });

  testWidgets('notes with no entries show the empty line', (tester) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
    await pumpScreen(
      tester,
      NotesPage(
        habitId: 'a',
        date: AppClock.now(),
        accent: const Color(0xFF7C5CFF),
      ),
    );

    expect(find.text('No notes for this day yet'), findsOneWidget);
    expect(find.byType(NoteCard), findsNothing);
  });

  testWidgets('journey with no photos shows the empty state', (tester) async {
    await seedHabits(tester, [testHabit(id: 'a', name: 'Read')]);
    await pumpScreen(
      tester,
      const JourneyPage(habitId: 'a', accent: Color(0xFF7C5CFF)),
    );

    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('No photos yet'), findsOneWidget);
  });
}
