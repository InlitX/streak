import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/quant_stats.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/settings_rows.dart';
import 'package:streak/features/statistics/widgets/stat_charts.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';

String amountWithUnit(double value, String unit) =>
    unit.isEmpty ? formatAmount(value) : '${formatAmount(value)} $unit';

class QuantStatsPage extends StatefulWidget {
  const QuantStatsPage({super.key, required this.habitId});

  final String habitId;

  @override
  State<QuantStatsPage> createState() => _QuantStatsPageState();
}

class _QuantStatsPageState extends State<QuantStatsPage> {
  QuantRange _range = QuantRange.week;

  String _barLabel(QuantStats stats, int index) {
    if (index < 0 || index >= stats.buckets.length) return '';
    final locale = Localizations.localeOf(context).toString();
    switch (_range) {
      case QuantRange.week:
        return WeekdayLabels.narrowFrom(
          Localizations.localeOf(context).languageCode,
          context.read<SettingsController>().weekStart,
        )[index];
      case QuantRange.month:
        final day = index + 1;
        return day == 1 || day % 5 == 0 ? '$day' : '';
      case QuantRange.year:
        return index.isEven
            ? DateFormat.MMM(locale).format(stats.buckets[index])
            : '';
    }
  }

  double _barWidth() => switch (_range) {
        QuantRange.week => 14,
        QuantRange.month => 5,
        QuantRange.year => 11,
      };

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitsController>().byId(widget.habitId);
    if (habit == null) return const SizedBox.shrink();

    final unit = habit.unitLabel;
    final stats = QuantStats.compute(
      habit: habit,
      range: _range,
      now: AppClock.now(),
      weekStart: context.watch<SettingsController>().weekStart,
    );
    final totals = stats.totals;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: Text(habit.name),
      ),
      body: totals.loggedDays == 0
          ? AppEmptyState(
              icon: LucideIcons.chartColumn,
              title: context.l10n.no_data_yet,
              message: context.l10n.quant_stats_empty,
            )
          : ListView(
              padding: context.pagePadding(16, 8, 16, 28),
              children: [
                StatReveal(
                  child: StatPair(
                    left: MiniStat(
                      icon: LucideIcons.sun,
                      color: habit.color,
                      value: formatAmount(stats.today),
                      unit: unit,
                      label: context.l10n.today,
                    ),
                    right: MiniStat(
                      icon: LucideIcons.calendarDays,
                      color: context.tokens.info,
                      value: formatAmount(stats.week),
                      unit: unit,
                      label: context.l10n.week,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StatReveal(
                  child: StatPair(
                    left: MiniStat(
                      icon: LucideIcons.calendarRange,
                      color: context.tokens.warning,
                      value: formatAmount(stats.month),
                      unit: unit,
                      label: context.l10n.month,
                    ),
                    right: MiniStat(
                      icon: LucideIcons.sigma,
                      color: context.tokens.success,
                      value: formatAmount(totals.total),
                      unit: unit,
                      label: context.l10n.total,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StatReveal(
                  child: StatPair(
                    left: MiniStat(
                      icon: LucideIcons.calendarCheck,
                      color: habit.color,
                      value: '${totals.loggedDays}',
                      label: context.l10n.quant_logged_days,
                    ),
                    right: MiniStat(
                      icon: LucideIcons.activity,
                      color: context.tokens.info,
                      value: formatAmount(totals.average),
                      unit: unit,
                      label: context.l10n.quant_average,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StatReveal(
                  child: StatPair(
                    left: MiniStat(
                      icon: LucideIcons.trophy,
                      color: context.tokens.warning,
                      value: formatAmount(totals.best),
                      unit: unit,
                      label: context.l10n.quant_best_day,
                    ),
                    right: MiniStat(
                      icon: LucideIcons.circleCheck,
                      color: context.tokens.success,
                      value: '${totals.goalDays}',
                      label: context.l10n.quant_goal_days,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                StatReveal(
                  child: StatCard(
                    title: context.l10n.quant_per_day,
                    icon: LucideIcons.chartColumn,
                    color: habit.color,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Segmented(
                            options: [
                              context.l10n.week,
                              context.l10n.month,
                              context.l10n.year,
                            ],
                            index: QuantRange.values.indexOf(_range),
                            onChanged: (index) => setState(
                              () => _range = QuantRange.values[index],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ValueBars(
                          key: ValueKey(_range),
                          values: stats.series,
                          color: habit.color,
                          barWidth: _barWidth(),
                          goal: _range == QuantRange.year
                              ? null
                              : habit.perDayTarget,
                          label: (index) => _barLabel(stats, index),
                          tooltip: (value) => amountWithUnit(value, unit),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class QuantStatsLink extends StatelessWidget {
  const QuantStatsLink({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final color = habit.color;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => AppNavigator.push(QuantStatsPage(habitId: habit.id)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.chartColumn, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                context.l10n.statistics,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 15, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class QuantStatsRow extends StatelessWidget {
  const QuantStatsRow({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final totals = QuantStats.totalsOf(habit, AppClock.now());
    final unit = habit.unitLabel;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => AppNavigator.push(QuantStatsPage(habitId: habit.id)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: MiniStat(
                  icon: LucideIcons.sigma,
                  color: habit.color,
                  value: formatAmount(totals.total),
                  unit: unit,
                  label: context.l10n.total,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MiniStat(
                  icon: LucideIcons.activity,
                  color: context.tokens.info,
                  value: formatAmount(totals.average),
                  unit: unit,
                  label: context.l10n.quant_average,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MiniStat(
                  icon: LucideIcons.circleCheck,
                  color: context.tokens.success,
                  value: '${totals.goalDays}',
                  label: context.l10n.quant_goal_days,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
