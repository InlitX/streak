import 'package:intl/intl.dart';

class WeekdayLabels {
  const WeekdayLabels._();

  static List<String> narrowMonFirst(String locale) {
    final n = DateFormat('', _resolve(locale)).dateSymbols.NARROWWEEKDAYS;
    return [n[1], n[2], n[3], n[4], n[5], n[6], n[0]];
  }

  static List<String> shortMonFirst(String locale) {
    final s = DateFormat('', _resolve(locale)).dateSymbols.SHORTWEEKDAYS;
    return [s[1], s[2], s[3], s[4], s[5], s[6], s[0]];
  }

  static List<String> shortSunFirst(String locale) =>
      List<String>.from(DateFormat('', _resolve(locale)).dateSymbols.SHORTWEEKDAYS);

  static List<String> narrowFrom(String locale, int weekStart) {
    final n = DateFormat('', _resolve(locale)).dateSymbols.NARROWWEEKDAYS;
    return _rotate(n, weekStart);
  }

  static List<String> shortFrom(String locale, int weekStart) {
    final s = DateFormat('', _resolve(locale)).dateSymbols.SHORTWEEKDAYS;
    return _rotate(s, weekStart);
  }

  static List<String> _rotate(List<String> sunFirst, int weekStart) =>
      List.generate(7, (i) {
        final weekday = ((weekStart - 1 + i) % 7) + 1;
        return sunFirst[weekday % 7];
      });

  static String _resolve(String locale) =>
      locale.startsWith('es') ? 'es' : 'en';
}
