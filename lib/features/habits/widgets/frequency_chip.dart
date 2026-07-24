import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';

String habitFrequencyLabel(BuildContext context, Habit habit) {
  return switch (habit.interval) {
    HabitInterval.daily => context.l10n.daily,
    HabitInterval.weekly =>
      context.l10n.freq_per_week_short('${habit.targetFrequency}'),
    HabitInterval.monthly =>
      context.l10n.freq_per_month_short('${habit.targetFrequency}'),
    HabitInterval.weekdays => _weekdaysLabel(context, habit),
    HabitInterval.everyXDays => context.l10n.every_n_days(habit.scheduleEvery),
  };
}

String _weekdaysLabel(BuildContext context, Habit habit) {
  final days = [...habit.scheduleWeekdays]..sort();
  if (days.isEmpty) return context.l10n.daily;
  if (days.length == 7) return context.l10n.every_day;
  final names = WeekdayLabels.shortMonFirst(
    Localizations.localeOf(context).languageCode,
  );
  return days.map((d) => names[d - 1]).join(', ');
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
