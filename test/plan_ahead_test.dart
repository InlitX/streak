import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/todos/data/todo_repeat.dart';
import 'package:streak/features/todos/state/todos_controller.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  final today = AppClock.today();

  test('a habit counted from the last time done is planned as if kept on time', () {
    final habit = testHabit(
      id: 'a',
      name: 'Water plants',
      interval: HabitInterval.everyXDays,
      done: [today.addDays(-10)],
    ).copyWith(scheduleEvery: 3, fromLastDone: true);
    expect(habit.isScheduledOn(today.addDays(1)), isTrue);
    expect(DayPlan.isDueOn(habit, today), isTrue);
    expect(DayPlan.isDueOn(habit, today.addDays(1)), isFalse);
    expect(DayPlan.isDueOn(habit, today.addDays(2)), isFalse);
    expect(DayPlan.isDueOn(habit, today.addDays(3)), isTrue);
    expect(DayPlan.isDueOn(habit, today.addDays(6)), isTrue);
  });

  test('a spaced review comes back later each time and then ends', () {
    var todo = testTodo(id: 's', text: 'Chapter 3', due: today)
        .copyWith(repeat: const TodoRepeat(unit: RepeatUnit.days, spaced: true));
    final gaps = <int>[];
    var day = today;
    while (todo.repeats) {
      todo = todo.nextTime(day);
      gaps.add(todo.due!.epochDay - day.epochDay);
      day = todo.due!;
    }
    expect(gaps, TodoRepeat.spacedGaps);
    expect(todo.repeat!.isOver, isTrue);
    expect(TodoRepeat.fromMap(todo.repeat!.toMap()), todo.repeat);
  });

  test('a future day in Plan shows the next times of a repeating to-do', () async {
    await LocalStore.writeTodo(
      testTodo(id: 'r', text: 'Review', due: today)
          .copyWith(repeat: const TodoRepeat(unit: RepeatUnit.days, spaced: true)),
    );
    await LocalStore.writeTodo(
      testTodo(id: 'w', text: 'Bins', due: today.addDays(-2))
          .copyWith(repeat: const TodoRepeat(unit: RepeatUnit.weeks)),
    );
    final todos = TodosController();
    List<String> on(int days) =>
        todos.plannedOn(today.addDays(days)).map((t) => t.id).toList();
    expect(on(0), ['r']);
    expect(on(1), ['r']);
    expect(on(2), isEmpty);
    expect(on(3), ['r']);
    expect(on(5), ['w']);
    expect(on(7), ['r']);
    expect(todos.byId('r')!.due, today);
  });
}
