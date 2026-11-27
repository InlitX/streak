import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:streak/features/todos/data/smart_title.dart';
import 'package:streak/features/todos/data/todo_repeat.dart';
import 'package:streak/l10n/app_localizations.dart';

void main() {
  late SmartWords en;
  late SmartWords es;
  final now = DateTime(2026, 11, 19, 10, 30);

  setUpAll(() async {
    await initializeDateFormatting();
    en = SmartWords.of(lookupAppLocalizations(const Locale('en')), 'en');
    es = SmartWords.of(lookupAppLocalizations(const Locale('es')), 'es');
  });

  SmartTitle? parse(String text, [SmartWords? words]) =>
      parseSmartTitle(text, now, words ?? en);

  test('plain titles are left alone', () {
    expect(parse('Read 1984'), isNull);
    expect(parse('Buy milk'), isNull);
    expect(parse('tomorrow'), isNull);
    expect(parse('Walk in the sun'), isNull);
    expect(parse('Pasear por el mar', es), isNull);
  });

  test('tomorrow with a time', () {
    final smart = parse('Call mom tmr 6pm')!;
    expect(smart.title, 'Call mom');
    expect(smart.date, DateTime(2026, 11, 20));
    expect(smart.minutes, 18 * 60);
    expect(smart.repeat, isNull);
  });

  test('a past time today moves to tomorrow', () {
    final smart = parse('Stretch at 9:15')!;
    expect(smart.title, 'Stretch');
    expect(smart.date, DateTime(2026, 11, 20));
    expect(smart.minutes, 9 * 60 + 15);
    expect(parse('Stretch at 21:00')!.date, DateTime(2026, 11, 19));
  });

  test('weekday and repeats', () {
    final monday = parse('Gym on monday')!;
    expect(monday.title, 'Gym');
    expect(monday.date, DateTime(2026, 11, 23));
    final weekly = parse('Water plants rpt weekly')!;
    expect(weekly.title, 'Water plants');
    expect(weekly.repeat!.unit, RepeatUnit.weeks);
    expect(weekly.date, DateTime(2026, 11, 19));
    final every = parse('Review notes every 3 days')!;
    expect(every.repeat!.unit, RepeatUnit.days);
    expect(every.repeat!.every, 3);
    final fri = parse('Report every friday 17:00')!;
    expect(fri.title, 'Report');
    expect(fri.repeat!.weekdays, [5]);
    expect(fri.date, DateTime(2026, 11, 20));
    expect(fri.minutes, 17 * 60);
  });

  test('dates by number and month name', () {
    expect(parse('Dentist 11/25', en)!.date, DateTime(2026, 11, 25));
    expect(parse('Dentist 25/11', es)!.date, DateTime(2026, 11, 25));
    expect(parse('Pay rent 3 jan')!.date, DateTime(2027, 1, 3));
    expect(parse('Trip dec 24')!.title, 'Trip');
    expect(parse('Trip 31/02', es), isNull);
  });

  test('spanish words and accents', () {
    final smart = parse('Llamar a mamá mañana a las 18:30', es)!;
    expect(smart.title, 'Llamar a mamá');
    expect(smart.date, DateTime(2026, 11, 20));
    expect(smart.minutes, 18 * 60 + 30);
    final lunes = parse('Correr todos los lunes', es)!;
    expect(lunes.title, 'Correr');
    expect(lunes.repeat!.weekdays, [1]);
    final miercoles = parse('Clase el miercoles', es)!;
    expect(miercoles.title, 'Clase');
    expect(miercoles.date, DateTime(2026, 11, 25));
    expect(parse('Leer 5 de diciembre', es)!.date, DateTime(2026, 12, 5));
    expect(parse('Call tmr', es)!.date, DateTime(2026, 11, 20));
  });
}
