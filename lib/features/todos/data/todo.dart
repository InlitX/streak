import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';

enum TodoPriority { none, low, medium, high }

class Todo {
  const Todo({
    required this.id,
    required this.text,
    required this.createdAt,
    this.done = false,
    this.date = '',
    this.priority = TodoPriority.none,
    this.photos = const [],
    this.doneAt,
  });

  final String id;
  final String text;
  final bool done;
  final String date;
  final TodoPriority priority;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime? doneAt;

  String get title => text.trim().split('\n').first;

  String get body {
    final lines = text.trim().split('\n');
    return lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
  }

  DateTime? get due => date.isEmpty ? null : parseDayKey(date);

  Todo copyWith({
    String? text,
    bool? done,
    String? date,
    TodoPriority? priority,
    List<String>? photos,
    DateTime? doneAt,
    bool clearDoneAt = false,
  }) =>
      Todo(
        id: id,
        text: text ?? this.text,
        done: done ?? this.done,
        date: date ?? this.date,
        priority: priority ?? this.priority,
        photos: photos ?? this.photos,
        createdAt: createdAt,
        doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'done': done,
        'date': date,
        'priority': priority.index,
        'photos': photos,
        'createdAt': createdAt.toIso8601String(),
        'doneAt': doneAt?.toIso8601String(),
      };

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
        id: map['id'] as String,
        text: (map['text'] ?? '') as String,
        done: (map['done'] ?? false) as bool,
        date: (map['date'] ?? '') as String,
        priority: TodoPriority.values[((map['priority'] ?? 0) as num)
            .toInt()
            .clamp(0, TodoPriority.values.length - 1)],
        photos:
            (map['photos'] as List?)?.map((p) => p as String).toList() ?? const [],
        createdAt: DateTime.tryParse((map['createdAt'] ?? '') as String) ??
            DateTime.now(),
        doneAt: DateTime.tryParse((map['doneAt'] ?? '') as String),
      );
}

Color todoPriorityColor(BuildContext context, TodoPriority priority) =>
    switch (priority) {
      TodoPriority.none => context.tokens.muted,
      TodoPriority.low => context.tokens.info,
      TodoPriority.medium => context.tokens.warning,
      TodoPriority.high => context.tokens.danger,
    };
