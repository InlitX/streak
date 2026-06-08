import 'package:intl/intl.dart';

/// Locale-aware weekday labels from intl's date symbols (Sunday-first arrays).
class WeekdayLabels {
  const WeekdayLabels._();

  /// Narrow initials, Monday first (en: M T W T F S S).
  static List<String> narrowMonFirst(String locale) {
    final n = DateFormat('', _resolve(locale)).dateSymbols.NARROWWEEKDAYS;
    return [n[1], n[2], n[3], n[4], n[5], n[6], n[0]];
  }

  /// Short names, Monday first (en: Mon Tue … Sun).
  static List<String> shortMonFirst(String locale) {
    final s = DateFormat('', _resolve(locale)).dateSymbols.SHORTWEEKDAYS;
    return [s[1], s[2], s[3], s[4], s[5], s[6], s[0]];
  }

  /// Short names, Sunday first (index 0 = Sun).
  static List<String> shortSunFirst(String locale) =>
      List<String>.from(DateFormat('', _resolve(locale)).dateSymbols.SHORTWEEKDAYS);

  static String _resolve(String locale) =>
      locale.startsWith('es') ? 'es' : 'en';
}
