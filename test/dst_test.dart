import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';

void main() {
  final autumn = DateTime(2025, 10, 26);
  final spring = DateTime(2026, 3, 29);

  bool shifts(DateTime day) =>
      day.timeZoneOffset != day.addDays(1).timeZoneOffset;

  test('a month grid never repeats or skips a day', () {
    for (final around in [autumn, spring]) {
      final start = around.addDays(-6);
      final days = List.generate(14, (i) => start.addDays(i));
      for (var i = 1; i < days.length; i++) {
        expect(
          days[i].epochDay - days[i - 1].epochDay,
          1,
          reason: 'salto raro en ${days[i - 1]} -> ${days[i]}',
        );
      }
    }
  });

  test('walking day by day lands on every day once', () {
    for (final around in [autumn, spring]) {
      var cursor = around.addDays(-3);
      final seen = <int>[];
      for (var i = 0; i < 7; i++) {
        seen.add(cursor.day);
        cursor = cursor.addDays(1);
      }
      expect(seen.toSet().length, 7, reason: 'dias repetidos: $seen');
    }
  });

  test('the week always starts on the same weekday', () {
    for (final around in [autumn, spring]) {
      for (var i = -7; i <= 7; i++) {
        final day = around.addDays(i);
        for (var weekStart = 1; weekStart <= 7; weekStart++) {
          expect(day.startOfWeek(weekStart).weekday, weekStart);
        }
      }
    }
  });

  test(
    'the clock really changes here, so the checks above mean something',
    () {
      expect(shifts(autumn) || shifts(spring), isTrue);
    },
    skip: shifts(autumn) || shifts(spring)
        ? null
        : 'esta maquina no cambia la hora, el test no prueba nada',
  );
}
