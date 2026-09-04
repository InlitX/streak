import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/statistics/data/habit_stats.dart';

List<({String label, int value})> periodRows(
  BuildContext context,
  HabitStats stats,
  int year,
) {
  final current = AppClock.now().year;
  return [
    (label: context.l10n.period_this_week, value: stats.weekDone),
    (label: context.l10n.period_this_month, value: stats.monthDone),
    (
      label: year == current ? context.l10n.period_this_year : '$year',
      value: stats.total,
    ),
    (label: context.l10n.period_all_time, value: stats.allDone),
  ];
}

class PeriodTotals extends StatelessWidget {
  const PeriodTotals({
    super.key,
    required this.stats,
    required this.year,
    required this.color,
  });

  final HabitStats stats;
  final int year;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rows = periodRows(context, stats, year);
    final line = context.tokens.muted.withValues(alpha: 0.18);

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: i == rows.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i].label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.tokens.muted,
                    ),
                  ),
                ),
                Text(
                  '${rows[i].value}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: i == rows.length - 1
                        ? color
                        : context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
