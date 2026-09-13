import 'package:streak/core/extensions/date_extensions.dart';

class VacationPeriod {
  VacationPeriod({required DateTime start, DateTime? end, this.bulk = false})
      : start = start.atMidnight,
        end = end?.atMidnight;

  final DateTime start;
  final DateTime? end;
  final bool bulk;

  bool get isOngoing => end == null;

  bool contains(DateTime date) {
    final day = date.atMidnight;
    if (day.isBefore(start)) return false;
    final upper = end ?? AppClock.now().atMidnight;
    return !day.isAfter(upper);
  }

  VacationPeriod copyWith({DateTime? end}) =>
      VacationPeriod(start: start, end: end ?? this.end, bulk: bulk);

  Map<String, dynamic> toMap() => {
        'start': start.toIso8601String(),
        if (end != null) 'end': end!.toIso8601String(),
        if (bulk) 'bulk': true,
      };

  factory VacationPeriod.fromMap(Map<String, dynamic> map) => VacationPeriod(
        start: DateTime.parse(map['start'] as String),
        end: map['end'] != null ? DateTime.tryParse(map['end'] as String) : null,
        bulk: map['bulk'] == true,
      );
}
