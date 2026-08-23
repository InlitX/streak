import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/habits/data/quant_stats.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/quant_range_bars.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class MinimalQuantStatsPage extends StatefulWidget {
  const MinimalQuantStatsPage({super.key, required this.habitId});

  final String habitId;

  @override
  State<MinimalQuantStatsPage> createState() => _MinimalQuantStatsPageState();
}

class _MinimalQuantStatsPageState extends State<MinimalQuantStatsPage> {
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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
      ),
      body: totals.loggedDays == 0
          ? AppEmptyState(
              icon: LucideIcons.chartColumn,
              title: context.l10n.no_data_yet,
              message: context.l10n.quant_stats_empty,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: context.pagePadding(20, 0, 20, 40),
                  children: [
                    MinimalTitle(title: habit.name),
                    MinimalGrid(
                      children: [
                        MinimalTile(
                          icon: LucideIcons.sigma,
                          label: context.l10n.total,
                          value: habit.amountText(totals.total),
                          caption: unit.isEmpty ? null : unit,
                        ),
                        MinimalTile(
                          icon: LucideIcons.activity,
                          label: context.l10n.quant_average,
                          value: habit.amountText(totals.average),
                          caption: unit.isEmpty ? null : unit,
                        ),
                        MinimalTile(
                          icon: LucideIcons.trophy,
                          label: context.l10n.quant_best_day,
                          value: habit.amountText(totals.best),
                        ),
                        MinimalTile(
                          icon: LucideIcons.circleCheck,
                          label: context.l10n.quant_goal_days,
                          value: '${totals.goalDays}',
                          caption: context.l10n.quant_logged_days,
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    MinimalSection(
                      title: context.l10n.quant_per_day,
                      trailing: MinimalSegmented(
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
                      child: MinimalCard(
                        padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                        child: QuantRangeBars(
                          habit: habit,
                          stats: stats,
                          range: _range,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
