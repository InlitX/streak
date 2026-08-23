import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/quant_stats.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/settings_rows.dart';
import 'package:streak/features/habits/pages/express_quant_stats_page.dart';
import 'package:streak/features/habits/pages/minimal_quant_stats_page.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/features/habits/widgets/quant_range_bars.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';

class QuantStatsPage extends StatefulWidget {
  const QuantStatsPage({super.key, required this.habitId});

  final String habitId;

  @override
  State<QuantStatsPage> createState() => _QuantStatsPageState();
}

class _QuantStatsPageState extends State<QuantStatsPage> {
  QuantRange _range = QuantRange.week;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    if (settings.isExpressStyle) {
      return ExpressQuantStatsPage(habitId: widget.habitId);
    }
    if (settings.isMinimalStyle) {
      return MinimalQuantStatsPage(habitId: widget.habitId);
    }

    final habit = context.watch<HabitsController>().byId(widget.habitId);
    if (habit == null) return const SizedBox.shrink();

    final unit = habit.isTimeAmount ? '' : habit.unitLabel;
    final stats = QuantStats.compute(
      habit: habit,
      range: _range,
      now: AppClock.now(),
      weekStart: settings.weekStart,
    );
    final totals = stats.totals;

    final body = totals.loggedDays == 0
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
                      value: habit.amountText(stats.today),
                      unit: unit,
                      label: context.l10n.today,
                    ),
                    right: MiniStat(
                      icon: LucideIcons.calendarDays,
                      color: context.tokens.info,
                      value: habit.amountText(stats.week),
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
                      value: habit.amountText(stats.month),
                      unit: unit,
                      label: context.l10n.month,
                    ),
                    right: MiniStat(
                      icon: LucideIcons.sigma,
                      color: context.tokens.success,
                      value: habit.amountText(totals.total),
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
                      value: habit.amountText(totals.average),
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
                      value: habit.amountText(totals.best),
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
                        QuantRangeBars(
                          habit: habit,
                          stats: stats,
                          range: _range,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: Text(habit.name),
      ),
      body: body,
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
    final unit = habit.isTimeAmount ? '' : habit.unitLabel;

    if (context.watch<SettingsController>().isExpressStyle) {
      return ExpressCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        onTap: () => AppNavigator.push(QuantStatsPage(habitId: habit.id)),
        child: ExpressMiniRow(
          children: [
            ExpressMiniStat(
              icon: LucideIcons.sigma,
              value: habit.amountText(totals.total),
              label: unit.isEmpty ? context.l10n.total : unit,
              tint: habit.color,
            ),
            ExpressMiniStat(
              icon: LucideIcons.activity,
              value: habit.amountText(totals.average),
              label: context.l10n.quant_average,
              tint: context.tokens.info,
            ),
            ExpressMiniStat(
              icon: LucideIcons.circleCheck,
              value: '${totals.goalDays}',
              label: context.l10n.quant_goal_days,
              tint: context.tokens.success,
            ),
          ],
        ),
      );
    }

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
                  value: habit.amountText(totals.total),
                  unit: unit,
                  label: context.l10n.total,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MiniStat(
                  icon: LucideIcons.activity,
                  color: context.tokens.info,
                  value: habit.amountText(totals.average),
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
