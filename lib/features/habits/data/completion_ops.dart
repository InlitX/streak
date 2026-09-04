import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

int _nowMinutes() {
  final now = AppClock.wallNow();
  return now.hour * 60 + now.minute;
}

bool _isFuture(DateTime date) =>
    date.atMidnight.isAfter(AppClock.now().atMidnight);

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

  static Map<String, Completion> logRelapse(Habit habit, DateTime date) {
    if (_isFuture(date)) return habit.completions;
    final completions = {...habit.completions};
    completions[date.dayKey] = Completion(
      date: date.dayKey,
      hour: AppClock.wallNow().hour,
      minute: AppClock.wallNow().minute,
      marks: [_nowMinutes()],
    );
    return completions;
  }

  static Map<String, Completion> clearRelapse(Habit habit, DateTime date) {
    final completions = {...habit.completions};
    completions.remove(date.dayKey);
    return completions;
  }

  static Map<String, Completion> addProgress(
    Habit habit,
    DateTime date,
    double delta,
  ) {
    if (_isFuture(date)) return habit.completions;
    final completions = {...habit.completions};
    final next = roundAmount((completions[date.dayKey]?.count ?? 0) + delta);
    if (next <= 0) {
      completions.remove(date.dayKey);
    } else {
      completions[date.dayKey] = Completion(
        date: date.dayKey,
        count: next,
        hour: AppClock.wallNow().hour,
        minute: AppClock.wallNow().minute,
        marks: delta > 0
            ? (completions[date.dayKey]?.plus(_nowMinutes()) ??
                [_nowMinutes()])
            : (completions[date.dayKey]?.marks ?? const []),
      );
    }
    return completions;
  }
}
