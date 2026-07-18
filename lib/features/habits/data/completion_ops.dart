import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

// Shared completion mutations for foreground and the widget background isolate.
class CompletionOps {
  const CompletionOps._();

  static Map<String, Completion> toggle(Habit habit, DateTime date) {
    final completions = {...habit.completions};
    if (habit.isCompletedOn(date)) {
      completions.remove(date.dayKey);
    } else {
      completions[date.dayKey] =
          Completion(date: date.dayKey, hour: DateTime.now().hour);
    }
    return completions;
  }

  // For negatives "completed" means clean, so this writes directly (not toggle).
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
