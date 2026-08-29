import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

class CompletionOps {
  const CompletionOps._();

  static Map<String, Completion> toggle(Habit habit, DateTime date) {
    if (habit.kind == HabitKind.negative) {
      if (date.atMidnight.isBefore(habit.createdAt.atMidnight)) {
        return {...habit.completions}..remove(date.dayKey);
      }
      return habit.isCompletedOn(date)
          ? logRelapse(habit, date)
          : clearRelapse(habit, date);
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
        hour: AppClock.now().hour,
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
        hour: entry?.hour ?? AppClock.now().hour,
      );
    }
    return completions;
  }

  static Map<String, Completion> toggleAllSteps(Habit habit, DateTime date) {
    final completions = {...habit.completions};
    final all = habit.substeps.map((s) => s.id).toSet();
    if (habit.isCompletedOn(date)) {
      completions.remove(date.dayKey);
    } else {
      completions[date.dayKey] = Completion(
        date: date.dayKey,
        count: all.length.toDouble(),
        steps: all,
        hour: completions[date.dayKey]?.hour ?? AppClock.now().hour,
      );
    }
    return completions;
  }

  static Map<String, Completion> logRelapse(Habit habit, DateTime date) {
    final completions = {...habit.completions};
    completions[date.dayKey] =
        Completion(date: date.dayKey, hour: AppClock.now().hour);
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
    final completions = {...habit.completions};
    final next = roundAmount((completions[date.dayKey]?.count ?? 0) + delta);
    if (next <= 0) {
      completions.remove(date.dayKey);
    } else {
      completions[date.dayKey] = Completion(
        date: date.dayKey,
        count: next,
        hour: AppClock.now().hour,
      );
    }
    return completions;
  }
}
