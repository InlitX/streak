import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/focus/widgets/focus_pill.dart';
import 'package:streak/features/focus/widgets/timer_clocks.dart';

import 'support/app_harness.dart';

Future<double> _flipHeight(WidgetTester tester, int seconds) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: FocusClock(
            style: ClockStyle.flip,
            seconds: seconds,
            progress: 0.5,
            color: Colors.orange,
            label: 'Study',
            size: 240,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  expect(tester.takeException(), isNull);
  return tester.getSize(find.byType(FocusClock)).height;
}

Future<FocusController> _pumpPill(WidgetTester tester) async {
  await pumpScreen(
    tester,
    const Scaffold(body: Center(child: FocusPill())),
    settings: {'focusEnabled': true},
  );
  return Provider.of<FocusController>(
    tester.element(find.byType(FocusPill)),
    listen: false,
  );
}

void main() {
  useEmptyStore();

  testWidgets('a flip clock past the hour takes no more room than before',
      (tester) async {
    final short = await _flipHeight(tester, 1502);
    final long = await _flipHeight(tester, 3661);

    expect(long, closeTo(short, 5));
  });

  testWidgets('the pill counts up in flowtime and down in a timed session',
      (tester) async {
    final focus = await _pumpPill(tester);

    focus.start(habitId: '', targetMinutes: 0);
    focus.pause(at: DateTime.now().add(const Duration(minutes: 3)));
    await tester.pump();
    expect(find.text('03:00'), findsOneWidget);

    focus.start(habitId: '', targetMinutes: 25);
    focus.pause(at: DateTime.now().add(const Duration(minutes: 3)));
    await tester.pump();
    expect(find.text('22:00'), findsOneWidget);
  });
}
