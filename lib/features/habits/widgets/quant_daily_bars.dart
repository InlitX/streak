import 'package:flutter/material.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/statistics/widgets/stat_line_charts.dart';

class QuantDailyBars extends StatelessWidget {
  const QuantDailyBars({super.key, required this.habit, this.days = 14});

  final Habit habit;
  final int days;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final start = today.subtract(Duration(days: days - 1));
    final unit = habit.isTimeAmount || habit.unitLabel.isEmpty
        ? ''
        : ' ${habit.unitLabel}';

    return TrendChart(
      values: [
        for (var i = 0; i < days; i++)
          habit.completions[start.add(Duration(days: i)).dayKey]?.count ?? 0,
      ],
      color: habit.color,
      startDate: start,
      height: 132,
      goal: habit.perDayTarget,
      format: (value) => '${habit.amountText(value)}$unit',
    );
  }
}
