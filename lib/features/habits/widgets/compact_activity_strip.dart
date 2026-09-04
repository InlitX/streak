import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';

class CompactActivityStrip extends StatelessWidget {
  const CompactActivityStrip({
    super.key,
    required this.habit,
    required this.mode,
  });

  final Habit habit;
  final HeatmapMode mode;

  List<Color> _monthCells(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final floor = habit.startedAt;
    final base = context.colors.surfaceContainerHighest;
    final dim = base.withValues(alpha: 0.4);
    final negative = habit.kind == HabitKind.negative;

    final logged = List<int>.filled(12, 0);
    for (final entry in habit.completions.values) {
      final day = parseDayKey(entry.date);
      if (day.year != today.year || day.isAfter(today)) continue;
      if (negative || entry.count >= habit.effectiveTarget) {
        logged[day.month - 1]++;
      }
    }

    return [
      for (var month = 1; month <= 12; month++)
        () {
          final first = DateTime(today.year, month);
          final last = DateTime(today.year, month + 1, 0);
          final from = first.isBefore(floor) ? floor : first;
          final to = last.isAfter(today) ? today : last;
          final span = to.epochDay - from.epochDay + 1;
          if (span <= 0) return dim;
          final done = negative ? span - logged[month - 1] : logged[month - 1];
          final ratio = (done / span).clamp(0.0, 1.0);
          return ratio <= 0
              ? base
              : Color.lerp(habit.color.withValues(alpha: 0.3), habit.color,
                  ratio)!;
        }(),
    ];
  }

  List<Color> _dayCells(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final days = DateTime(today.year, today.month + 1, 0).day;
    return [
      for (var day = 1; day <= days; day++)
        heatmapCellColor(context, habit, DateTime(today.year, today.month, day)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cells =
        mode == HeatmapMode.year ? _monthCells(context) : _dayCells(context);

    return Row(
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: Container(
              height: mode == HeatmapMode.year ? 8 : 7,
              decoration: BoxDecoration(
                color: cells[i],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
