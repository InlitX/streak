class Reminder {
  const Reminder({
    required this.id,
    required this.hour,
    required this.minute,
    required this.days,
    this.message = '',
    this.everyDays = 1,
    this.anchorEpochDay,
  });

  final String id;
  final int hour;
  final int minute;
  final List<int> days;

  final String message;

  // 1 = use the weekday set; >= 2 = every N days from anchorEpochDay.
  final int everyDays;

  final int? anchorEpochDay;

  bool get isInterval => everyDays >= 2;

  String get timeLabel {
    final period = hour >= 12 ? 'PM' : 'AM';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$display:${minute.toString().padLeft(2, '0')} $period';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'selectedDays': days,
        'message': message,
        'everyDays': everyDays,
        'anchorEpochDay': anchorEpochDay,
      };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
        id: map['id'] as String,
        hour: map['hour'] as int,
        minute: map['minute'] as int,
        days: List<int>.from((map['selectedDays'] ?? map['days']) as List),
        message: (map['message'] ?? '') as String,
        everyDays: (map['everyDays'] ?? 1) as int,
        anchorEpochDay: map['anchorEpochDay'] as int?,
      );
}
