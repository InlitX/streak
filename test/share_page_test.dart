import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/share_card.dart';
import 'package:streak/features/habits/widgets/share_range_pages.dart';
import 'package:streak/features/habits/widgets/share_stat_card.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  Habit habit() => testHabit(
        id: 'run',
        name: 'Run',
        color: const Color(0xFF34D399),
        done: lastDays(12),
      );

  testWidgets('the card and every control are laid out', (tester) async {
    await pumpScreen(tester, SharePage(habit: habit()));

    expect(find.byType(ShareStatCard), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(find.byType(RepaintBoundary), findsWidgets);
  });

  testWidgets('the range tabs move the card', (tester) async {
    await pumpScreen(tester, SharePage(habit: habit()));

    final card = tester.widget<ShareStatCard>(find.byType(ShareStatCard));
    expect(card.range, ShareRange.month);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    final updated = tester.widget<ShareStatCard>(find.byType(ShareStatCard));
    expect(updated.range, ShareRange.year);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggling the stats keeps the page together', (tester) async {
    await pumpScreen(tester, SharePage(habit: habit()));

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    final card = tester.widget<ShareStatCard>(find.byType(ShareStatCard));
    expect(card.showStats, isFalse);
    expect(tester.takeException(), isNull);
  });
}
