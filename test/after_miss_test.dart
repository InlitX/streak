import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/reminder.dart';

final _today = AppClock.today();

DateTime _ago(int days) => _today.addDays(-days);

Completion _mark(int ago) =>
    Completion(date: _ago(ago).dayKey, hour: 9, count: 1);

Habit _habit(
  int daysOld,
  Set<int> missed, {
  bool today = false,
  HabitKind kind = HabitKind.positive,
  HabitInterval interval = HabitInterval.daily,
  List<int> weekdays = const [],
  bool tracking = false,
}) =>
    Habit(
      id: 'h',
      name: 'h',
      color: const Color(0xFF00FF00),
      order: 0,
      kind: kind,
      interval: interval,
      scheduleWeekdays: weekdays,
      tracking: tracking,
      createdAt: _ago(daysOld),
      completions: {
        for (var i = daysOld; i >= (today ? 0 : 1); i--)
          if (!missed.contains(i)) _ago(i).dayKey: _mark(i),
      },
    );

Habit _avoid(int daysOld, Set<int> relapses) => Habit(
      id: 'a',
      name: 'a',
      color: const Color(0xFF00FF00),
      order: 0,
      kind: HabitKind.negative,
      createdAt: _ago(daysOld),
      completions: {for (final i in relapses) _ago(i).dayKey: _mark(i)},
    );

void main() {
  tearDown(() => Habit.secondChances = false);

  test('a miss yesterday brings a gentle nudge today', () {
    expect(_habit(10, {1}).comebackOn(_today), ComebackTone.gentle);
  });

  test('nothing after a good day', () {
    expect(_habit(10, {}).comebackOn(_today), isNull);
  });

  test('quiet once today is done', () {
    expect(_habit(10, {1}, today: true).comebackOn(_today), isNull);
  });

  test('only once per run of misses', () {
    expect(_habit(10, {1, 2}).comebackOn(_today), isNull);
  });

  test('today still open arms tomorrow, done today disarms it', () {
    final tomorrow = _today.addDays(1);
    expect(_habit(10, {}).comebackOn(tomorrow), ComebackTone.gentle);
    expect(_habit(10, {}, today: true).comebackOn(tomorrow), isNull);
  });

  test('looks back to the last day the habit was due', () {
    final off = _ago(1).weekday;
    final habit = _habit(
      10,
      {2},
      interval: HabitInterval.weekdays,
      weekdays: [for (var d = 1; d <= 7; d++) if (d != off) d],
    );
    expect(habit.dueBefore(_today), _ago(2));
    expect(habit.comebackOn(_today), ComebackTone.gentle);
  });

  test('keeps missing lately suggests a smaller goal', () {
    expect(_habit(20, {1, 4, 7, 10}).comebackOn(_today), ComebackTone.hard);
    expect(_habit(20, {1, 4, 7}).comebackOn(_today), ComebackTone.gentle);
  });

  test('a miss saved by a second chance says so', () {
    Habit.secondChances = true;
    expect(_habit(40, {1}).comebackOn(_today), ComebackTone.chance);
    expect(_habit(40, {}).comebackOn(_today.addDays(1)), ComebackTone.chance);
  });

  test('avoid habits nudge after a relapse, once', () {
    expect(_avoid(10, {1}).comebackOn(_today), ComebackTone.avoid);
    expect(_avoid(10, {1, 2}).comebackOn(_today), isNull);
    expect(_avoid(10, {1, 0}).comebackOn(_today), isNull);
    expect(_avoid(10, {}).comebackOn(_today), isNull);
    expect(_avoid(10, {0}).comebackOn(_today.addDays(1)), ComebackTone.avoid);
  });

  test('not for tracking, weekly or monthly habits', () {
    expect(_habit(10, {1}, tracking: true).comebackOn(_today), isNull);
    expect(
      _habit(10, {1}, interval: HabitInterval.weekly).comebackOn(_today),
      isNull,
    );
    expect(
      Habit.missFollowable(HabitKind.positive, HabitInterval.monthly),
      isFalse,
    );
  });

  test('nothing before the habit existed', () {
    expect(_habit(0, {}).comebackOn(_today), isNull);
  });

  test('the option survives a backup', () {
    const reminder = Reminder(
      id: 'r',
      hour: 21,
      minute: 0,
      days: [1, 2, 3, 4, 5, 6, 7],
      afterMiss: true,
    );
    expect(Reminder.fromMap(reminder.toMap()).afterMiss, isTrue);
    expect(
      Reminder.fromMap({
        'id': 'r',
        'hour': 8,
        'minute': 0,
        'selectedDays': [1],
      }).afterMiss,
      isFalse,
    );
  });

  test('followsMisses needs an after-miss reminder', () {
    final plain = _habit(10, {1});
    expect(plain.followsMisses, isFalse);
    final armed = plain.copyWith(reminders: const [
      Reminder(id: 'r', hour: 21, minute: 0, days: [1], afterMiss: true),
    ]);
    expect(armed.followsMisses, isTrue);
  });
}
