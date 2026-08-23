import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/quant_stats.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/widgets/stat_charts.dart';

String amountWithUnit(Habit habit, double value) =>
    habit.isTimeAmount || habit.unitLabel.isEmpty
        ? habit.amountText(value)
        : '${formatAmount(value)} ${habit.unitLabel}';

class QuantRangeBars extends StatelessWidget {
  const QuantRangeBars({
    super.key,
    required this.habit,
    required this.stats,
    required this.range,
    this.height = 150,
  });

  final Habit habit;
  final QuantStats stats;
  final QuantRange range;
  final double height;

  double get _barWidth => switch (range) {
    QuantRange.week => 14,
    QuantRange.month => 5,
    QuantRange.year => 11,
  };

  String _label(BuildContext context, int index) {
    if (index < 0 || index >= stats.buckets.length) return '';
    final locale = Localizations.localeOf(context);
    switch (range) {
      case QuantRange.week:
        return WeekdayLabels.narrowFrom(
          locale.languageCode,
          context.read<SettingsController>().weekStart,
        )[index];
      case QuantRange.month:
        final day = index + 1;
        return day == 1 || day % 5 == 0 ? '$day' : '';
      case QuantRange.year:
        return index.isEven
            ? DateFormat.MMM(locale.toString()).format(stats.buckets[index])
            : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueBars(
      key: ValueKey(range),
      values: stats.series,
      color: habit.color,
      height: height,
      barWidth: _barWidth,
      goal: range == QuantRange.year ? null : habit.perDayTarget,
      label: (index) => _label(context, index),
      tooltip: (value) => amountWithUnit(habit, value),
    );
  }
}
