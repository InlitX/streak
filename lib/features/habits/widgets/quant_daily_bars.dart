import 'package:flutter/material.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/statistics/widgets/stat_charts.dart';

class QuantDailyBars extends StatelessWidget {
  const QuantDailyBars({super.key, required this.habit, this.days = 14});

  final Habit habit;
  final int days;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final dates = [
      for (var i = days - 1; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final unit = habit.unitLabel.isEmpty ? '' : ' ${habit.unitLabel}';

    return ValueBars(
      values: [
        for (final date in dates) habit.completions[date.dayKey]?.count ?? 0,
      ],
      color: habit.color,
      height: 130,
      label: (index) => index >= 0 && index < dates.length
          ? '${dates[index].day}'
          : '',
      tooltip: (value) => '${formatAmount(value)}$unit',
    );
  }
}
