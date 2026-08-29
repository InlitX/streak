import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/services/focus_service.dart';

import 'support/app_harness.dart';

FocusController _controller() {
  final controller = FocusController();
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  useEmptyStore();

  group('coming back to a saved session', () {
    Future<void> save({
      required int acc,
      required String since,
      bool open = true,
    }) =>
        LocalStore.writeSetting('focusActive', {
          'habitId': 'h1',
          'target': 25,
          'focus': 25,
          'break': 0,
          'isBreak': false,
          'round': 1,
          'acc': acc,
          'since': since,
          'open': open,
        });

    test('one that was left paused at zero is dropped, not restored', () async {
      await save(acc: 0, since: '');
      expect(_controller().isActive, isFalse);
    });

    test('one with time on the clock is restored', () async {
      await save(acc: 300, since: '');
      final focus = _controller();
      expect(focus.isActive, isTrue);
      expect(focus.elapsedSeconds, 300);
    });

    test('one still running is restored', () async {
      await save(acc: 0, since: DateTime.now().toIso8601String());
      expect(_controller().isActive, isTrue);
    });

    test('a dropped one does not block starting another habit', () async {
      await save(acc: 0, since: '');
      final focus = _controller();
      expect(focus.isActive, isFalse);

      focus.start(habitId: 'h2', targetMinutes: 45);
      expect(focus.isActive, isTrue);
      expect(focus.habitId, 'h2');
      expect(focus.targetSeconds, 2700);
    });
  });

  group('countdown', () {
    test('a timed session keeps its target and counts down', () {
      final focus = _controller();
      focus.start(habitId: '', targetMinutes: 25);

      expect(focus.isFlow, isFalse);
      expect(focus.targetSeconds, 1500);
      expect(focus.remainingSeconds, 1500);
      expect(focus.displaySeconds, focus.remainingSeconds);
      expect(focus.reachedTarget, isFalse);
      expect(focus.progress, 0);
    });

    test('pomodoro still turns on for a timed session', () {
      final focus = _controller();
      focus.start(habitId: '', targetMinutes: 25, breakMinutes: 5);

      expect(focus.isPomodoro, isTrue);
    });
  });

  group('flowtime', () {
    test('it has no target and does not complete on its own', () {
      final focus = _controller();
      focus.start(habitId: '', targetMinutes: 0);

      expect(focus.isFlow, isTrue);
      expect(focus.targetSeconds, 0);
      expect(focus.remainingSeconds, 0);
      expect(focus.reachedTarget, isFalse);
    });

    test('the clock counts up instead of down', () {
      final focus = _controller();
      focus.start(habitId: '', targetMinutes: 0);

      expect(focus.displaySeconds, focus.elapsedSeconds);
      expect(focus.progress, isNot(isNaN));
      expect(focus.progress, inInclusiveRange(0, 1));
    });

    test('pomodoro is refused because there is nothing to break from', () {
      final focus = _controller();
      focus.start(habitId: '', targetMinutes: 0, breakMinutes: 5);

      expect(focus.isPomodoro, isFalse);
    });

    test('a session shorter than 30 seconds is not saved', () async {
      final focus = _controller();
      focus.start(habitId: '', targetMinutes: 0);

      expect(await focus.stop(completed: true), isNull);
      expect(focus.isActive, isFalse);
    });
  });

  group('outliving the process', () {
    Future<void> seedRunning({
      required int targetMinutes,
      required Duration ago,
      int breakMinutes = 0,
    }) async {
      await LocalStore.writeSetting('focusActive', {
        'habitId': 'read',
        'target': targetMinutes,
        'focus': targetMinutes,
        'break': breakMinutes,
        'isBreak': false,
        'round': 1,
        'acc': 0,
        'since': DateTime.now().subtract(ago).toIso8601String(),
        'open': true,
      });
      await coldStart();
    }

    test('a running session is still there after a cold start', () async {
      final before = _controller();
      before.start(habitId: 'read', targetMinutes: 25);
      await coldStart();

      final after = _controller();
      expect(after.isActive, isTrue);
      expect(after.isRunning, isTrue);
      expect(after.habitId, 'read');
      expect(after.targetMinutes, 25);
    });

    test('a countdown that ran out while away banks its target, not the gap',
        () async {
      await seedRunning(targetMinutes: 25, ago: const Duration(hours: 3));

      final focus = _controller();
      expect(focus.elapsedSeconds, 1500);
      expect(focus.remainingSeconds, 0);
      expect(focus.reachedTarget, isTrue);

      final session = await focus.stop(completed: true);
      expect(session!.seconds, 1500);
    });

    test('a session paused before the process died comes back paused',
        () async {
      await LocalStore.writeSetting('focusActive', {
        'habitId': 'read',
        'target': 25,
        'focus': 25,
        'break': 0,
        'isBreak': false,
        'round': 1,
        'acc': 300,
        'since': '',
        'open': true,
      });
      await coldStart();

      final focus = _controller();
      expect(focus.isActive, isTrue);
      expect(focus.isRunning, isFalse);
      expect(focus.elapsedSeconds, 300);
    });

    test('flowtime keeps every minute it was away', () async {
      await seedRunning(targetMinutes: 0, ago: const Duration(hours: 3));

      final focus = _controller();
      expect(focus.isFlow, isTrue);
      expect(focus.elapsedSeconds, closeTo(10800, 5));
    });

    test('stopping from the notification banks up to the moment it was pressed',
        () async {
      await seedRunning(targetMinutes: 60, ago: const Duration(minutes: 30));

      final focus = _controller();
      final session = await focus.apply(
        FocusAction(
          kind: FocusAction.stop,
          at: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
      );

      expect(session!.seconds, closeTo(600, 5));
      expect(focus.isActive, isFalse);
    });

    test('pausing from the notification drops the time it was left alone',
        () async {
      await seedRunning(targetMinutes: 60, ago: const Duration(minutes: 30));

      final focus = _controller();
      await focus.apply(
        FocusAction(
          kind: FocusAction.pause,
          at: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
      );

      expect(focus.isRunning, isFalse);
      expect(focus.elapsedSeconds, closeTo(300, 5));
    });
  });

  group('what the focus screen remembers', () {
    test('a free session starts with the last setup, not with 25', () async {
      var settings = SettingsController();
      expect(settings.focusMinutes, 25);
      expect(settings.focusBreakMinutes, 0);

      await settings.rememberFocusSetup(50, 10);
      await coldStart();

      settings = SettingsController();
      expect(settings.focusMinutes, 50);
      expect(settings.focusBreakMinutes, 10);
    });

    test('turning pomodoro off is remembered too', () async {
      var settings = SettingsController();
      await settings.rememberFocusSetup(50, 10);
      await settings.rememberFocusSetup(30, 0);
      await coldStart();

      settings = SettingsController();
      expect(settings.focusMinutes, 30);
      expect(settings.focusBreakMinutes, 0);
    });

    test('the track survives a cold start, and stopping forgets it', () async {
      var settings = SettingsController();
      expect(settings.focusTrack, '');

      await settings.setFocusTrack('rain');
      await coldStart();

      settings = SettingsController();
      expect(settings.focusTrack, 'rain');

      await settings.setFocusTrack('');
      await coldStart();

      settings = SettingsController();
      expect(settings.focusTrack, '');
    });
  });
}
