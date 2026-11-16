import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/todos/data/todo.dart';

class TodoCredit {
  const TodoCredit._();

  static bool linkable(Habit habit) =>
      !habit.isArchived &&
      !habit.tracking &&
      !habit.needsFocusSession &&
      !habit.readsSteps &&
      (habit.kind == HabitKind.positive ||
          (habit.kind == HabitKind.quantitative && !habit.isTimeAmount));

  static bool links(Habit habit, Todo todo) {
    final link = habit.todoLink;
    if (link.isEmpty || !linkable(habit)) return false;
    return todo.project == link || todo.tags.contains(link);
  }

  static DateTime dayOf(Todo todo) {
    final at = todo.doneAt ?? DateTime.now();
    return at.subtract(Duration(hours: AppClock.cutoffHour)).atMidnight;
  }

  static Set<String> apply(
    Map<String, Habit> habits,
    List<Todo> todos, {
    Todo? before,
    Todo? after,
  }) {
    final was = before?.done ?? false;
    final now = after?.done ?? false;
    if (was == now) return const {};
    final todo = now ? after! : before!;
    final day = dayOf(todo);
    final touched = <String>{};
    for (final habit in [...habits.values]) {
      if (!links(habit, todo)) continue;
      final completions = now
          ? _credit(habit, day)
          : _uncredit(habit, day, todos, todo.id);
      if (identical(completions, habit.completions)) continue;
      habits[habit.id] = habit.copyWith(completions: completions);
      touched.add(habit.id);
    }
    return touched;
  }

  static Map<String, Completion> _credit(Habit habit, DateTime day) {
    if (habit.kind == HabitKind.quantitative) {
      return CompletionOps.addProgress(habit, day, 1);
    }
    if (habit.isCompletedOn(day)) return habit.completions;
    return CompletionOps.toggle(habit, day);
  }

  static Map<String, Completion> _uncredit(
    Habit habit,
    DateTime day,
    List<Todo> todos,
    String id,
  ) {
    if (habit.kind == HabitKind.quantitative) {
      if ((habit.completions[day.dayKey]?.count ?? 0) <= 0) {
        return habit.completions;
      }
      return CompletionOps.addProgress(habit, day, -1);
    }
    if (!habit.isCompletedOn(day)) return habit.completions;
    final others = todos.any(
      (todo) =>
          todo.id != id &&
          todo.done &&
          links(habit, todo) &&
          dayOf(todo).isSameDay(day),
    );
    if (others) return habit.completions;
    return CompletionOps.toggle(habit, day);
  }
}
