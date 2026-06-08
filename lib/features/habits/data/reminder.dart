class Reminder {
  const Reminder({
    required this.id,
    required this.hour,
    required this.minute,
    required this.days,
    this.message = '',
  });

  final String id;
  final int hour;
  final int minute;
  final List<int> days;

  /// Mensaje personalizado opcional. Si está vacío, se usa una frase
  /// motivacional aleatoria al disparar la notificación.
  final String message;

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
      };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
        id: map['id'] as String,
        hour: map['hour'] as int,
        minute: map['minute'] as int,
        days: List<int>.from((map['selectedDays'] ?? map['days']) as List),
        message: (map['message'] ?? '') as String,
      );
}
