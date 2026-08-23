import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_page.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_tabs.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/quant_stats.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/quant_range_bars.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/widgets/express_stat_kit.dart';

class ExpressQuantStatsPage extends StatefulWidget {
  const ExpressQuantStatsPage({super.key, required this.habitId});

  final String habitId;

  @override
  State<ExpressQuantStatsPage> createState() => _ExpressQuantStatsPageState();
}

class _ExpressQuantStatsPageState extends State<ExpressQuantStatsPage> {
  QuantRange _range = QuantRange.week;

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitsController>().byId(widget.habitId);
    if (habit == null) return const SizedBox.shrink();

    final unit = habit.isTimeAmount ? '' : habit.unitLabel;
    final stats = QuantStats.compute(
      habit: habit,
      range: _range,
      now: AppClock.now(),
      weekStart: context.watch<SettingsController>().weekStart,
    );
    final totals = stats.totals;

    final sections = <Widget>[
      _TotalHero(habit: habit, stats: stats, unit: unit),
      const SizedBox(height: 20),
      ExpressGroup(
        children: [
          ExpressStatRow(
            icon: LucideIcons.activity,
            label: context.l10n.quant_average,
            value: habit.amountText(totals.average),
            tint: context.tokens.info,
            shape: ExpressShape.cookie,
          ),
          ExpressStatRow(
            icon: LucideIcons.trophy,
            label: context.l10n.quant_best_day,
            value: habit.amountText(totals.best),
            tint: context.tokens.warning,
            shape: ExpressShape.gem,
          ),
          ExpressStatRow(
            icon: LucideIcons.calendarCheck,
            label: context.l10n.quant_logged_days,
            value: '${totals.loggedDays}',
            tint: habit.color,
            shape: ExpressShape.clover,
          ),
          ExpressStatRow(
            icon: LucideIcons.circleCheck,
            label: context.l10n.quant_goal_days,
            value: '${totals.goalDays}',
            tint: context.tokens.success,
            shape: ExpressShape.flower,
          ),
        ],
      ),
      const SizedBox(height: 20),
      ExpressStatPanel(
        title: context.l10n.quant_per_day,
        icon: LucideIcons.chartColumn,
        tint: habit.color,
        shape: ExpressShape.gem,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExpressTabs(
              labels: [
                context.l10n.week,
                context.l10n.month,
                context.l10n.year,
              ],
              index: QuantRange.values.indexOf(_range),
              onChanged: (index) =>
                  setState(() => _range = QuantRange.values[index]),
            ),
            const SizedBox(height: 18),
            QuantRangeBars(habit: habit, stats: stats, range: _range),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: expressBar(),
      body: totals.loggedDays == 0
          ? expressBody(
              title: habit.name,
              child: AppEmptyState(
                icon: LucideIcons.chartColumn,
                title: context.l10n.no_data_yet,
                message: context.l10n.quant_stats_empty,
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: context.pagePadding(18, 0, 18, 40),
                  children: [
                    ExpressHeadline(title: habit.name),
                    const SizedBox(height: 20),
                    for (var i = 0; i < sections.length; i++)
                      ExpressReveal(index: i ~/ 2, child: sections[i]),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TotalHero extends StatelessWidget {
  const _TotalHero({
    required this.habit,
    required this.stats,
    required this.unit,
  });

  final Habit habit;
  final QuantStats stats;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return ExpressCard(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExpressBlob(
                size: 52,
                color: habit.color.withValues(alpha: 0.18),
                shape: ExpressShape.flower,
                child: Icon(LucideIcons.sigma, size: 23, color: habit.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.isEmpty
                          ? context.l10n.total
                          : '${context.l10n.total}  ·  $unit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ExpressType.body.at(
                        12.5,
                        weight: 700,
                        color: context.tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        habit.amountText(stats.totals.total),
                        style: ExpressType.display.at(
                          36,
                          height: 1.05,
                          spacing: -1,
                          color: context.colors.onSurface,
                          tabular: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ExpressMiniRow(
            children: [
              ExpressMiniStat(
                icon: LucideIcons.sun,
                value: habit.amountText(stats.today),
                label: context.l10n.today,
                tint: habit.color,
              ),
              ExpressMiniStat(
                icon: LucideIcons.calendarDays,
                value: habit.amountText(stats.week),
                label: context.l10n.week,
                tint: context.tokens.info,
              ),
              ExpressMiniStat(
                icon: LucideIcons.calendarRange,
                value: habit.amountText(stats.month),
                label: context.l10n.month,
                tint: context.tokens.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
