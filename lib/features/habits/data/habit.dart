import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/reminder.dart';

enum HabitInterval { daily, weekly, monthly }

extension HabitIntervalLabel on HabitInterval {
  String get label => switch (this) {
        HabitInterval.daily => 'Daily',
        HabitInterval.weekly => 'Weekly',
        HabitInterval.monthly => 'Monthly',
      };

  String get unit => switch (this) {
        HabitInterval.daily => 'day',
        HabitInterval.weekly => 'week',
        HabitInterval.monthly => 'month',
      };
}

// negative = relapse-logged (clean by default); quantitative = amount-based.
enum HabitKind { positive, negative, quantitative }

enum QuantKind { generic, water, reading }

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.color,
    required this.order,
    this.icon = 'target',
    this.category = '',
    this.description = '',
    this.perDayTarget = 1,
    this.completions = const {},
    this.interval = HabitInterval.daily,
    this.targetFrequency = 1,
    this.reminders = const [],
    this.coverPath = '',
    this.kind = HabitKind.positive,
    this.unitLabel = '',
    this.incrementAmount = 1,
    this.quantKind = QuantKind.generic,
    this.bookCoverPath = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String icon;
  final String category;
  final String description;
  final Color color;
  final int order;

  // Daily goal: check count, or target amount for quantitative habits.
  final int perDayTarget;
  final Map<String, Completion> completions;
  final HabitInterval interval;
  final int targetFrequency;
  final List<Reminder> reminders;

  final String coverPath;
  final DateTime createdAt;

  final HabitKind kind;
  final String unitLabel;
  final int incrementAmount;
  final QuantKind quantKind;

  // Book cover for the reading visual; separate from [coverPath].
  final String bookCoverPath;

  // Bounded to [createdAt, today]; unbounded "clean by default" freezes the walk.
  bool isCompletedOn(DateTime date) {
    final day = date.atMidnight;
    if (day.isBefore(createdAt.atMidnight) || day.isAfter(DateTime.now().atMidnight)) {
      return false;
    }
    final entry = completions[date.dayKey];
    if (kind == HabitKind.negative) return entry == null;
    if (entry == null) return false;
    return entry.count >= perDayTarget;
  }

  int get totalCompletions =>
      completions.values.where((c) => c.count >= perDayTarget).length;

  bool get isDoneForNow {
    // Negatives are clean by default; sinking them would hide them.
    if (kind == HabitKind.negative) return false;
    final now = DateTime.now();
    switch (interval) {
      case HabitInterval.daily:
        return isCompletedOn(now);
      case HabitInterval.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return _countInRange(start, start.add(const Duration(days: 6))) >=
            targetFrequency;
      case HabitInterval.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return _countInRange(start, end) >= targetFrequency;
    }
  }

  // Day's contribution to [strength], 0..1. Fractional for quantitative.
  double _dayValue(DateTime date) {
    final day = date.atMidnight;
    if (day.isBefore(createdAt.atMidnight) ||
        day.isAfter(DateTime.now().atMidnight)) {
      return 0;
    }
    if (kind == HabitKind.negative) {
      return completions.containsKey(date.dayKey) ? 0.0 : 1.0;
    }
    final count = completions[date.dayKey]?.count ?? 0;
    if (perDayTarget <= 0) return count > 0 ? 1 : 0;
    return (count / perDayTarget).clamp(0.0, 1.0);
  }

  // EWMA of recent _dayValues; for negatives an empty map means "never relapsed".
  double get strength {
    if (completions.isEmpty && kind != HabitKind.negative) return 0;
    final now = DateTime.now().atMidnight;
    const halfLife = 12.0; // days
    const window = 90;
    var score = 0.0;
    var norm = 0.0;
    for (var i = 0; i < window; i++) {
      final weight = math.pow(0.5, i / halfLife).toDouble();
      norm += weight;
      score += weight * _dayValue(now.subtract(Duration(days: i)));
    }
    return norm == 0 ? 0 : (score / norm).clamp(0.0, 1.0);
  }

  int _countInRange(DateTime start, DateTime end) {
    var count = 0;
    for (var i = 0; i <= end.difference(start).inDays; i++) {
      if (isCompletedOn(start.add(Duration(days: i)))) count++;
    }
    return count;
  }

  int get currentStreak {
    // Negatives: walk back counting clean days (isCompletedOn bounds the walk).
    if (kind == HabitKind.negative) {
      var cursor = DateTime.now();
      var streak = 0;
      while (isCompletedOn(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return streak;
    }

    if (completions.isEmpty) return 0;
    final now = DateTime.now();

    switch (interval) {
      case HabitInterval.daily:
        var cursor = now;
        if (!isCompletedOn(cursor)) {
          cursor = cursor.subtract(const Duration(days: 1));
          if (!isCompletedOn(cursor)) return 0;
        }
        var streak = 0;
        while (isCompletedOn(cursor)) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        }
        return streak;

      case HabitInterval.weekly:
        var weekStart = now.subtract(Duration(days: now.weekday - 1));
        var streak = 0;
        if (_countInRange(weekStart, weekStart.add(const Duration(days: 6))) >=
            targetFrequency) {
          streak++;
        }
        weekStart = weekStart.subtract(const Duration(days: 7));
        while (_countInRange(
                weekStart, weekStart.add(const Duration(days: 6))) >=
            targetFrequency) {
          streak++;
          weekStart = weekStart.subtract(const Duration(days: 7));
        }
        return streak;

      case HabitInterval.monthly:
        var monthStart = DateTime(now.year, now.month, 1);
        var monthEnd =
            DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
        var streak = 0;
        if (_countInRange(monthStart, monthEnd) >= targetFrequency) streak++;
        monthStart = DateTime(monthStart.year, monthStart.month - 1, 1);
        while (true) {
          final end = DateTime(monthStart.year, monthStart.month + 1, 1)
              .subtract(const Duration(days: 1));
          if (_countInRange(monthStart, end) < targetFrequency) break;
          streak++;
          monthStart = DateTime(monthStart.year, monthStart.month - 1, 1);
        }
        return streak;
    }
  }

  int get longestStreak {
    // Negatives: longest run of clean days from creation to today.
    if (kind == HabitKind.negative) {
      var cursor = createdAt.atMidnight;
      final end = DateTime.now().atMidnight;
      var best = 0;
      var run = 0;
      while (!cursor.isAfter(end)) {
        if (isCompletedOn(cursor)) {
          run++;
          if (run > best) best = run;
        } else {
          run = 0;
        }
        cursor = cursor.add(const Duration(days: 1));
      }
      return best;
    }

    if (completions.isEmpty) return 0;
    final dates = completions.keys.map(parseDayKey).toList()
      ..sort((a, b) => a.compareTo(b));

    switch (interval) {
      case HabitInterval.daily:
        var best = 0;
        var run = 0;
        DateTime? last;
        for (final date in dates) {
          if (last != null && date.difference(last).inDays == 1) {
            run++;
          } else {
            run = 1;
          }
          last = date;
          if (run > best) best = run;
        }
        return best;

      case HabitInterval.weekly:
        var start = dates.first.subtract(Duration(days: dates.first.weekday - 1));
        final end =
            dates.last.add(Duration(days: 7 - dates.last.weekday));
        var best = 0;
        var run = 0;
        while (!start.isAfter(end)) {
          if (_countInRange(start, start.add(const Duration(days: 6))) >=
              targetFrequency) {
            run++;
          } else {
            run = 0;
          }
          if (run > best) best = run;
          start = start.add(const Duration(days: 7));
        }
        return best;

      case HabitInterval.monthly:
        var start = DateTime(dates.first.year, dates.first.month, 1);
        final end = DateTime(dates.last.year, dates.last.month + 1, 1)
            .subtract(const Duration(days: 1));
        var best = 0;
        var run = 0;
        while (!start.isAfter(end)) {
          final mEnd = DateTime(start.year, start.month + 1, 1)
              .subtract(const Duration(days: 1));
          if (_countInRange(start, mEnd) >= targetFrequency) {
            run++;
          } else {
            run = 0;
          }
          if (run > best) best = run;
          start = DateTime(start.year, start.month + 1, 1);
        }
        return best;
    }
  }

  Habit copyWith({
    String? name,
    String? icon,
    String? category,
    String? description,
    Color? color,
    int? order,
    int? perDayTarget,
    Map<String, Completion>? completions,
    HabitInterval? interval,
    int? targetFrequency,
    List<Reminder>? reminders,
    String? coverPath,
    HabitKind? kind,
    String? unitLabel,
    int? incrementAmount,
    QuantKind? quantKind,
    String? bookCoverPath,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      description: description ?? this.description,
      color: color ?? this.color,
      order: order ?? this.order,
      perDayTarget: perDayTarget ?? this.perDayTarget,
      completions: completions ?? this.completions,
      interval: interval ?? this.interval,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      reminders: reminders ?? this.reminders,
      coverPath: coverPath ?? this.coverPath,
      kind: kind ?? this.kind,
      unitLabel: unitLabel ?? this.unitLabel,
      incrementAmount: incrementAmount ?? this.incrementAmount,
      quantKind: quantKind ?? this.quantKind,
      bookCoverPath: bookCoverPath ?? this.bookCoverPath,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'category': category,
        'description': description,
        'color': color.toARGB32(),
        'order': order,
        'numberOfCompletionsPerDay': perDayTarget,
        'completions':
            completions.map((key, value) => MapEntry(key, value.toMap())),
        'interval': interval.index,
        'targetFrequency': targetFrequency,
        'reminders': reminders.map((r) => r.toMap()).toList(),
        'coverPath': coverPath,
        'createdAt': createdAt.toIso8601String(),
        'kind': kind.index,
        'unitLabel': unitLabel,
        'incrementAmount': incrementAmount,
        'quantKind': quantKind.index,
        'bookCoverPath': bookCoverPath,
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: (map['icon'] ?? 'target') as String,
        category: (map['category'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        color: Color(map['color'] as int),
        order: (map['order'] ?? 0) as int,
        perDayTarget: (map['numberOfCompletionsPerDay'] ?? 1) as int,
        completions: (map['completions'] as Map?)?.map(
              (key, value) => MapEntry(
                key as String,
                Completion.fromMap(Map<String, dynamic>.from(value as Map)),
              ),
            ) ??
            const {},
        interval: HabitInterval.values[(map['interval'] ?? 0) as int],
        targetFrequency: (map['targetFrequency'] ?? 1) as int,
        reminders: map['reminders'] == null
            ? const []
            : (map['reminders'] as List)
                .map((r) => Reminder.fromMap(Map<String, dynamic>.from(r as Map)))
                .toList(),
        coverPath: (map['coverPath'] ?? '') as String,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String)
            : null,
        kind: HabitKind.values[(map['kind'] ?? 0) as int],
        unitLabel: (map['unitLabel'] ?? '') as String,
        incrementAmount: (map['incrementAmount'] ?? 1) as int,
        quantKind: QuantKind.values[(map['quantKind'] ?? 0) as int],
        bookCoverPath: (map['bookCoverPath'] ?? '') as String,
      );

  String toJson() => json.encode(toMap());

  factory Habit.fromJson(String source) =>
      Habit.fromMap(json.decode(source) as Map<String, dynamic>);
}
