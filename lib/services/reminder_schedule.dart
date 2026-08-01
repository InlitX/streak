class ReminderSchedule {
  const ReminderSchedule._();

  static const slotsPerReminder = 64;

  static int notificationId(String habitId, String reminderId, int slot) {
    final habit = habitId.hashCode.abs() % 10000;
    final reminder = reminderId.hashCode.abs() % 100;
    return (habit * 100 + reminder) * slotsPerReminder + slot;
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
