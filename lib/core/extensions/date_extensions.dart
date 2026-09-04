class AppClock {
  const AppClock._();

  static int cutoffHour = 0;

  static DateTime now() => cutoffHour == 0
      ? DateTime.now()
      : DateTime.now().subtract(Duration(hours: cutoffHour));

  static DateTime wallNow() => DateTime.now();

  static DateTime today() => now().atMidnight;

  static bool isLogicalToday(DateTime date) => date.isSameDay(now());
}

extension DateOnly on DateTime {
  String get dayKey => '${_pad(day)}-${_pad(month)}-$year';

  DateTime get atMidnight => DateTime(year, month, day);

  int get epochDay =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  DateTime addDays(int count) => DateTime(year, month, day + count);

  DateTime startOfWeek(int weekStart) {
    final diff = (weekday - weekStart + 7) % 7;
    return addDays(-diff);
  }
}

DateTime parseDayKey(String value) => DateTime(
  int.parse(value.substring(6)),
  int.parse(value.substring(3, 5)),
  int.parse(value.substring(0, 2)),
);

String _pad(int value) => value < 10 ? '0$value' : '$value';
