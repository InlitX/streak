import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/widgets/celebration_overlay.dart';
import 'package:streak/core/widgets/confetti_overlay.dart';
import 'package:streak/core/widgets/fireworks_overlay.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

import 'support/app_harness.dart';

Future<void> pumpCelebration(WidgetTester tester, int trigger) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => SettingsController(),
      child: MaterialApp(
        home: CelebrationOverlay(trigger: trigger),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  useEmptyStore();

  testWidgets('the setting picks fireworks over confetti', (tester) async {
    await tester.runAsync(() => LocalStore.writeSetting('celebration', 1));

    await pumpCelebration(tester, 1);

    expect(find.byType(FireworksOverlay), findsOneWidget);
    expect(find.byType(ConfettiOverlay), findsNothing);
  });

  testWidgets('switching in on the first completion still animates',
      (tester) async {
    await tester.runAsync(() => LocalStore.writeSetting('celebration', 1));

    await pumpCelebration(tester, 0);
    expect(find.byType(FireworksOverlay), findsNothing);

    await pumpCelebration(tester, 1);

    final overlay = tester.state(find.byType(FireworksOverlay));
    expect(overlay.mounted, isTrue);
    expect(
      tester.widget<FireworksOverlay>(find.byType(FireworksOverlay)).trigger,
      1,
    );
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('confetti stays the default', (tester) async {
    await pumpCelebration(tester, 1);

    expect(find.byType(ConfettiOverlay), findsOneWidget);
    expect(find.byType(FireworksOverlay), findsNothing);
  });

  group('on the Today screen', () {
    Future<void> pumpThree(WidgetTester tester, {int style = 0}) async {
      await seedHabits(tester, [
        testHabit(id: 'a', name: 'Read', order: 0),
        testHabit(id: 'b', name: 'Walk', order: 1),
        testHabit(id: 'c', name: 'Water', order: 2),
      ]);
      await pumpScreen(
        tester,
        const HomePage(),
        settings: {'celebration': style},
      );
    }

    Future<void> check(WidgetTester tester, int index) async {
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(LucideIcons.check).at(index));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
    }

    int triggerOf(WidgetTester tester) =>
        tester.widget<CelebrationOverlay>(find.byType(CelebrationOverlay))
            .trigger;

    testWidgets('checking a single habit celebrates, not only the last one',
        (tester) async {
      await pumpThree(tester);
      expect(triggerOf(tester), 0);

      await check(tester, 0);

      expect(triggerOf(tester), 1);
    });

    testWidgets('the fireworks come out for a single habit too',
        (tester) async {
      await pumpThree(tester, style: 1);

      await check(tester, 0);

      expect(find.byType(FireworksOverlay), findsOneWidget);
    });

    testWidgets('unchecking does not celebrate', (tester) async {
      await pumpThree(tester);
      await check(tester, 0);
      expect(triggerOf(tester), 1);

      await check(tester, 0);

      expect(triggerOf(tester), 1);
    });
  });
}
