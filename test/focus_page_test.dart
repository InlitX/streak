import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/focus/pages/focus_page.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  setUp(() {
    for (final name in const [
      'dev.fluttercommunity.plus/wakelock',
      'flutter.baseflow.com/permissions/methods',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (call) async => 1);
    }
  });

  testWidgets('starting a session stays on the timer instead of popping back',
      (tester) async {
    await pumpScreen(
      tester,
      const Scaffold(body: SizedBox.shrink()),
      settings: {'focusKeepAwake': false},
    );

    AppNavigator.push(
      const FocusPage(startHabitId: '', startMinutes: 25),
      fade: true,
      name: FocusPage.routeName,
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(FocusPage), findsOneWidget);
  });
}
