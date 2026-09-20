import 'package:streak/core/extensions/date_extensions.dart';

class FocusSession {
  const FocusSession({
    required this.id,
    required this.habitId,
    required this.targetMinutes,
    required this.seconds,
    required this.completed,
    required this.startedAt,
    this.counted = false,
  });

  final String id;
  final String habitId;
  final int targetMinutes;
  final int seconds;
  final bool completed;
  final DateTime startedAt;
  final bool counted;

  int get minutes => seconds ~/ 60;

  DateTime get countedOn => startedAt
      .add(Duration(seconds: seconds > 0 ? seconds - 1 : 0))
      .subtract(Duration(hours: AppClock.cutoffHour));

  List<FocusSession> split() {
    final pieces = <FocusSession>[];
    var start = startedAt;
    var left = seconds;
    while (left > 0) {
      final span = dayBorderAfter(start).difference(start).inSeconds;
      if (span >= left) {
        pieces.add(_pieceOf(pieces.length + 1, start, left, last: true));
        break;
      }
      pieces.add(_pieceOf(pieces.length + 1, start, span));
      start = start.add(Duration(seconds: span));
      left -= span;
    }
    if (pieces.length < 2 || pieces.any((piece) => piece.seconds < 60)) {
      return [this];
    }
    return pieces;
  }

  FocusSession _pieceOf(int index, DateTime start, int span,
          {bool last = false}) =>
      FocusSession(
        id: index == 1 ? id : '$id-$index',
        habitId: habitId,
        targetMinutes: targetMinutes,
        seconds: span,
        completed: completed && last,
        startedAt: start,
        counted: counted,
      );

  FocusSession get asCounted => FocusSession(
        id: id,
        habitId: habitId,
        targetMinutes: targetMinutes,
        seconds: seconds,
        completed: completed,
        startedAt: startedAt,
        counted: true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'habitId': habitId,
        'targetMinutes': targetMinutes,
        'seconds': seconds,
        'completed': completed,
        'startedAt': startedAt.toIso8601String(),
        if (counted) 'counted': true,
      };

  factory FocusSession.fromMap(Map<String, dynamic> map) => FocusSession(
        id: map['id'] as String,
        habitId: (map['habitId'] ?? '') as String,
        targetMinutes: ((map['targetMinutes'] ?? 0) as num).toInt(),
        seconds: ((map['seconds'] ?? 0) as num).toInt(),
        completed: (map['completed'] ?? false) as bool,
        startedAt: DateTime.tryParse((map['startedAt'] ?? '') as String) ??
            DateTime.now(),
        counted: map['counted'] == true,
      );
}

DateTime dayBorderAfter(DateTime moment) => moment
    .subtract(Duration(hours: AppClock.cutoffHour))
    .atMidnight
    .addDays(1)
    .add(Duration(hours: AppClock.cutoffHour));

String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
}

String formatHoursShort(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h == 0 && m == 0) return '${seconds}s';
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}
