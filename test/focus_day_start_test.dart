import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/state/focus_controller.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  tearDown(() => AppClock.cutoffHour = 0);

  test('a session after midnight counts for the day before when the day starts later',
      () async {
    AppClock.cutoffHour = 5;
    final focus = FocusController();
    addTearDown(focus.dispose);
    final day = DateTime(2026, 11, 20);
    await focus.addSession(
      habitId: 'read',
      startedAt: DateTime(2026, 11, 21, 1, 30),
      minutes: 20,
    );

    expect(focus.secondsForDay(day), 1200);
    expect(focus.secondsForDay(day.addDays(1)), 0);
    expect(focus.secondsForHabitSince('read', day), 1200);
    expect(focus.secondsForHabitSince('read', day.addDays(1)), 0);
  });
}
