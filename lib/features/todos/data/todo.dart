import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/todos/data/todo_repeat.dart';

enum TodoPriority { none, low, medium, high }

class Todo {
  const Todo({
    required this.id,
    required this.text,
    required this.createdAt,
    this.done = false,
    this.date = '',
    this.minutes,
    this.estimate,
    this.priority = TodoPriority.none,
    this.photos = const [],
    this.tags = const [],
    this.project = '',
    this.steps = const [],
    this.paper = -1,
    this.cover = '',
    this.pinned = false,
    this.repeat,
    this.doneAt,
  });

  final String id;
  final String text;
  final bool done;
  final String date;
  final int? minutes;
  final int? estimate;
  final TodoPriority priority;
  final List<String> photos;
  final List<String> tags;
  final String project;
  final List<TodoStep> steps;
  final int paper;
  final String cover;
  final bool pinned;
  final TodoRepeat? repeat;
  final DateTime createdAt;
  final DateTime? doneAt;

  static final _derived = Expando<_Derived>();

  _Derived get _parts => _derived[this] ??= _Derived.of(this);

  String get title => _parts.title;

  String get body => _parts.body;

  String get searchText => _parts.lower;

  DateTime? get due => _parts.due;

  TimeOfDay? get time => minutes == null
      ? null
      : TimeOfDay(hour: minutes! ~/ 60, minute: minutes! % 60);

  DateTime? get dueAt {
    final day = due;
    if (day == null || minutes == null) return day;
    return day.add(Duration(minutes: minutes!));
  }

  bool get repeats => repeat != null && due != null;

  Todo nextTime(DateTime today, {bool skipping = false}) => copyWith(
        date: repeat!.after(due!, today: today, skipping: skipping).dayKey,
        steps: [for (final step in steps) step.copyWith(done: false)],
      );

  Todo doneRecord(String id, DateTime at) => Todo(
        id: id,
        text: text,
        done: true,
        date: date,
        minutes: minutes,
        estimate: estimate,
        priority: priority,
        tags: tags,
        project: project,
        steps: steps,
        paper: paper,
        createdAt: createdAt,
        doneAt: at,
      );

  Todo copyWith({
    String? text,
    bool? done,
    String? date,
    int? minutes,
    int? estimate,
    TodoPriority? priority,
    List<String>? photos,
    List<String>? tags,
    String? project,
    List<TodoStep>? steps,
    int? paper,
    String? cover,
    bool? pinned,
    TodoRepeat? repeat,
    DateTime? doneAt,
    bool clearRepeat = false,
    bool clearDoneAt = false,
    bool clearMinutes = false,
    bool clearEstimate = false,
  }) =>
      Todo(
        id: id,
        text: text ?? this.text,
        done: done ?? this.done,
        date: date ?? this.date,
        minutes: clearMinutes ? null : (minutes ?? this.minutes),
        estimate: clearEstimate ? null : (estimate ?? this.estimate),
        priority: priority ?? this.priority,
        photos: photos ?? this.photos,
        tags: tags ?? this.tags,
        project: project ?? this.project,
        steps: steps ?? this.steps,
        paper: paper ?? this.paper,
        cover: cover ?? this.cover,
        pinned: pinned ?? this.pinned,
        repeat: clearRepeat ? null : (repeat ?? this.repeat),
        createdAt: createdAt,
        doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'done': done,
        'date': date,
        'minutes': minutes,
        'estimate': estimate,
        'priority': priority.index,
        'photos': photos,
        'tags': tags,
        'project': project,
        'steps': [for (final step in steps) step.toMap()],
        'paper': paper,
        'cover': cover,
        'pinned': pinned,
        if (repeat != null) 'repeat': repeat!.toMap(),
        'createdAt': createdAt.toIso8601String(),
        'doneAt': doneAt?.toIso8601String(),
      };

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
        id: map['id'] as String,
        text: (map['text'] ?? '') as String,
        done: (map['done'] ?? false) as bool,
        date: (map['date'] ?? '') as String,
        minutes: (map['minutes'] as num?)?.toInt(),
        estimate: (map['estimate'] as num?)?.toInt(),
        priority: TodoPriority.values[((map['priority'] ?? 0) as num)
            .toInt()
            .clamp(0, TodoPriority.values.length - 1)],
        photos:
            (map['photos'] as List?)?.map((p) => p as String).toList() ?? const [],
        tags:
            (map['tags'] as List?)?.map((t) => t as String).toList() ?? const [],
        project: (map['project'] ?? '') as String,
        steps: (map['steps'] as List?)
                ?.map((s) => TodoStep.fromMap(Map<String, dynamic>.from(s as Map)))
                .toList() ??
            const [],
        paper: ((map['paper'] ?? -1) as num).toInt(),
        cover: (map['cover'] ?? '') as String,
        pinned: (map['pinned'] ?? false) as bool,
        repeat: map['repeat'] is Map
            ? TodoRepeat.fromMap(Map<String, dynamic>.from(map['repeat'] as Map))
            : null,
        createdAt: DateTime.tryParse((map['createdAt'] ?? '') as String) ??
            DateTime.now(),
        doneAt: DateTime.tryParse((map['doneAt'] ?? '') as String),
      );
}

class TodoStep {
  const TodoStep({required this.id, required this.text, this.done = false});

  final String id;
  final String text;
  final bool done;

  TodoStep copyWith({bool? done}) =>
      TodoStep(id: id, text: text, done: done ?? this.done);

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'done': done};

  factory TodoStep.fromMap(Map<String, dynamic> map) => TodoStep(
        id: map['id'] as String,
        text: (map['text'] ?? '') as String,
        done: (map['done'] ?? false) as bool,
      );
}

Color todoPriorityColor(BuildContext context, TodoPriority priority) =>
    switch (priority) {
      TodoPriority.none => context.tokens.muted,
      TodoPriority.low => context.tokens.info,
      TodoPriority.medium => context.tokens.warning,
      TodoPriority.high => context.tokens.danger,
    };

class _Derived {
  const _Derived(this.title, this.body, this.lower, this.due);

  factory _Derived.of(Todo todo) {
    final lines = todo.text.trim().split('\n');
    return _Derived(
      lines.first,
      lines.length > 1 ? lines.sublist(1).join('\n').trim() : '',
      todo.text.toLowerCase(),
      todo.date.isEmpty ? null : parseDayKey(todo.date),
    );
  }

  final String title;
  final String body;
  final String lower;
  final DateTime? due;
}
