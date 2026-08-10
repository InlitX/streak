import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/widgets/scrolling_text.dart';

const _style = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

Future<void> _pump(
  WidgetTester tester,
  String text, {
  bool animations = true,
}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: MediaQueryData(disableAnimations: !animations),
              child: SizedBox(
                width: 120,
                child: ScrollingText(text, style: _style),
              ),
            ),
          ),
        ),
      ),
    );

double _offset(WidgetTester tester) =>
    tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!
        .offset;

double _room(WidgetTester tester) =>
    tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!
        .position
        .maxScrollExtent;

void main() {
  testWidgets('a name that fits never moves', (tester) async {
    await _pump(tester, 'Read');
    await tester.pump();

    expect(_room(tester), 0);
    await tester.pump(const Duration(seconds: 4));
    expect(_offset(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a name too long slides out and comes back', (tester) async {
    await _pump(tester, 'Read twenty pages before going to sleep');
    await tester.pump();

    final room = _room(tester);
    expect(room, greaterThan(0));
    expect(_offset(tester), 0);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(seconds: 4));
    expect(_offset(tester), greaterThan(0));

    await tester.pumpAndSettle();
    expect(_offset(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('with animations off it falls back to an ellipsis',
      (tester) async {
    await _pump(tester, 'Read twenty pages before going to sleep',
        animations: false);
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(
      tester.widget<Text>(find.byType(Text)).overflow,
      TextOverflow.ellipsis,
    );
  });
}
