import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/utils/app_snackbar.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  Future<void> show(WidgetTester tester, {required bool sticky}) async {
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  AppSnackbar.info(context, 'Second chance used', sticky: sticky),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
  }

  testWidgets('a notice nobody asked for waits to be closed', (tester) async {
    await show(tester, sticky: true);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Second chance used'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();
    expect(find.text('Second chance used'), findsNothing);
  });

  testWidgets('a normal notice still goes away on its own', (tester) async {
    await show(tester, sticky: false);
    expect(find.byIcon(LucideIcons.x), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Second chance used'), findsNothing);
  });
}
