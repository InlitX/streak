import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/minimal_form_fields.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  tearDown(() => Habit.weekStart = DateTime.monday);

  testWidgets('day pickers start on the chosen first day of the week',
      (tester) async {
    Habit.weekStart = DateTime.sunday;
    List<int>? picked;
    await pumpScreen(
      tester,
      Scaffold(
        body: CompactWeekdays(
          selected: const [],
          onChanged: (days) => picked = days,
        ),
      ),
    );

    final sun = tester.getTopLeft(find.text('Sun')).dx;
    final mon = tester.getTopLeft(find.text('Mon')).dx;
    final sat = tester.getTopLeft(find.text('Sat')).dx;
    expect(sun, lessThan(mon));
    expect(mon, lessThan(sat));

    await tester.tap(find.text('Sun'));
    expect(picked, [DateTime.sunday]);
  });
}
