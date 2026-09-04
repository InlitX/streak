import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/widgets/express_line_chart.dart';
import 'package:streak/features/statistics/widgets/stat_line_charts.dart';

class QuantDailyBars extends StatelessWidget {
  const QuantDailyBars({super.key, required this.habit, this.days = 14});

  final Habit habit;
  final int days;

  @override
  Widget build(BuildContext context) {
    final express = context.watch<SettingsController>().isExpressStyle;
    final span = express ? 30 : days;
    final today = AppClock.now().atMidnight;
    final start = today.addDays(-(span - 1));
    final unit = habit.isTimeAmount || habit.unitLabel.isEmpty
        ? ''
        : ' ${habit.unitLabel}';
    final amounts = [
      for (var i = 0; i < span; i++)
        habit.completions[start.addDays(i).dayKey]?.count ?? 0,
    ];
    String label(double value) => '${habit.amountText(value)}$unit';
    String axis(double value) => habit.amountText(value);

    if (express) {
      final month = DateFormat.MMM(Localizations.localeOf(context).toString());
      return ExpressLineChart(
        values: amounts,
        color: habit.color,
        window: 10,
        height: 176,
        goal: habit.perDayTarget,
        format: label,
        axisFormat: axis,
        label: (index) => '${start.addDays(index).day}',
        subLabel: (index) {
          final day = start.addDays(index);
          return day.day == 1 || index == 0 ? month.format(day) : null;
        },
      );
    }

    return TrendChart(
      values: amounts,
      color: habit.color,
      startDate: start,
      height: 132,
      goal: habit.perDayTarget,
      format: label,
      axisFormat: axis,
    );
  }
}
