import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/data/focus_stats.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/widgets/stat_charts.dart';

class FocusRangeBars extends StatelessWidget {
  const FocusRangeBars({
    super.key,
    required this.stats,
    required this.range,
    required this.color,
    this.height = 150,
  });

  final FocusStats stats;
  final FocusRange range;
  final Color color;
  final double height;

  double get _barWidth => switch (range) {
    FocusRange.week => 14,
    FocusRange.month => 5,
    FocusRange.year => 11,
  };

  String _label(BuildContext context, int index) {
    if (index < 0 || index >= stats.buckets.length) return '';
    final locale = Localizations.localeOf(context);
    switch (range) {
      case FocusRange.week:
        return WeekdayLabels.narrowFrom(
          locale.languageCode,
          context.read<SettingsController>().weekStart,
        )[index];
      case FocusRange.month:
        final day = index + 1;
        return day == 1 || day % 5 == 0 ? '$day' : '';
      case FocusRange.year:
        return index.isEven
            ? DateFormat.MMM(locale.toString()).format(stats.buckets[index])
            : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueBars(
      key: ValueKey(range),
      values: [for (final seconds in stats.series) seconds / 60],
      color: color,
      height: height,
      barWidth: _barWidth,
      label: (index) => _label(context, index),
      tooltip: (value) => formatHoursShort((value * 60).round()),
    );
  }
}
