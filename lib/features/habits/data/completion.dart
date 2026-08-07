class Completion {
  const Completion({
    required this.date,
    this.count = 1,
    this.hour,
    this.steps = const {},
  });

  final String date;
  final double count;

  final int? hour;

  final Set<String> steps;

  Completion copyWith({double? count, int? hour, Set<String>? steps}) =>
      Completion(
        date: date,
        count: count ?? this.count,
        hour: hour ?? this.hour,
        steps: steps ?? this.steps,
      );

  Map<String, dynamic> toMap() => {
        'date': date,
        'numberOfCompletions': count,
        if (hour != null) 'hour': hour,
        if (steps.isNotEmpty) 'steps': steps.toList(),
      };

  factory Completion.fromMap(Map<String, dynamic> map) => Completion(
        date: map['date'] as String,
        count: ((map['numberOfCompletions'] ?? map['count'] ?? 1) as num)
            .toDouble(),
        hour: map['hour'] as int?,
        steps: map['steps'] == null
            ? const {}
            : {...(map['steps'] as List).map((e) => e as String)},
      );
}
