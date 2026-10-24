import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_repeat.dart';

void main() {
  DateTime next(TodoRepeat repeat, DateTime due, DateTime today) =>
      repeat.anchoredTo(due).after(due, today: today);

  test('daily moves past an overdue day to tomorrow', () {
    const daily = TodoRepeat(unit: RepeatUnit.days);
    expect(
      next(daily, DateTime(2026, 10, 20), DateTime(2026, 10, 24)),
      DateTime(2026, 10, 25),
    );
  });

  test('every 3 days counts from the due date', () {
    const every3 = TodoRepeat(unit: RepeatUnit.days, every: 3);
    expect(
      next(every3, DateTime(2026, 10, 24), DateTime(2026, 10, 24)),
      DateTime(2026, 10, 27),
    );
  });

  test('weekdays skip the weekend', () {
    const workdays = TodoRepeat(
      unit: RepeatUnit.weeks,
      weekdays: TodoRepeat.workdays,
    );
    expect(
      next(workdays, DateTime(2026, 10, 23), DateTime(2026, 10, 23)),
      DateTime(2026, 10, 26),
    );
  });

  test('every two weeks on Monday and Thursday', () {
    const repeat = TodoRepeat(
      unit: RepeatUnit.weeks,
      every: 2,
      weekdays: [1, 4],
    );
    final monday = DateTime(2026, 10, 19);
    expect(next(repeat, monday, monday), DateTime(2026, 10, 22));
    final thursday = DateTime(2026, 10, 22);
    expect(next(repeat, thursday, thursday), DateTime(2026, 11, 2));
  });

  test('monthly on the 31st keeps the 31st after a short month', () {
    final repeat = const TodoRepeat(unit: RepeatUnit.months)
        .anchoredTo(DateTime(2027, 1, 31));
    final feb = repeat.after(DateTime(2027, 1, 31), today: DateTime(2027, 1, 31));
    expect(feb, DateTime(2027, 2, 28));
    expect(repeat.after(feb, today: feb), DateTime(2027, 3, 31));
  });

  test('monthly by weekday keeps the second Tuesday', () {
    const repeat = TodoRepeat(unit: RepeatUnit.months, byWeekday: true);
    final due = DateTime(2026, 10, 13);
    expect(next(repeat, due, due), DateTime(2026, 11, 10));
  });

  test('yearly on Feb 29 falls back to Feb 28', () {
    const repeat = TodoRepeat(unit: RepeatUnit.years);
    final due = DateTime(2028, 2, 29);
    expect(next(repeat, due, due), DateTime(2029, 2, 28));
  });

  test('from completion counts from today, skipping from the due date', () {
    const repeat = TodoRepeat(unit: RepeatUnit.weeks, fromDone: true);
    final due = DateTime(2026, 10, 1);
    final today = DateTime(2026, 10, 24);
    expect(repeat.after(due, today: today), DateTime(2026, 10, 31));
    expect(
      repeat.after(due, today: today, skipping: true),
      DateTime(2026, 10, 29),
    );
  });

  test('finishing a repeating to-do keeps a done copy and resets steps', () {
    final todo = Todo(
      id: 'rent',
      text: 'Pay rent',
      createdAt: DateTime(2026, 9, 1),
      date: '01-10-2026',
      photos: const ['a.jpg'],
      steps: const [TodoStep(id: 's', text: 'Transfer', done: true)],
      repeat: const TodoRepeat(unit: RepeatUnit.months, day: 1),
    );
    final next = todo.nextTime(DateTime(2026, 10, 2));
    expect(next.id, 'rent');
    expect(next.date, '01-11-2026');
    expect(next.done, isFalse);
    expect(next.steps.single.done, isFalse);
    expect(next.photos, ['a.jpg']);

    final record = todo.doneRecord('copy', DateTime(2026, 10, 2));
    expect(record.done, isTrue);
    expect(record.date, '01-10-2026');
    expect(record.repeat, isNull);
    expect(record.photos, isEmpty);
  });

  test('repeat survives a round trip through the store map', () {
    const repeat = TodoRepeat(
      unit: RepeatUnit.weeks,
      every: 2,
      weekdays: [2, 5],
      fromDone: true,
    );
    final todo = Todo(
      id: 'x',
      text: 'x',
      createdAt: DateTime(2026),
      date: '24-10-2026',
      repeat: repeat,
    );
    expect(Todo.fromMap(todo.toMap()).repeat, repeat);
    expect(Todo.fromMap({'id': 'y'}).repeat, isNull);
  });
}
