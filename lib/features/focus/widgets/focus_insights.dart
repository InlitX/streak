import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/data/focus_stats.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/statistics/widgets/stat_charts.dart';
import 'package:streak/features/statistics/widgets/year_heatmap.dart';

String focusPercent(BuildContext context, double ratio) =>
    NumberFormat.decimalPercentPattern(
      locale: Localizations.localeOf(context).toString(),
      decimalDigits: ratio.abs() < 0.1 ? 1 : 0,
    ).format(ratio.abs());

bool _onPlan(double overrun) => overrun.abs() < 0.02;

String focusPlanLine(BuildContext context, double overrun) {
  if (_onPlan(overrun)) return context.l10n.focus_avg_on_plan;
  final pct = focusPercent(context, overrun);
  return overrun > 0
      ? context.l10n.focus_avg_longer(pct)
      : context.l10n.focus_avg_shorter(pct);
}

String focusSessionLine(BuildContext context, FocusSession session) {
  final overrun = session.overrun;
  if (_onPlan(overrun)) return context.l10n.focus_session_on_plan;
  final pct = focusPercent(context, overrun);
  return overrun > 0
      ? context.l10n.focus_session_longer(pct)
      : context.l10n.focus_session_shorter(pct);
}

String? focusChangeLine(BuildContext context, FocusStats stats) {
  final change = stats.change;
  if (change == null) return null;
  final sign = change > 0 ? '+' : change < 0 ? '−' : '';
  return context.l10n.focus_vs_previous('$sign${focusPercent(context, change)}');
}

String focusHour(BuildContext context, int hour) =>
    TimeOfDay(hour: hour, minute: 0).format(context);

String focusPauses(BuildContext context, double perSession) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toString())
        .format((perSession * 10).round() / 10);

List<List<(double, Color)>>? focusStacks(
  BuildContext context,
  FocusStats stats,
  Color accent,
) {
  if (stats.perHabit.length < 2) return null;
  final habits = context.read<HabitsController>();
  final order = stats.perHabit.keys.toList()
    ..sort((a, b) => stats.perHabit[b]!.compareTo(stats.perHabit[a]!));
  Color tint(String id) =>
      habits.byId(id)?.color.shownIn(context) ?? context.tokens.muted;
  return [
    for (final bucket in stats.stacks)
      [
        for (final id in order)
          if ((bucket[id] ?? 0) > 0) (bucket[id]! / 60, tint(id)),
      ],
  ];
}

class FocusHourBars extends StatelessWidget {
  const FocusHourBars({
    super.key,
    required this.stats,
    required this.color,
    this.height = 140,
  });

  final FocusStats stats;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ValueBars(
      values: [for (final seconds in stats.hours) seconds / 60],
      color: color,
      height: height,
      barWidth: 6,
      label: (index) => index % 6 == 0 ? '$index' : '',
      tooltip: (value) => formatHoursShort((value * 60).round()),
      axisFormat: (value) =>
          value <= 0 ? '0' : formatHoursShort((value * 60).round()),
    );
  }
}

class FocusWeekdayBars extends StatelessWidget {
  const FocusWeekdayBars({
    super.key,
    required this.stats,
    required this.color,
    this.height = 140,
  });

  final FocusStats stats;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return WeekdayBars(
      values: [for (final seconds in stats.weekdays) seconds ~/ 60],
      color: color,
      height: height,
      format: (value) =>
          value <= 0 ? '0' : formatHoursShort((value * 60).round()),
    );
  }
}

class FocusHeat extends StatelessWidget {
  const FocusHeat({
    super.key,
    required this.stats,
    required this.color,
    this.express = false,
  });

  final FocusStats stats;
  final Color color;
  final bool express;

  @override
  Widget build(BuildContext context) {
    final minutes = {
      for (final entry in stats.heat.entries) entry.key: entry.value ~/ 60,
    };
    final most = minutes.values.fold(0, max);
    return YearHeatmap(
      year: AppClock.now().year,
      dailyCounts: minutes,
      maxCount: max(30, most),
      color: color,
      express: express,
    );
  }
}

class FocusPlanFacts extends StatelessWidget {
  const FocusPlanFacts({
    super.key,
    required this.stats,
    required this.headline,
    required this.body,
  });

  final FocusStats stats;
  final TextStyle headline;
  final TextStyle body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(focusPlanLine(context, stats.overrun), style: headline),
        const SizedBox(height: 6),
        Text(
          '${context.l10n.focus_pauses_avg}: '
          '${focusPauses(context, stats.pausesPerSession)}',
          style: body,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.focus_plan_hint,
          style: body.copyWith(fontSize: (body.fontSize ?? 13) - 1.5),
        ),
      ],
    );
  }
}
