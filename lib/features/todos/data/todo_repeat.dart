import 'dart:math' as math;

import 'package:streak/core/extensions/date_extensions.dart';

enum RepeatUnit { days, weeks, months, years }

class TodoRepeat {
  const TodoRepeat({
    required this.unit,
    this.every = 1,
    this.weekdays = const [],
    this.byWeekday = false,
    this.day = 0,
    this.fromDone = false,
  });

  final RepeatUnit unit;
  final int every;
  final List<int> weekdays;
  final bool byWeekday;
  final int day;
  final bool fromDone;

  static const workdays = [1, 2, 3, 4, 5];

  bool get isWorkdays =>
      unit == RepeatUnit.weeks &&
      every == 1 &&
      weekdays.length == workdays.length &&
      workdays.every(weekdays.contains);

  TodoRepeat copyWith({
    RepeatUnit? unit,
    int? every,
    List<int>? weekdays,
    bool? byWeekday,
    int? day,
    bool? fromDone,
  }) =>
      TodoRepeat(
        unit: unit ?? this.unit,
        every: every ?? this.every,
        weekdays: weekdays ?? this.weekdays,
        byWeekday: byWeekday ?? this.byWeekday,
        day: day ?? this.day,
        fromDone: fromDone ?? this.fromDone,
      );

  TodoRepeat anchoredTo(DateTime due) => copyWith(
        day: switch (unit) {
          RepeatUnit.months when byWeekday => weekOfMonth(due),
          RepeatUnit.months || RepeatUnit.years => due.day,
          _ => 0,
        },
      );

  DateTime after(DateTime due, {required DateTime today, bool skipping = false}) {
    final from = fromDone && !skipping ? today : due.atMidnight;
    var next = _step(from, due);
    var guard = 0;
    while (!next.isAfter(today) && guard++ < 5000) {
      next = _step(next, due);
    }
    return next;
  }

  DateTime _step(DateTime from, DateTime anchor) {
    final span = math.max(1, every);
    switch (unit) {
      case RepeatUnit.days:
        return from.addDays(span);
      case RepeatUnit.weeks:
        if (weekdays.isEmpty) return from.addDays(7 * span);
        final days = [...weekdays]..sort();
        for (final day in days) {
          if (day > from.weekday) return from.addDays(day - from.weekday);
        }
        final monday = from.addDays(1 - from.weekday);
        return monday.addDays(7 * span + days.first - 1);
      case RepeatUnit.months:
        final month = DateTime(from.year, from.month + span);
        if (byWeekday) {
          return _nthWeekday(
            month,
            anchor.weekday,
            day > 0 ? day : weekOfMonth(anchor),
          );
        }
        return _clampDay(month.year, month.month, day > 0 ? day : anchor.day);
      case RepeatUnit.years:
        return _clampDay(
          from.year + span,
          anchor.month,
          day > 0 ? day : anchor.day,
        );
    }
  }

  static DateTime _clampDay(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, math.min(day, last));
  }

  static int weekOfMonth(DateTime date) => (date.day - 1) ~/ 7 + 1;

  static DateTime _nthWeekday(DateTime month, int weekday, int nth) {
    final first = DateTime(month.year, month.month);
    final offset = (weekday - first.weekday + 7) % 7;
    final day = first.addDays(offset + 7 * (math.min(nth, 5) - 1));
    if (nth < 5 && day.month == first.month) return day;
    var last = DateTime(month.year, month.month + 1, 0);
    while (last.weekday != weekday) {
      last = last.addDays(-1);
    }
    return last;
  }

  Map<String, dynamic> toMap() => {
        'unit': unit.index,
        'every': every,
        if (weekdays.isNotEmpty) 'weekdays': weekdays,
        if (byWeekday) 'byWeekday': true,
        if (day > 0) 'day': day,
        if (fromDone) 'fromDone': true,
      };

  factory TodoRepeat.fromMap(Map<String, dynamic> map) => TodoRepeat(
        unit: RepeatUnit.values[((map['unit'] ?? 0) as num)
            .toInt()
            .clamp(0, RepeatUnit.values.length - 1)],
        every: math.max(1, ((map['every'] ?? 1) as num).toInt()),
        weekdays: (map['weekdays'] as List?)
                ?.map((d) => (d as num).toInt())
                .where((d) => d >= 1 && d <= 7)
                .toList() ??
            const [],
        byWeekday: map['byWeekday'] == true,
        day: ((map['day'] ?? 0) as num).toInt().clamp(0, 31),
        fromDone: map['fromDone'] == true,
      );

  @override
  bool operator ==(Object other) =>
      other is TodoRepeat &&
      other.unit == unit &&
      other.every == every &&
      other.byWeekday == byWeekday &&
      other.day == day &&
      other.fromDone == fromDone &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.every(weekdays.contains);

  @override
  int get hashCode => Object.hash(
        unit,
        every,
        byWeekday,
        day,
        fromDone,
        Object.hashAllUnordered(weekdays),
      );
}
