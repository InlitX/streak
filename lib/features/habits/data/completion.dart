class Completion {
  const Completion({required this.date, this.count = 1, this.hour});

  final String date;
  final int count;

  /// Hora del día (0-23) en que se registró, para la gráfica de "hora
  /// habitual". Null en datos antiguos o importados sin esta info.
  final int? hour;

  Completion copyWith({int? count, int? hour}) =>
      Completion(date: date, count: count ?? this.count, hour: hour ?? this.hour);

  Map<String, dynamic> toMap() => {
        'date': date,
        'numberOfCompletions': count,
        if (hour != null) 'hour': hour,
      };

  factory Completion.fromMap(Map<String, dynamic> map) => Completion(
        date: map['date'] as String,
        count: (map['numberOfCompletions'] ?? map['count'] ?? 1) as int,
        hour: map['hour'] as int?,
      );
}
