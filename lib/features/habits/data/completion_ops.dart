import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

// Shared by the app and the widget background isolate.
class CompletionOps {
  const CompletionOps._();

  static Map<String, Completion> toggle(Habit habit, DateTime date) {
    if (habit.hasSubsteps) return toggleAllSteps(habit, date);
    final completions = {...habit.completions};
    if (habit.isCompletedOn(date)) {
      completions.remove(date.dayKey);
    } else {
      completions[date.dayKey] =
          Completion(date: date.dayKey, hour: DateTime.now().hour);
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
        count: steps.length,
        steps: steps,
        hour: entry?.hour ?? DateTime.now().hour,
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
        count: all.length,
        steps: all,
        hour: completions[date.dayKey]?.hour ?? DateTime.now().hour,
      );
    }
    return completions;
  }

  static Map<String, Completion> logRelapse(Habit habit, DateTime date) {
    final completions = {...habit.completions};
    completions[date.dayKey] =
        Completion(date: date.dayKey, hour: DateTime.now().hour);
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
    int delta,
  ) {
    final completions = {...habit.completions};
    final next = (completions[date.dayKey]?.count ?? 0) + delta;
    if (next <= 0) {
      completions.remove(date.dayKey);
    } else {
      completions[date.dayKey] = Completion(
        date: date.dayKey,
        count: next,
        hour: DateTime.now().hour,
      );
    }
    return completions;
  }
}
