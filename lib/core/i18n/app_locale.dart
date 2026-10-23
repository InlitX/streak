import 'dart:ui';

import 'package:streak/l10n/app_localizations.dart';

const shippedLanguages = {
  'ca', 'de', 'en', 'es', 'fr', 'ko', 'pt', 'ro', 'ru', 'tr', 'uk', 'zh',
};

List<Locale> get shippedLocales => AppLocalizations.supportedLocales
    .where((l) => shippedLanguages.contains(l.languageCode))
    .toList();

Locale pickLocale(Iterable<Locale>? wanted) {
  for (final locale in wanted ?? const <Locale>[]) {
    if (shippedLanguages.contains(locale.languageCode)) {
      return Locale(locale.languageCode);
    }
  }
  return const Locale('en');
}
