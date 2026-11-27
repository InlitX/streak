import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/scale_faces.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/widgets/express_line_chart.dart';
import 'package:streak/features/statistics/widgets/stat_line_charts.dart';
import 'package:streak/core/extensions/color_extensions.dart';

class QuantDailyBars extends StatelessWidget {
  const QuantDailyBars({super.key, required this.habit, this.days = 14});

  final Habit habit;
  final int days;

  @override
  Widget build(BuildContext context) {
    if (habit.isScale) return ScaleChart(habit: habit);
    final express = context.watch<SettingsController>().isExpressStyle;
    final span = express ? 30 : days;
    final today = AppClock.today();
    final start = today.addDays(-(span - 1));
    final unit = habit.isTimeAmount || habit.unitLabel.isEmpty
        ? ''
        : ' ${habit.unitLabel}';
    final dates = _sparseDays(today, span) ??
        [for (var i = 0; i < span; i++) start.addDays(i)];
    final amounts = [
      for (final day in dates) habit.completions[day.dayKey]?.count ?? 0,
    ];
    String label(double value) => '${habit.amountText(value)}$unit';
    String axis(double value) => habit.amountText(value);

    if (express) {
      final month = DateFormat.MMM(Localizations.localeOf(context).toString());
      return ExpressLineChart(
        values: amounts,
        color: habit.color.shownIn(context),
        window: 10,
        height: 176,
        goal: habit.hasGoal ? habit.perDayTarget : null,
        format: label,
        axisFormat: axis,
        label: (index) => '${dates[index].day}',
        subLabel: (index) {
          final day = dates[index];
          return index == 0 || day.month != dates[index - 1].month
              ? month.format(day)
              : null;
        },
      );
    }

    return TrendChart(
      values: amounts,
      color: habit.color.shownIn(context),
      startDate: dates.first,
      dates: dates,
      height: 132,
      goal: habit.hasGoal ? habit.perDayTarget : null,
      format: label,
      axisFormat: axis,
    );
  }

  List<DateTime>? _sparseDays(DateTime today, int span) {
    final sparse = switch (habit.interval) {
      HabitInterval.weekdays => habit.scheduleWeekdays.length < 7,
      HabitInterval.everyXDays => true,
      _ => false,
    };
    if (!sparse) return null;
    final first = habit.createdAt.atMidnight;
    final days = <DateTime>[];
    for (var back = 0; back < 366 && days.length < span; back++) {
      final day = today.addDays(-back);
      if (day.isBefore(first)) break;
      final logged = (habit.completions[day.dayKey]?.count ?? 0) > 0;
      if (logged || habit.isScheduledOn(day)) days.add(day);
    }
    return days.length < 2 ? null : days.reversed.toList();
  }
}
