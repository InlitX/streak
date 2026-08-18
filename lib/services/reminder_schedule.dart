class ReminderSchedule {
  const ReminderSchedule._();

  static const slotsPerReminder = 64;

  static int notificationId(String habitId, String reminderId, int slot) {
    final habit = habitId.hashCode.abs() % 10000;
    final reminder = reminderId.hashCode.abs() % 100;
    return (habit * 100 + reminder) * slotsPerReminder + slot;
  }

  static const maxHourlyPerDay = 8;

  static List<int> hourlySlots({
    required int hour,
    required int minute,
    required int everyHours,
  }) {
    if (everyHours < 1) return [hour * 60 + minute];
    final start = hour * 60 + minute;
    final step = everyHours * 60;
    final slots = <int>[];
    for (var at = start; at < 24 * 60 && slots.length < maxHourlyPerDay; at += step) {
      slots.add(at);
    }
    return slots;
  }

  static int hourlyId(String habitId, String reminderId, int day, int slot) =>
      notificationId(habitId, reminderId, (day - 1) * maxHourlyPerDay + slot);

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
}
