import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/services/focus_service.dart';

Future<void> applyFocusAction(FocusAction action) async {
  final context = AppNavigator.key.currentContext;
  if (context == null) return;

  final focus = context.read<FocusController>();
  if (!focus.isActive) return;

  final habits = context.read<HabitsController>();
  final habitId = focus.habitId;
  final session = await focus.apply(action);
  if (session == null || habitId.isEmpty) return;

  final habit = habits.byId(habitId);
  if (habit == null) return;

  final today = AppClock.now();
  if (habit.isTimeAmount) {
    await habits.addProgress(habit.id, today, session.seconds / 60);
    return;
  }

  if (!session.completed || habit.kind != HabitKind.positive) return;
  if (habit.isCompletedOn(today)) return;
  habits.toggle(habit.id, today, fromFocus: true);
}

Future<void> drainFocusActions() async {
  for (final action in await FocusService.drain()) {
    await applyFocusAction(action);
  }
}
