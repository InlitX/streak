import 'package:intl/intl.dart';

final _keyFormat = DateFormat('dd-MM-yyyy');

extension DateOnly on DateTime {
  String get dayKey => _keyFormat.format(this);

  DateTime get atMidnight => DateTime(year, month, day);

  // UTC-anchored so it stays DST-safe.
  int get epochDay =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  DateTime startOfWeek(int weekStart) {
    final diff = (weekday - weekStart + 7) % 7;
    return atMidnight.subtract(Duration(days: diff));
  }
}

DateTime parseDayKey(String value) => _keyFormat.parse(value);
