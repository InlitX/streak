import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';

enum NoteType { note, planned, completed }

class HabitNote {
  const HabitNote({
    required this.id,
    required this.habitId,
    required this.date,
    required this.type,
    required this.text,
    this.minutes,
    this.photos = const [],
    required this.createdAt,
  });

  final String id;
  final String habitId;
  final String date;
  final NoteType type;
  final String text;
  final int? minutes;
  final List<String> photos;
  final DateTime createdAt;

  String get title => text.trim().split('\n').first;

  String get body {
    final lines = text.trim().split('\n');
    return lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
  }

  TimeOfDay? get time => minutes == null
      ? null
      : TimeOfDay(hour: minutes! ~/ 60, minute: minutes! % 60);

  HabitNote copyWith({
    NoteType? type,
    String? text,
    int? minutes,
    List<String>? photos,
    bool clearMinutes = false,
  }) =>
      HabitNote(
        id: id,
        habitId: habitId,
        date: date,
        type: type ?? this.type,
        text: text ?? this.text,
        minutes: clearMinutes ? null : (minutes ?? this.minutes),
        photos: photos ?? this.photos,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'habitId': habitId,
        'date': date,
        'type': type.index,
        'text': text,
        'minutes': minutes,
        'photos': photos,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HabitNote.fromMap(Map<String, dynamic> map) => HabitNote(
        id: map['id'] as String,
        habitId: (map['habitId'] ?? '') as String,
        date: (map['date'] ?? '') as String,
        type: NoteType.values[((map['type'] ?? 0) as num).toInt().clamp(0, 2)],
        text: (map['text'] ?? '') as String,
        minutes: (map['minutes'] as num?)?.toInt(),
        photos: (map['photos'] as List?)?.map((p) => p as String).toList() ??
            const [],
        createdAt:
            DateTime.tryParse((map['createdAt'] ?? '') as String) ??
                DateTime.now(),
      );
}

Color noteTypeColor(BuildContext context, NoteType type) => switch (type) {
      NoteType.note => context.tokens.info,
      NoteType.planned => context.tokens.warning,
      NoteType.completed => context.tokens.success,
    };
