import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/settings/pages/minimal_settings_page.dart';
import 'package:streak/features/settings/pages/settings_page.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  testWidgets('classic lists the four sections', (tester) async {
    await pumpScreen(tester, const SettingsPage());

    expect(find.byType(ClassicSettingsPage), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);

    await scrollToEnd(tester);
  });

  testWidgets('minimal takes over the same screen', (tester) async {
    await pumpScreen(tester, const SettingsPage(), minimal: true);

    expect(find.byType(MinimalSettingsPage), findsOneWidget);
    expect(find.byType(ClassicSettingsPage), findsNothing);

    await scrollToEnd(tester);
  });

  testWidgets('the style row reads the saved style', (tester) async {
    await pumpScreen(tester, const SettingsPage());
    expect(find.text('Classic'), findsOneWidget);
  });
}
