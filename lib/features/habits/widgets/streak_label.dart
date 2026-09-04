import 'package:flutter/widgets.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';

String streakLabel(BuildContext context, Habit habit) {
  final value = '${habit.currentStreak}';
  return switch (habit.interval) {
    HabitInterval.weekly => context.l10n.streak_unit_week(value),
    HabitInterval.monthly => context.l10n.streak_unit_month(value),
    _ => value,
  };
}
