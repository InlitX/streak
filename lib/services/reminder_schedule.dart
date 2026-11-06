class ReminderSchedule {
  const ReminderSchedule._();

  static const slotsPerReminder = 64;

  static const quietWeeks = 4;

  static const _quietIdBase = 100000000;

  static int quietId(int id, int week) =>
      week <= 1 ? id : id + _quietIdBase * (week - 1);

  static int notificationId(String habitId, String reminderId, int slot) {
    final habit = habitId.hashCode.abs() % 10000;
    final reminder = reminderId.hashCode.abs() % 100;
    return (habit * 100 + reminder) * slotsPerReminder + slot;
  }

  static const _dayMinutes = 24 * 60;

  static int hourlyCap(int days) => slotsPerReminder ~/ (days < 1 ? 1 : days);

  static List<int> hourlySlots({
    required int hour,
    required int minute,
    required int everyMinutes,
    int? until,
    int cap = 24,
  }) {
    final start = hour * 60 + minute;
    if (everyMinutes < 1) return [start];
    final end = until != null && until > start ? until : _dayMinutes - 1;
    final slots = <int>[];
    for (var at = start; at <= end && slots.length < cap; at += everyMinutes) {
      slots.add(at);
    }
    return slots;
  }

  static const todoIdBase = 1000000000;

  static int todoNotificationId(String todoId) =>
      todoIdBase + todoId.hashCode.abs() % 100000000;

  static DateTime? todoFireAt({
    required DateTime now,
    required bool done,
    DateTime? due,
    int? minutes,
  }) {
    if (done || due == null || minutes == null) return null;
    final at = DateTime(due.year, due.month, due.day).add(
      Duration(minutes: minutes),
    );
    return at.isAfter(now) ? at : null;
  }

  static DateTime nextWeekly({
    required DateTime now,
    required int weekday,
    required int hour,
    required int minute,
  }) {
    var when = DateTime(now.year, now.month, now.day, hour, minute);
    while (when.weekday != weekday) {
      when = when.add(const Duration(days: 1));
    }
    return when.isBefore(now) ? when.add(const Duration(days: 7)) : when;
  }

  static const habitDaysHorizon = 800;

  static List<DateTime> onHabitDays({
    required DateTime from,
    required bool Function(DateTime day) due,
    required List<int> slots,
    required int limit,
  }) {
    final moments = <DateTime>[];
    for (var offset = 0; offset < habitDaysHorizon; offset++) {
      final day = DateTime(from.year, from.month, from.day + offset);
      if (!due(day)) continue;
      for (final slot in slots) {
        final at = DateTime(day.year, day.month, day.day, slot ~/ 60, slot % 60);
        if (at.isBefore(from)) continue;
        moments.add(at);
        if (moments.length >= limit) return moments;
      }
    }
    return moments;
  }

  static DateTime nextDaily({
    required DateTime now,
    required int hour,
    required int minute,
  }) {
    final when = DateTime(now.year, now.month, now.day, hour, minute);
    return when.isBefore(now)
        ? DateTime(now.year, now.month, now.day + 1, hour, minute)
        : when;
  }
}
