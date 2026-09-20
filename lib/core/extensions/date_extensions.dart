class AppClock {
  const AppClock._();

  static int _cutoffHour = 0;
  static DateTime? _today;
  static int _todayUntil = 0;

  static int get cutoffHour => _cutoffHour;

  static set cutoffHour(int value) {
    if (_cutoffHour == value) return;
    _cutoffHour = value;
    _today = null;
  }

  static DateTime now() => _cutoffHour == 0
      ? DateTime.now()
      : DateTime.now().subtract(Duration(hours: _cutoffHour));

  static DateTime wallNow() => DateTime.now();

  static DateTime today() {
    final cached = _today;
    if (cached != null &&
        DateTime.now().millisecondsSinceEpoch < _todayUntil) {
      return cached;
    }
    final midnight = now().atMidnight;
    _today = midnight;
    _todayUntil = midnight.addDays(1).millisecondsSinceEpoch +
        _cutoffHour * Duration.millisecondsPerHour;
    return midnight;
  }

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
