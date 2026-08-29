import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/data/vacation.dart';

enum HabitInterval { daily, weekly, monthly, weekdays, everyXDays }

extension HabitIntervalLabel on HabitInterval {
  String get label => switch (this) {
        HabitInterval.daily => 'Daily',
        HabitInterval.weekly => 'Weekly',
        HabitInterval.monthly => 'Monthly',
        HabitInterval.weekdays => 'Days',
        HabitInterval.everyXDays => 'Interval',
      };

  String get unit => switch (this) {
        HabitInterval.daily => 'day',
        HabitInterval.weekly => 'week',
        HabitInterval.monthly => 'month',
        HabitInterval.weekdays => 'day',
        HabitInterval.everyXDays => 'day',
      };

  bool get isDaySpecific =>
      this == HabitInterval.weekdays || this == HabitInterval.everyXDays;
}

enum HabitKind { positive, negative, quantitative }

enum QuantKind { generic, water, reading, time }

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
    this.scheduleWeekdays = const [],
    this.scheduleEvery = 2,
    this.reminders = const [],
    this.coverPath = '',
    this.kind = HabitKind.positive,
    this.dailyCost = 0,
    this.unitLabel = '',
    this.incrementAmount = 1,
    this.quantKind = QuantKind.generic,
    this.bookCoverPath = '',
    this.focusMinutes = 25,
    this.focusBreakMinutes = 0,
    this.focusOnly = false,
    this.tracking = false,
    this.startMinute = -1,
    this.durationMinutes = 0,
    this.substeps = const [],
    this.vacations = const [],
    this.restDays = const [],
    this.archivedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? AppClock.now();

  final String id;
  final String name;
  final String icon;
  final String category;
  final String description;
  final Color color;
  final int order;

  final double perDayTarget;
  final Map<String, Completion> completions;
  final HabitInterval interval;
  final int targetFrequency;

  final List<int> scheduleWeekdays;

  final int scheduleEvery;

  final List<Reminder> reminders;

  bool isScheduledOn(DateTime date) {
    switch (interval) {
      case HabitInterval.weekdays:
        return scheduleWeekdays.contains(date.weekday);
      case HabitInterval.everyXDays:
        if (scheduleEvery <= 0) return false;
        final diff = date.atMidnight.difference(createdAt.atMidnight).inDays;
        return diff >= 0 && diff % scheduleEvery == 0;
      case HabitInterval.daily:
      case HabitInterval.weekly:
      case HabitInterval.monthly:
        return true;
    }
  }

  final String coverPath;
  final DateTime createdAt;

  final HabitKind kind;
  final double dailyCost;
  final String unitLabel;
  final double incrementAmount;
  final QuantKind quantKind;

  final String bookCoverPath;

  final int focusMinutes;
  final int focusBreakMinutes;
  final bool focusOnly;

  final bool tracking;

  final int startMinute;
  final int durationMinutes;

  static const dayMinutes = 24 * 60;

  bool get isPlanned => startMinute >= 0;

  int get endMinute =>
      (startMinute + durationMinutes).clamp(startMinute, dayMinutes);

  bool get isTimeAmount =>
      kind == HabitKind.quantitative && quantKind == QuantKind.time;

  String amountText(double value) =>
      isTimeAmount ? formatMinutes(value) : formatAmount(value);

  bool get needsFocusSession =>
      focusOnly && kind == HabitKind.positive && substeps.isEmpty;

  bool blocksManualCheck(DateTime date, {bool fromFocus = false}) =>
      needsFocusSession && !fromFocus && !isCompletedOn(date);

  final List<Substep> substeps;

  final List<VacationPeriod> vacations;

  final List<int> restDays;

  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  bool get hasSubsteps => substeps.isNotEmpty;

  double get effectiveTarget =>
      hasSubsteps ? substeps.length.toDouble() : perDayTarget;

  bool isRestDay(DateTime date) => restDays.contains(date.weekday);

  bool isPausedOn(DateTime date) =>
      isRestDay(date) || vacations.any((v) => v.contains(date));

  bool isOffDay(DateTime date) => !isScheduledOn(date) || isPausedOn(date);

  bool get isOnVacation => vacations.any((v) => v.isOngoing);

  bool isNeutralOn(DateTime date) =>
      isPausedOn(date) && !completions.containsKey(date.dayKey);

  bool isSatisfiedOn(DateTime date) =>
      isCompletedOn(date) || _doneAheadOf(date);

  bool _doneAheadOf(DateTime date) {
    if (interval != HabitInterval.everyXDays || scheduleEvery <= 1) return false;
    final floor = createdAt.atMidnight;
    var cursor = date.atMidnight;
    for (var step = 1; step < scheduleEvery; step++) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (cursor.isBefore(floor)) return false;
      if (isCompletedOn(cursor)) return true;
    }
    return false;
  }

  bool isCoveredOn(DateTime date) {
    if (interval != HabitInterval.everyXDays || scheduleEvery <= 1) return false;
    var cursor = date.atMidnight;
    if (isScheduledOn(cursor) || cursor.isAfter(AppClock.now().atMidnight)) {
      return false;
    }
    final floor = createdAt.atMidnight;
    for (var step = 1; step < scheduleEvery; step++) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (cursor.isBefore(floor)) return false;
      if (isCompletedOn(cursor)) return true;
      if (isScheduledOn(cursor)) return false;
    }
    return false;
  }

  bool isCompletedOn(DateTime date) {
    final day = date.atMidnight;
    if (day.isAfter(AppClock.now().atMidnight)) return false;
    final entry = completions[date.dayKey];
    if (kind == HabitKind.negative) {
      return day.isBefore(createdAt.atMidnight) ? false : entry == null;
    }
    if (entry == null) return false;
    if (hasSubsteps) {
      return substeps.every((s) => entry.steps.contains(s.id));
    }
    return entry.count >= perDayTarget;
  }

  bool get hasCost => kind == HabitKind.negative && dailyCost > 0;

  late final int cleanDays = _cleanDays();

  int _cleanDays() {
    if (kind != HabitKind.negative) return 0;
    final floor = createdAt.atMidnight;
    final span = AppClock.now().atMidnight.epochDay - floor.epochDay + 1;
    if (span <= 0) return 0;
    return span - _relapsesSince(floor);
  }

  int _relapsesSince(DateTime floor) {
    final today = AppClock.now().atMidnight;
    var relapses = 0;
    for (final entry in completions.values) {
      final day = parseDayKey(entry.date);
      if (!day.isBefore(floor) && !day.isAfter(today)) relapses++;
    }
    return relapses;
  }

  double get moneySaved => hasCost ? cleanDays * dailyCost : 0;

  late final int totalCompletions = _totalCompletions();

  int _totalCompletions() {
    if (hasSubsteps) {
      final ids = substeps.map((s) => s.id).toSet();
      return completions.values.where((c) => ids.every(c.steps.contains)).length;
    }
    return completions.values.where((c) => c.count >= perDayTarget).length;
  }

  bool get isDoneForNow {
    if (kind == HabitKind.negative) return false;
    final now = AppClock.now();
    return isOffDay(now) || isCompletedOn(now);
  }

  double _dayValue(DateTime date) {
    final day = date.atMidnight;
    if (day.isBefore(createdAt.atMidnight) ||
        day.isAfter(AppClock.now().atMidnight)) {
      return 0;
    }
    if (kind == HabitKind.negative) {
      return completions.containsKey(date.dayKey) ? 0.0 : 1.0;
    }
    final count = completions[date.dayKey]?.count ?? 0;
    final target = effectiveTarget;
    if (target <= 0) return count > 0 ? 1 : 0;
    return (count / target).clamp(0.0, 1.0);
  }

  late final double strength = _strength();

  double _strength() {
    if (completions.isEmpty && kind != HabitKind.negative) return 0;
    final now = AppClock.now().atMidnight;
    final floor = createdAt.atMidnight;
    const halfLife = 12.0;
    const window = 90;
    var score = 0.0;
    var norm = 0.0;
    for (var i = 0; i < window; i++) {
      final day = now.subtract(Duration(days: i));
      if (day.isBefore(floor) || !isScheduledOn(day) || isNeutralOn(day)) {
        continue;
      }
      final weight = math.pow(0.5, i / halfLife).toDouble();
      norm += weight;
      score += weight * _dayValue(day);
    }
    return norm == 0 ? 0 : (score / norm).clamp(0.0, 1.0);
  }

  late final int consistency = (strength * 100).round();

  int _countInRange(DateTime start, DateTime end) {
    var count = 0;
    for (var i = 0; i <= end.difference(start).inDays; i++) {
      if (isCompletedOn(start.add(Duration(days: i)))) count++;
    }
    return count;
  }

  late final int currentStreak = _currentStreak();

  int _currentStreak() {
    final floor = createdAt.atMidnight;

    if (kind == HabitKind.negative) {
      var cursor = AppClock.now().atMidnight;
      var streak = 0;
      while (!cursor.isBefore(floor)) {
        if (isNeutralOn(cursor)) {
        } else if (isCompletedOn(cursor)) {
          streak++;
        } else {
          break;
        }
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return streak;
    }

    if (completions.isEmpty) return 0;
    final now = AppClock.now();

    switch (interval) {
      case HabitInterval.daily:
        var cursor = now.atMidnight;
        if (!isCompletedOn(cursor) && !isNeutralOn(cursor)) {
          cursor = cursor.subtract(const Duration(days: 1));
          if (!isCompletedOn(cursor) && !isNeutralOn(cursor)) return 0;
        }
        var streak = 0;
        while (!cursor.isBefore(floor)) {
          if (isNeutralOn(cursor)) {
          } else if (isCompletedOn(cursor)) {
            streak++;
          } else {
            break;
          }
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
        final monthEnd =
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

      case HabitInterval.weekdays:
      case HabitInterval.everyXDays:
        return _daySpecificCurrentStreak();
    }
  }

  int _daySpecificCurrentStreak() {
    final floor = createdAt.atMidnight;
    final today = AppClock.now().atMidnight;
    var cursor = today;
    var streak = 0;
    while (!cursor.isBefore(floor)) {
      if (isNeutralOn(cursor) || !isScheduledOn(cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (isSatisfiedOn(cursor)) {
        streak++;
      } else if (cursor.isAtSameMomentAs(today)) {
      } else {
        break;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _daySpecificLongestStreak() {
    var cursor = createdAt.atMidnight;
    final end = AppClock.now().atMidnight;
    var best = 0;
    var run = 0;
    while (!cursor.isAfter(end)) {
      if (isNeutralOn(cursor) || !isScheduledOn(cursor)) {
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }
      if (isSatisfiedOn(cursor)) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return best;
  }

  late final int longestStreak = _longestStreak();

  int _longestStreak() {
    if (kind == HabitKind.negative) {
      var cursor = createdAt.atMidnight;
      final end = AppClock.now().atMidnight;
      var best = 0;
      var run = 0;
      while (!cursor.isAfter(end)) {
        if (isNeutralOn(cursor)) {
        } else if (isCompletedOn(cursor)) {
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
        var cursor = createdAt.atMidnight;
        final end = AppClock.now().atMidnight;
        var best = 0;
        var run = 0;
        while (!cursor.isAfter(end)) {
          if (isNeutralOn(cursor)) {
          } else if (isCompletedOn(cursor)) {
            run++;
            if (run > best) best = run;
          } else {
            run = 0;
          }
          cursor = cursor.add(const Duration(days: 1));
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

      case HabitInterval.weekdays:
      case HabitInterval.everyXDays:
        return _daySpecificLongestStreak();
    }
  }

  Habit copyWith({
    String? name,
    String? icon,
    String? category,
    String? description,
    Color? color,
    int? order,
    double? perDayTarget,
    Map<String, Completion>? completions,
    HabitInterval? interval,
    int? targetFrequency,
    List<int>? scheduleWeekdays,
    int? scheduleEvery,
    List<Reminder>? reminders,
    String? coverPath,
    HabitKind? kind,
    double? dailyCost,
    String? unitLabel,
    double? incrementAmount,
    QuantKind? quantKind,
    String? bookCoverPath,
    int? focusMinutes,
    int? focusBreakMinutes,
    bool? focusOnly,
    bool? tracking,
    int? startMinute,
    int? durationMinutes,
    List<Substep>? substeps,
    List<VacationPeriod>? vacations,
    List<int>? restDays,
    DateTime? archivedAt,
    bool clearArchived = false,
    DateTime? createdAt,
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
      scheduleWeekdays: scheduleWeekdays ?? this.scheduleWeekdays,
      scheduleEvery: scheduleEvery ?? this.scheduleEvery,
      reminders: reminders ?? this.reminders,
      coverPath: coverPath ?? this.coverPath,
      kind: kind ?? this.kind,
      dailyCost: dailyCost ?? this.dailyCost,
      unitLabel: unitLabel ?? this.unitLabel,
      incrementAmount: incrementAmount ?? this.incrementAmount,
      quantKind: quantKind ?? this.quantKind,
      bookCoverPath: bookCoverPath ?? this.bookCoverPath,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      focusOnly: focusOnly ?? this.focusOnly,
      tracking: tracking ?? this.tracking,
      focusBreakMinutes: focusBreakMinutes ?? this.focusBreakMinutes,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      substeps: substeps ?? this.substeps,
      vacations: vacations ?? this.vacations,
      restDays: restDays ?? this.restDays,
      archivedAt: clearArchived ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt ?? this.createdAt,
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
        'scheduleWeekdays': scheduleWeekdays,
        'scheduleEvery': scheduleEvery,
        'reminders': reminders.map((r) => r.toMap()).toList(),
        'coverPath': coverPath,
        'createdAt': createdAt.toIso8601String(),
        'kind': kind.index,
        'dailyCost': dailyCost,
        'unitLabel': unitLabel,
        'incrementAmount': incrementAmount,
        'quantKind': quantKind.index,
        'bookCoverPath': bookCoverPath,
        'focusMinutes': focusMinutes,
        'focusBreakMinutes': focusBreakMinutes,
        'focusOnly': focusOnly,
        'tracking': tracking,
        'startMinute': startMinute,
        'durationMinutes': durationMinutes,
        'substeps': substeps.map((s) => s.toMap()).toList(),
        'vacations': vacations.map((v) => v.toMap()).toList(),
        'restDays': restDays,
        if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: (map['icon'] ?? 'target') as String,
        category: (map['category'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        color: Color(map['color'] as int),
        order: (map['order'] ?? 0) as int,
        perDayTarget:
            ((map['numberOfCompletionsPerDay'] ?? 1) as num).toDouble(),
        completions: (map['completions'] as Map?)?.map(
              (key, value) => MapEntry(
                key as String,
                Completion.fromMap(Map<String, dynamic>.from(value as Map)),
              ),
            ) ??
            const {},
        interval: HabitInterval.values[(map['interval'] ?? 0) as int],
        targetFrequency: (map['targetFrequency'] ?? 1) as int,
        scheduleWeekdays: (map['scheduleWeekdays'] as List?)
                ?.map((e) => e as int)
                .toList() ??
            const [],
        scheduleEvery: (map['scheduleEvery'] ?? 2) as int,
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
        dailyCost: ((map['dailyCost'] ?? 0) as num).toDouble(),
        unitLabel: (map['unitLabel'] ?? '') as String,
        incrementAmount: ((map['incrementAmount'] ?? 1) as num).toDouble(),
        quantKind: QuantKind.values[(map['quantKind'] ?? 0) as int],
        bookCoverPath: (map['bookCoverPath'] ?? '') as String,
        focusMinutes: ((map['focusMinutes'] ?? 25) as num).toInt(),
        focusBreakMinutes:
            ((map['focusBreakMinutes'] ?? 0) as num).toInt(),
        focusOnly: (map['focusOnly'] ?? false) as bool,
        tracking: (map['tracking'] ?? false) as bool,
        startMinute: ((map['startMinute'] ?? -1) as num).toInt(),
        durationMinutes: ((map['durationMinutes'] ?? 0) as num).toInt(),
        substeps: map['substeps'] == null
            ? const []
            : (map['substeps'] as List)
                .map((s) => Substep.fromMap(Map<String, dynamic>.from(s as Map)))
                .toList(),
        vacations: map['vacations'] == null
            ? const []
            : (map['vacations'] as List)
                .map((v) =>
                    VacationPeriod.fromMap(Map<String, dynamic>.from(v as Map)))
                .toList(),
        restDays:
            (map['restDays'] as List?)?.map((e) => e as int).toList() ?? const [],
        archivedAt: map['archivedAt'] == null
            ? null
            : DateTime.tryParse(map['archivedAt'] as String),
      );

  String toJson() => json.encode(toMap());

  factory Habit.fromJson(String source) =>
      Habit.fromMap(json.decode(source) as Map<String, dynamic>);
}
