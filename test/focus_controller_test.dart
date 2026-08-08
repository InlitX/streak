import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/focus/state/focus_controller.dart';

import 'support/app_harness.dart';

FocusController _controller() {
  final controller = FocusController();
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  useEmptyStore();

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
}
