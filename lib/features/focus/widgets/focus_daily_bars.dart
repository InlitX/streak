import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/statistics/widgets/stat_line_charts.dart';

class FocusDailyBars extends StatelessWidget {
  const FocusDailyBars({super.key, required this.habit, this.days = 14});

  final Habit habit;
  final int days;

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    final today = AppClock.now().atMidnight;
    final start = today.subtract(Duration(days: days - 1));

    return TrendChart(
      values: [
        for (var i = 0; i < days; i++)
          focus.secondsForHabitOnDay(habit.id, start.add(Duration(days: i))) /
              60,
      ],
      color: habit.color,
      startDate: start,
      height: 132,
      format: (value) => formatHoursShort((value * 60).round()),
    );
  }
}
