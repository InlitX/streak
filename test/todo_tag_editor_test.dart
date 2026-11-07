import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/features/todos/data/todo_tag.dart';
import 'package:streak/features/todos/widgets/todo_tag_sheet.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  TodoTag? result;
  var closed = false;

  Future<void> open(WidgetTester tester, {TodoTag? initial}) async {
    result = null;
    closed = false;
    await pumpScreen(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                result = await showTodoTagEditor(context, initial: initial);
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> swipeAway(WidgetTester tester) async {
    await tester.fling(find.byType(BottomSheet), const Offset(0, 900), 3000);
    await tester.pumpAndSettle();
  }

  testWidgets('picking an icon or a color puts the keyboard away',
      (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Errands');
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.bySemanticsLabel('notebook'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('swiping a new tag away keeps what was typed', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Errands');
    await tester.pumpAndSettle();

    await swipeAway(tester);

    expect(closed, isTrue);
    expect(result?.name, 'Errands');
  });

  testWidgets('swiping away an empty or cleared new tag creates nothing',
      (tester) async {
    await open(tester);
    await swipeAway(tester);
    expect(closed, isTrue);
    expect(result, isNull);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Errands');
    await tester.enterText(find.byType(TextField), '  ');
    await tester.pumpAndSettle();
    await swipeAway(tester);
    expect(result, isNull);
  });

  testWidgets('swiping away while editing leaves the tag as it was',
      (tester) async {
    await open(
      tester,
      initial: const TodoTag(
        id: 't1',
        name: 'urgent',
        color: Color(0xFFFF3B30),
      ),
    );
    await tester.enterText(find.byType(TextField), 'changed');
    await tester.pumpAndSettle();

    await swipeAway(tester);

    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('save still returns the tag with its icon', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Errands');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.book).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result?.name, 'Errands');
    expect(result?.icon, 'book');
  });
}
