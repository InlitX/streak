import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/data/vacation.dart';

Habit _base({
  List<Substep> substeps = const [],
  List<VacationPeriod> vacations = const [],
  Map<String, Completion> completions = const {},
  HabitKind kind = HabitKind.positive,
  DateTime? createdAt,
}) =>
    Habit(
      id: 'h',
      name: 'Test',
      color: const Color(0xFF00FF00),
      order: 0,
      kind: kind,
      substeps: substeps,
      vacations: vacations,
      completions: completions,
      createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 30)),
    );

void main() {
  final today = DateTime.now();
  final steps = [
    const Substep(id: 's1', title: 'Wash face'),
    const Substep(id: 's2', title: 'Brush teeth'),
  ];

  group('substeps', () {
    test('not complete until every step is checked', () {
      var habit = _base(substeps: steps);
      var completions = CompletionOps.setStep(habit, today, 's1', true);
      habit = habit.copyWith(completions: completions);
      expect(habit.isCompletedOn(today), isFalse);

      completions = CompletionOps.setStep(habit, today, 's2', true);
      habit = habit.copyWith(completions: completions);
      expect(habit.isCompletedOn(today), isTrue);
    });

    test('count mirrors number of checked steps', () {
      final habit = _base(substeps: steps);
      final completions = CompletionOps.setStep(habit, today, 's1', true);
      expect(completions[today.dayKey]!.count, 1);
      expect(completions[today.dayKey]!.steps, {'s1'});
    });

    test('unchecking the last step clears the day', () {
      var habit = _base(substeps: steps);
      var completions = CompletionOps.setStep(habit, today, 's1', true);
      habit = habit.copyWith(completions: completions);
      completions = CompletionOps.setStep(habit, today, 's1', false);
      expect(completions.containsKey(today.dayKey), isFalse);
    });

    test('toggle checks then clears all steps', () {
      var habit = _base(substeps: steps);
      var completions = CompletionOps.toggle(habit, today);
      habit = habit.copyWith(completions: completions);
      expect(habit.isCompletedOn(today), isTrue);
      completions = CompletionOps.toggle(habit, today);
      expect(completions.containsKey(today.dayKey), isFalse);
    });

    test('totalCompletions only counts fully-checked days', () {
      var habit = _base(substeps: steps);
      final yesterday = today.subtract(const Duration(days: 1));
      var completions = CompletionOps.setStep(habit, today, 's1', true);
      habit = habit.copyWith(completions: completions);
      completions = CompletionOps.setStep(habit, yesterday, 's1', true);
      habit = habit.copyWith(completions: completions);
      completions = CompletionOps.setStep(habit, yesterday, 's2', true);
      habit = habit.copyWith(completions: completions);
      expect(habit.totalCompletions, 1);
    });

    test('serialization round-trips substeps and steps', () {
      var habit = _base(substeps: steps);
      final completions = CompletionOps.setStep(habit, today, 's1', true);
      habit = habit.copyWith(completions: completions);
      final restored = Habit.fromJson(habit.toJson());
      expect(restored.substeps.map((s) => s.id), ['s1', 's2']);
      expect(restored.completions[today.dayKey]!.steps, {'s1'});
    });
  });

  group('vacation', () {
    Map<String, Completion> completed(List<DateTime> days) => {
          for (final d in days)
            d.dayKey: Completion(date: d.dayKey, hour: 8),
        };

    test('paused days do not break the daily streak', () {
      final done = [today, today.subtract(const Duration(days: 4))];
      final vac = VacationPeriod(
        start: today.subtract(const Duration(days: 3)),
        end: today.subtract(const Duration(days: 1)),
      );
      final habit = _base(completions: completed(done), vacations: [vac]);
      expect(habit.currentStreak, 2);
    });

    test('without vacation the same gap breaks the streak', () {
      final done = [today, today.subtract(const Duration(days: 4))];
      final habit = _base(completions: completed(done));
      expect(habit.currentStreak, 1);
    });

    test('isPausedOn / isNeutralOn respect logged days', () {
      final vac = VacationPeriod(
        start: today.subtract(const Duration(days: 3)),
        end: today.subtract(const Duration(days: 1)),
      );
      final loggedDay = today.subtract(const Duration(days: 2));
      final habit =
          _base(completions: completed([loggedDay]), vacations: [vac]);
      expect(habit.isPausedOn(loggedDay), isTrue);
      expect(habit.isNeutralOn(loggedDay), isFalse);
      expect(
        habit.isNeutralOn(today.subtract(const Duration(days: 3))),
        isTrue,
      );
    });

    test('open period pauses through today', () {
      final vac = VacationPeriod(start: today.subtract(const Duration(days: 2)));
      final habit = _base(vacations: [vac]);
      expect(habit.isOnVacation, isTrue);
      expect(habit.isPausedOn(today), isTrue);
      expect(
        habit.isPausedOn(today.add(const Duration(days: 1))),
        isFalse,
      );
    });

    test('vacation round-trips through serialization', () {
      final vac = VacationPeriod(
        start: today.subtract(const Duration(days: 3)),
        end: today.subtract(const Duration(days: 1)),
      );
      final habit = _base(vacations: [vac]);
      final restored = Habit.fromJson(habit.toJson());
      expect(restored.vacations.length, 1);
      expect(restored.isOnVacation, isFalse);
    });
  });

  group('back-filling past days', () {
    test('a day logged before createdAt still counts as completed', () {
      final yesterday = today.subtract(const Duration(days: 1));
      var habit = _base(createdAt: today);
      expect(habit.isCompletedOn(yesterday), isFalse);

      habit = habit.copyWith(completions: CompletionOps.toggle(habit, yesterday));
      expect(habit.isCompletedOn(yesterday), isTrue);
    });

    test('a back-filled day can be unchecked again', () {
      final yesterday = today.subtract(const Duration(days: 1));
      var habit = _base(createdAt: today);

      habit = habit.copyWith(completions: CompletionOps.toggle(habit, yesterday));
      expect(habit.completions.containsKey(yesterday.dayKey), isTrue);

      habit = habit.copyWith(completions: CompletionOps.toggle(habit, yesterday));
      expect(habit.completions.containsKey(yesterday.dayKey), isFalse);
    });

    test('a weekly habit can undo a past day of the week', () {
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      var habit = Habit(
        id: 'w',
        name: 'Weekly',
        color: const Color(0xFF00FF00),
        order: 0,
        interval: HabitInterval.weekly,
        targetFrequency: 3,
        createdAt: today,
      );

      habit = habit.copyWith(completions: CompletionOps.toggle(habit, twoDaysAgo));
      expect(habit.isCompletedOn(twoDaysAgo), isTrue);

      habit = habit.copyWith(completions: CompletionOps.toggle(habit, twoDaysAgo));
      expect(habit.isCompletedOn(twoDaysAgo), isFalse);
      expect(habit.completions, isEmpty);
    });

    test('a past day amount can be raised and cleared again', () {
      final wednesday = today.subtract(const Duration(days: 3));
      var habit = _base(kind: HabitKind.quantitative, createdAt: today)
          .copyWith(perDayTarget: 2);

      habit = habit.copyWith(
        completions: CompletionOps.addProgress(habit, wednesday, 1),
      );
      expect(habit.completions[wednesday.dayKey]?.count, 1);
      expect(habit.isCompletedOn(wednesday), isFalse);

      habit = habit.copyWith(
        completions: CompletionOps.addProgress(habit, wednesday, 1),
      );
      expect(habit.isCompletedOn(wednesday), isTrue);

      final current = habit.completions[wednesday.dayKey]!.count;
      habit = habit.copyWith(
        completions: CompletionOps.addProgress(habit, wednesday, -current),
      );
      expect(habit.completions.containsKey(wednesday.dayKey), isFalse);
    });

    test('negatives stay clean-by-default only from createdAt', () {
      final yesterday = today.subtract(const Duration(days: 1));
      final habit = _base(kind: HabitKind.negative, createdAt: today);
      expect(habit.isCompletedOn(yesterday), isFalse);
      expect(habit.isCompletedOn(today), isTrue);
    });

    test('tapping a clean negative logs the relapse, and back again', () {
      final habit = _base(kind: HabitKind.negative, createdAt: today);

      final relapsed = CompletionOps.toggle(habit, today);
      expect(habit.copyWith(completions: relapsed).isCompletedOn(today), isFalse);

      final clean = CompletionOps.toggle(
        habit.copyWith(completions: relapsed),
        today,
      );
      expect(clean.containsKey(today.dayKey), isFalse);
    });

    test('tapping a negative before it existed records nothing', () {
      final before = today.subtract(const Duration(days: 40));
      final habit = _base(kind: HabitKind.negative, createdAt: today);

      final tapped = CompletionOps.toggle(habit, before);
      expect(tapped.containsKey(before.dayKey), isFalse);

      final again = CompletionOps.toggle(
        habit.copyWith(completions: tapped),
        before,
      );
      expect(again.containsKey(before.dayKey), isFalse);
    });

    test('a relapse mistakenly stored before createdAt can be tapped away', () {
      final before = today.subtract(const Duration(days: 40));
      final habit = _base(
        kind: HabitKind.negative,
        createdAt: today,
        completions: {
          before.dayKey: Completion(date: before.dayKey, count: 1, hour: 9),
        },
      );

      expect(
        CompletionOps.toggle(habit, before).containsKey(before.dayKey),
        isFalse,
      );
    });
  });

  group('focus only', () {
    test('a manual check is blocked, a focus one is not', () {
      final habit = _base().copyWith(focusOnly: true);
      expect(habit.blocksManualCheck(today), isTrue);
      expect(habit.blocksManualCheck(today, fromFocus: true), isFalse);
    });

    test('an already completed day can still be undone', () {
      var habit = _base().copyWith(focusOnly: true);
      habit = habit.copyWith(completions: CompletionOps.toggle(habit, today));
      expect(habit.isCompletedOn(today), isTrue);
      expect(habit.blocksManualCheck(today), isFalse);
    });

    test('past days are blocked too', () {
      final habit = _base().copyWith(focusOnly: true);
      expect(
        habit.blocksManualCheck(today.subtract(const Duration(days: 3))),
        isTrue,
      );
    });

    test('it does not apply to checklists or to other kinds', () {
      final checklist = _base(substeps: steps).copyWith(focusOnly: true);
      expect(checklist.blocksManualCheck(today), isFalse);

      final quantitative =
          _base(kind: HabitKind.quantitative).copyWith(focusOnly: true);
      expect(quantitative.blocksManualCheck(today), isFalse);
    });
  });
}
