import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

int _nowMinutes() {
  final now = AppClock.wallNow();
  return now.hour * 60 + now.minute;
}

bool _isFuture(DateTime date) =>
    date.atMidnight.isAfter(AppClock.today());

class CompletionOps {
  const CompletionOps._();

  static Map<String, Completion> toggle(Habit habit, DateTime date) {
    if (_isFuture(date)) return habit.completions;
    if (habit.kind == HabitKind.negative) {
      return habit.completions.containsKey(date.dayKey)
          ? clearRelapse(habit, date)
          : logRelapse(habit, date);
    }
    if (habit.hasSubsteps) return toggleAllSteps(habit, date);
    final completions = {...habit.completions};
    if (habit.isCompletedOn(date)) {
      completions.remove(date.dayKey);
    } else {
      completions[date.dayKey] = Completion(
        date: date.dayKey,
        count: habit.kind == HabitKind.quantitative
            ? (habit.perDayTarget <= 0 ? 1 : habit.perDayTarget)
            : 1,
        hour: AppClock.wallNow().hour,
        minute: AppClock.wallNow().minute,
        marks: [_nowMinutes()],
      );
    }
    return completions;
  }

  static Map<String, Completion> setStep(
    Habit habit,
    DateTime date,
    String stepId,
    bool checked,
  ) {
    if (_isFuture(date)) return habit.completions;
    final completions = {...habit.completions};
    final entry = completions[date.dayKey];
    final steps = {...?entry?.steps};
    if (checked) {
      steps.add(stepId);
    } else {
      steps.remove(stepId);
    }
    final valid = habit.substeps.map((s) => s.id).toSet();
    steps.retainWhere(valid.contains);
    if (steps.isEmpty) {
      completions.remove(date.dayKey);
    } else {
      completions[date.dayKey] = Completion(
        date: date.dayKey,
        count: steps.length.toDouble(),
        steps: steps,
        hour: AppClock.wallNow().hour,
        minute: AppClock.wallNow().minute,
        marks: checked ? (entry?.plus(_nowMinutes()) ?? [_nowMinutes()])
            : (entry?.marks ?? const []),
      );
    }
    return completions;
  }

  static Map<String, Completion> toggleAllSteps(Habit habit, DateTime date) {
    if (_isFuture(date)) return habit.completions;
    final completions = {...habit.completions};
    final all = habit.substeps.map((s) => s.id).toSet();
    if (habit.isCompletedOn(date)) {
      completions.remove(date.dayKey);
    } else {
      completions[date.dayKey] = Completion(
        date: date.dayKey,
        count: all.length.toDouble(),
        steps: all,
        hour: AppClock.wallNow().hour,
        minute: AppClock.wallNow().minute,
        marks: completions[date.dayKey]?.plus(_nowMinutes()) ??
            [_nowMinutes()],
      );
    }
    return completions;
  }

  static Map<String, Completion> logRelapse(
    Habit habit,
    DateTime date, {
    double? spent,
  }) {
    if (_isFuture(date)) return habit.completions;
    final completions = {...habit.completions};
    completions[date.dayKey] = Completion(
      date: date.dayKey,
      hour: AppClock.wallNow().hour,
      minute: AppClock.wallNow().minute,
      marks: [_nowMinutes()],
      spent: spent ?? (habit.logsSpent ? habit.dailyCost : 0),
    );
    return completions;
  }

  static Map<String, Completion> setSpent(
    Habit habit,
    DateTime date,
    double spent,
  ) {
    final entry = habit.completions[date.dayKey];
    if (entry == null) return habit.completions;
    return {
      ...habit.completions,
      date.dayKey: entry.copyWith(spent: spent < 0 ? 0 : spent),
    };
  }

  static Map<String, Completion> addRelapse(Habit habit, DateTime date) {
    final entry = habit.completions[date.dayKey];
    if (entry == null) return logRelapse(habit, date);
    if (_isFuture(date)) return habit.completions;
    return {
      ...habit.completions,
      date.dayKey: entry.copyWith(
        count: entry.count.roundToDouble() + 1,
        hour: AppClock.wallNow().hour,
        minute: AppClock.wallNow().minute,
        marks: entry.plus(_nowMinutes()),
      ),
    };
  }

  static Map<String, Completion> dropRelapse(Habit habit, DateTime date) {
    final entry = habit.completions[date.dayKey];
    if (entry == null || entry.count <= 1) return clearRelapse(habit, date);
    return {
      ...habit.completions,
      date.dayKey: entry.copyWith(
        count: entry.count.roundToDouble() - 1,
        marks: entry.marks.isEmpty
            ? entry.marks
            : entry.marks.sublist(0, entry.marks.length - 1),
      ),
    };
  }

  static Map<String, Completion> retime(
    Habit habit,
    String dayKey,
    int? from,
    int to,
  ) {
    final entry = habit.completions[dayKey];
    if (entry == null) return habit.completions;
    final marks = [...entry.times];
    final index = from == null ? -1 : marks.indexOf(from);
    if (index < 0) {
      marks.add(to);
    } else {
      marks[index] = to;
    }
    marks.sort();
    return {
      ...habit.completions,
      dayKey: entry.copyWith(
        hour: marks.last ~/ 60,
        minute: marks.last % 60,
        marks: marks,
      ),
    };
  }

  static Map<String, Completion> clearRelapse(Habit habit, DateTime date) {
    final completions = {...habit.completions};
    completions.remove(date.dayKey);
    return completions;
  }

  static Map<String, Completion> raiseCounts(
    Habit habit,
    Map<DateTime, double> counts,
  ) {
    Map<String, Completion>? completions;
    for (final MapEntry(key: date, value: count) in counts.entries) {
      if (_isFuture(date)) continue;
      final previous = habit.completions[date.dayKey];
      if (count <= (previous?.count ?? 0)) continue;
      final today = date.isSameDay(AppClock.today());
      completions ??= {...habit.completions};
      completions[date.dayKey] = previous?.copyWith(count: count) ??
          Completion(
            date: date.dayKey,
            count: count,
            hour: today ? AppClock.wallNow().hour : null,
            minute: today ? AppClock.wallNow().minute : null,
            marks: today ? [_nowMinutes()] : const [],
          );
    }
    return completions ?? habit.completions;
  }

  static Map<String, Completion> addProgress(
    Habit habit,
    DateTime date,
    double delta,
  ) {
    if (_isFuture(date)) return habit.completions;
    final completions = {...habit.completions};
    final previous = completions[date.dayKey];
    final next = roundAmount((previous?.count ?? 0) + delta);
    if (next <= 0) {
      completions.remove(date.dayKey);
    } else if (delta > 0) {
      completions[date.dayKey] = Completion(
        date: date.dayKey,
        count: next,
        hour: AppClock.wallNow().hour,
        minute: AppClock.wallNow().minute,
        marks: previous?.plus(_nowMinutes()) ?? [_nowMinutes()],
      );
    } else {
      final marks = [...?previous?.marks];
      if (marks.isNotEmpty) marks.removeLast();
      completions[date.dayKey] = Completion(
        date: date.dayKey,
        count: next,
        hour: marks.isEmpty ? previous?.hour : marks.last ~/ 60,
        minute: marks.isEmpty ? previous?.minute : marks.last % 60,
        marks: marks,
      );
    }
    return completions;
  }
}
