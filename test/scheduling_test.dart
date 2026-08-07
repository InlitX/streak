import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

DateTime _today() => DateTime.now().atMidnight;
DateTime _ago(int days) => _today().subtract(Duration(days: days));

Map<String, Completion> _done(Iterable<DateTime> days) => {
      for (final d in days)
        d.atMidnight.dayKey: Completion(date: d.atMidnight.dayKey, count: 1),
    };

Habit _habit({
  required HabitInterval interval,
  List<int> weekdays = const [],
  int every = 2,
  required DateTime createdAt,
  Map<String, Completion> completions = const {},
}) =>
    Habit(
      id: 'h',
      name: 'Test',
      color: const Color(0xFF00FF00),
      order: 0,
      interval: interval,
      scheduleWeekdays: weekdays,
      scheduleEvery: every,
      createdAt: createdAt,
      completions: completions,
    );

void main() {
  group('everyXDays scheduling', () {
    test('isScheduledOn matches the cadence from createdAt', () {
      final h = _habit(
        interval: HabitInterval.everyXDays,
        every: 3,
        createdAt: _ago(6),
      );
      expect(h.isScheduledOn(_ago(6)), isTrue); // diff 0
      expect(h.isScheduledOn(_ago(5)), isFalse);
      expect(h.isScheduledOn(_ago(3)), isTrue); // diff 3
      expect(h.isScheduledOn(_ago(0)), isTrue); // diff 6
    });

    test('streak counts scheduled completions, skips off days', () {
      // every 2 days from 6 days ago → due on -6,-4,-2,0. Done on -6,-4,-2.
      final h = _habit(
        interval: HabitInterval.everyXDays,
        every: 2,
        createdAt: _ago(6),
        completions: _done([_ago(6), _ago(4), _ago(2)]),
      );
      // Today is due but not done → grace; the three past due days give 3.
      expect(h.currentStreak, 3);
    });

    test('completing today extends the streak', () {
      final h = _habit(
        interval: HabitInterval.everyXDays,
        every: 2,
        createdAt: _ago(6),
        completions: _done([_ago(6), _ago(4), _ago(2), _ago(0)]),
      );
      expect(h.currentStreak, 4);
    });

    test('a missed scheduled day breaks the streak', () {
      // Skip -4 (a due day). Walk back: 0 grace, -2 done(+1), -4 missed → stop.
      final h = _habit(
        interval: HabitInterval.everyXDays,
        every: 2,
        createdAt: _ago(6),
        completions: _done([_ago(6), _ago(2)]),
      );
      expect(h.currentStreak, 1);
    });

    test('isDoneForNow is true when today is not a scheduled day', () {
      // due on even offsets; yesterday-anchored so today (diff 1) is off.
      final h = _habit(
        interval: HabitInterval.everyXDays,
        every: 2,
        createdAt: _ago(1),
      );
      expect(h.isScheduledOn(_today()), isFalse);
      expect(h.isDoneForNow, isTrue);
    });
  });

  group('done for now', () {
    test('a weekly habit is settled once it is ticked today', () {
      final pending = _habit(
        interval: HabitInterval.weekly,
        createdAt: _ago(30),
      );
      final ticked = _habit(
        interval: HabitInterval.weekly,
        createdAt: _ago(30),
        completions: _done([_ago(0)]),
      );

      expect(pending.isDoneForNow, isFalse);
      expect(ticked.isDoneForNow, isTrue);
    });

    test('a rest day is settled without ticking it', () {
      final h = Habit(
        id: 'h',
        name: 'Test',
        color: const Color(0xFF00FF00),
        order: 0,
        createdAt: _ago(30),
        restDays: [_today().weekday],
      );

      expect(h.isDoneForNow, isTrue);
    });
  });

  group('weekdays scheduling', () {
    test('isScheduledOn only on the selected weekdays', () {
      final h = _habit(
        interval: HabitInterval.weekdays,
        weekdays: const [1, 3, 5], // Mon, Wed, Fri
        createdAt: _ago(30),
      );
      for (final d in [_ago(0), _ago(1), _ago(2), _ago(3), _ago(4), _ago(5)]) {
        expect(h.isScheduledOn(d), const [1, 3, 5].contains(d.weekday));
      }
    });

    test('streak walks weekly scheduled days, skipping off days', () {
      // Only today's weekday is scheduled → one due day per week.
      final wd = _today().weekday;
      final h = _habit(
        interval: HabitInterval.weekdays,
        weekdays: [wd],
        createdAt: _ago(21),
        completions: _done([_ago(0), _ago(7), _ago(14)]),
      );
      // today, -7, -14 all done and scheduled; -21 (createdAt) due but missed.
      expect(h.currentStreak, 3);
    });

    test('a missed scheduled week breaks it', () {
      final wd = _today().weekday;
      final h = _habit(
        interval: HabitInterval.weekdays,
        weekdays: [wd],
        createdAt: _ago(21),
        completions: _done([_ago(0), _ago(7)]), // -14 missed
      );
      expect(h.currentStreak, 2);
    });

    test('longestStreak ignores non-scheduled days', () {
      final wd = _today().weekday;
      final h = _habit(
        interval: HabitInterval.weekdays,
        weekdays: [wd],
        createdAt: _ago(21),
        completions: _done([_ago(21), _ago(14), _ago(7)]), // 3 in a row, not today
      );
      expect(h.longestStreak, 3);
    });
  });

  test('round-trips through toMap/fromMap', () {
    final h = _habit(
      interval: HabitInterval.weekdays,
      weekdays: const [2, 4],
      every: 5,
      createdAt: _ago(3),
      completions: _done([_ago(3)]),
    );
    final back = Habit.fromMap(h.toMap());
    expect(back.interval, HabitInterval.weekdays);
    expect(back.scheduleWeekdays, const [2, 4]);
    expect(back.scheduleEvery, 5);
  });

  group('archive', () {
    test('a fresh habit is not archived and survives a round trip', () {
      final habit = _habit(interval: HabitInterval.daily, createdAt: _ago(2));
      expect(habit.isArchived, isFalse);
      expect(Habit.fromMap(habit.toMap()).isArchived, isFalse);
    });

    test('archivedAt round-trips and clearArchived restores', () {
      final stamp = DateTime(2026, 3, 14, 9, 30);
      final archived =
          _habit(interval: HabitInterval.daily, createdAt: _ago(2))
              .copyWith(archivedAt: stamp);
      final back = Habit.fromMap(archived.toMap());
      expect(back.isArchived, isTrue);
      expect(back.archivedAt, stamp);
      expect(back.copyWith(clearArchived: true).isArchived, isFalse);
    });
  });

  group('day cutoff', () {
    tearDown(() => AppClock.cutoffHour = 0);

    test('with no cutoff the logical day is the calendar day', () {
      AppClock.cutoffHour = 0;
      expect(AppClock.today(), DateTime.now().atMidnight);
    });

    test('a cutoff shifts the logical day back by that many hours', () {
      AppClock.cutoffHour = 3;
      final expected =
          DateTime.now().subtract(const Duration(hours: 3)).atMidnight;
      expect(AppClock.today(), expected);
    });
  });
}
