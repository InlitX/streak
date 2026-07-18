import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/i18n/app_strings.dart';
import 'package:streak/features/habits/data/habit.dart';

// e.g. "Daily", "5×/week", "3×/month".
String habitFrequencyLabel(BuildContext context, Habit habit) {
  return switch (habit.interval) {
    HabitInterval.daily => context.tr('daily'),
    HabitInterval.weekly =>
      context.tr('freq_per_week_short', {'n': '${habit.targetFrequency}'}),
    HabitInterval.monthly =>
      context.tr('freq_per_month_short', {'n': '${habit.targetFrequency}'}),
  };
}

bool habitHasExplicitFrequency(Habit habit) =>
    habit.interval != HabitInterval.daily;

class FrequencyChip extends StatelessWidget {
  const FrequencyChip({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final c = habit.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.repeat, size: 13, color: c),
          const SizedBox(width: 5),
          Text(
            habitFrequencyLabel(context, habit),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}
