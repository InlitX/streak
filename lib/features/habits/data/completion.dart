import 'package:streak/core/extensions/date_extensions.dart';

class Completion {
  const Completion({
    required this.date,
    this.count = 1,
    this.hour,
    this.minute,
    this.marks = const [],
    this.steps = const {},
  });

  final String date;
  final double count;

  final int? hour;

  final int? minute;

  final List<int> marks;

  final Set<String> steps;

  Completion copyWith({
    double? count,
    int? hour,
    int? minute,
    List<int>? marks,
    Set<String>? steps,
  }) =>
      Completion(
        date: date,
        count: count ?? this.count,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        marks: marks ?? this.marks,
        steps: steps ?? this.steps,
      );

  List<int> get times {
    if (marks.isNotEmpty) return marks;
    if (hour == null) return const [];
    return [hour! * 60 + (minute ?? 0)];
  }

  List<int> plus(int minuteOfDay) => [...marks, minuteOfDay];

  DateTime? get day => date.length == 10 ? parseDayKey(date) : null;

  DateTime? get stamp {
    final at = day;
    if (hour == null || at == null) return null;
    return DateTime(at.year, at.month, at.day, hour!, minute ?? 0);
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'numberOfCompletions': count,
        if (hour != null) 'hour': hour,
        if (minute != null) 'minute': minute,
        if (marks.isNotEmpty) 'marks': marks,
        if (steps.isNotEmpty) 'steps': steps.toList(),
      };

  factory Completion.fromMap(Map<String, dynamic> map) => Completion(
        date: map['date'] as String,
        count: ((map['numberOfCompletions'] ?? map['count'] ?? 1) as num)
            .toDouble(),
        hour: map['hour'] as int?,
        minute: map['minute'] as int?,
        marks: map['marks'] == null
            ? const []
            : [...(map['marks'] as List).map((e) => (e as num).toInt())],
        steps: map['steps'] == null
            ? const {}
            : {...(map['steps'] as List).map((e) => e as String)},
      );
}
