class FocusSession {
  const FocusSession({
    required this.id,
    required this.habitId,
    required this.targetMinutes,
    required this.seconds,
    required this.completed,
    required this.startedAt,
  });

  final String id;
  final String habitId;
  final int targetMinutes;
  final int seconds;
  final bool completed;
  final DateTime startedAt;

  int get minutes => seconds ~/ 60;

  Map<String, dynamic> toMap() => {
        'id': id,
        'habitId': habitId,
        'targetMinutes': targetMinutes,
        'seconds': seconds,
        'completed': completed,
        'startedAt': startedAt.toIso8601String(),
      };

  factory FocusSession.fromMap(Map<String, dynamic> map) => FocusSession(
        id: map['id'] as String,
        habitId: (map['habitId'] ?? '') as String,
        targetMinutes: ((map['targetMinutes'] ?? 0) as num).toInt(),
        seconds: ((map['seconds'] ?? 0) as num).toInt(),
        completed: (map['completed'] ?? false) as bool,
        startedAt: DateTime.tryParse((map['startedAt'] ?? '') as String) ??
            DateTime.now(),
      );
}

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
