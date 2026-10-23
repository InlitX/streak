import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/i18n/app_locale.dart';

void main() {
  test('a language the app does not ship falls back to English, not German', () {
    expect(pickLocale(const [Locale('fi', 'FI')]), const Locale('en'));
    expect(pickLocale(const [Locale('und')]), const Locale('en'));
    expect(pickLocale(null), const Locale('en'));
  });

  test('the first shipped language in the system list wins', () {
    expect(
      pickLocale(const [Locale('fi'), Locale('es', 'ES'), Locale('en')]),
      const Locale('es'),
    );
    expect(pickLocale(const [Locale('pt', 'BR')]), const Locale('pt'));
  });
}
