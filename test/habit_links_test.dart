import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/habit_links.dart';

import 'support/app_harness.dart';

String _iso(DateTime day) => day.toIso8601String().substring(0, 10);

Habit _with(Habit habit, Uri link) =>
    habit.copyWith(completions: HabitLinks.apply(habit, link));

void main() {
  final today = AppClock.today();
  final run = testHabit(id: 'run', name: 'Run');
  final water = testHabit(
    id: 'water',
    name: 'Water',
    kind: HabitKind.quantitative,
    perDayTarget: 8,
  ).copyWith(incrementAmount: 2);
  final smoke = testHabit(id: 'smoke', name: 'Smoke', kind: HabitKind.negative);

  test('done marks today and a second done changes nothing', () {
    final done = _with(run, Uri.parse(HabitLinks.done(run)));
    expect(done.isCompletedOn(today), isTrue);
    expect(HabitLinks.apply(done, Uri.parse(HabitLinks.done(done))), isNull);
  });

  test('undo clears the day and does nothing on an empty day', () {
    final done = _with(run, Uri.parse(HabitLinks.done(run)));
    final undone = _with(done, Uri.parse(HabitLinks.undo(done)));
    expect(undone.completions.containsKey(today.dayKey), isFalse);
    expect(HabitLinks.apply(undone, Uri.parse(HabitLinks.undo(undone))), isNull);
  });

  test('add sums the amount of the link, or the habit step without one', () {
    final once = _with(water, Uri.parse(HabitLinks.add(water)));
    expect(once.completions[today.dayKey]?.count, 2);
    final more = _with(once, Uri.parse('streak://add?habit=water&amount=3.5'));
    expect(more.completions[today.dayKey]?.count, 5.5);
    final step = _with(more, Uri.parse('streak://add?habit=water'));
    expect(step.completions[today.dayKey]?.count, 7.5);
  });

  test('done fills an amount habit up to its goal', () {
    final done = _with(water, Uri.parse(HabitLinks.done(water)));
    expect(done.completions[today.dayKey]?.count, 8);
  });

  test('relapse only works on habits to avoid, and adds up', () {
    expect(HabitLinks.apply(run, Uri.parse('streak://relapse?habit=run')), isNull);
    final once = _with(smoke, Uri.parse(HabitLinks.relapse(smoke)));
    final twice = _with(once, Uri.parse(HabitLinks.relapse(once)));
    expect(twice.completions[today.dayKey]?.count, 2);
    expect(HabitLinks.apply(smoke, Uri.parse(HabitLinks.done(smoke))), isNull);
  });

  test('a past day can be marked, a future or broken one cannot', () {
    final past = today.addDays(-3);
    final marked =
        _with(run, Uri.parse('${HabitLinks.done(run)}&day=${_iso(past)}'));
    expect(marked.isCompletedOn(past), isTrue);
    final ahead = _iso(today.addDays(2));
    expect(HabitLinks.apply(run, Uri.parse('${HabitLinks.done(run)}&day=$ahead')), isNull);
    expect(HabitLinks.apply(run, Uri.parse('${HabitLinks.done(run)}&day=31-10-2026')), isNull);
  });

  test('habits that need a focus session or are archived are left alone', () {
    final focus = testHabit(id: 'read', name: 'Read', focusOnly: true);
    expect(HabitLinks.apply(focus, Uri.parse(HabitLinks.done(focus))), isNull);
    final archived = run.copyWith(archivedAt: DateTime.now());
    expect(HabitLinks.apply(archived, Uri.parse(HabitLinks.done(archived))), isNull);
  });
}
