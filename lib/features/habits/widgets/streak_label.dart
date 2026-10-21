import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/check_history.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';

IconData habitMarkIcon(Habit habit) =>
    habit.tracking ? LucideIcons.hash : LucideIcons.flame;

String habitMarkLabel(BuildContext context, Habit habit, HeatmapMode mode) {
  if (habit.tracking) return trackedLabel(context, habit, mode);
  if (habit.hasCleanGoal && habit.currentStreak < habit.cleanGoal) {
    return '${habit.currentStreak}/${habit.cleanGoal}';
  }
  return streakLabel(context, habit);
}

String trackedLabel(BuildContext context, Habit habit, HeatmapMode mode) {
  final (_, count) = periodTotal(context, habit, mode);
  return switch (mode) {
    HeatmapMode.week => context.l10n.tracked_week(count),
    HeatmapMode.year => context.l10n.tracked_year(count),
    _ => context.l10n.tracked_month(count),
  };
}

String streakLabel(BuildContext context, Habit habit) {
  final value = '${habit.currentStreak}';
  return switch (habit.interval) {
    HabitInterval.weekly => context.l10n.streak_unit_week(value),
    HabitInterval.monthly => context.l10n.streak_unit_month(value),
    _ => value,
  };
}
