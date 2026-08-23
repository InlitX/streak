import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_page.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_tabs.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/data/focus_stats.dart';
import 'package:streak/features/focus/pages/focus_history_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/focus/widgets/focus_period_bar.dart';
import 'package:streak/features/focus/widgets/focus_range_bars.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/widgets/express_stat_kit.dart';

class ExpressFocusStatsPage extends StatefulWidget {
  const ExpressFocusStatsPage({super.key, this.habitId});

  final String? habitId;

  @override
  State<ExpressFocusStatsPage> createState() => _ExpressFocusStatsPageState();
}

class _ExpressFocusStatsPageState extends State<ExpressFocusStatsPage> {
  FocusRange _range = FocusRange.week;
  int _offset = 0;

  List<({String name, Color color, int count})> _ranking(
    FocusStats stats,
    HabitsController habits,
    Color accent,
  ) {
    final entries = [
      for (final entry in stats.perHabit.entries)
        (
          name: habits.byId(entry.key)?.name ?? context.l10n.focus_free_session,
          color: habits.byId(entry.key)?.color ?? accent,
          count: entry.value,
        ),
    ]..sort((a, b) => b.count.compareTo(a.count));
    return entries.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    final habits = context.watch<HabitsController>();
    final habit = widget.habitId == null ? null : habits.byId(widget.habitId!);
    final accent = habit?.color ?? context.colors.primary;

    final stats = FocusStats.compute(
      sessions: focus.sessions,
      range: _range,
      offset: _offset,
      now: AppClock.now(),
      weekStart: context.watch<SettingsController>().weekStart,
      habitId: widget.habitId,
    );

    final sections = <Widget>[
      _TotalHero(stats: stats, accent: accent),
      const SizedBox(height: 20),
      ExpressGroup(
        children: [
          ExpressStatRow(
            icon: LucideIcons.calendarDays,
            label: context.l10n.week,
            value: formatHoursShort(stats.weekSeconds),
            tint: context.tokens.info,
            shape: ExpressShape.cookie,
          ),
          ExpressStatRow(
            icon: LucideIcons.calendarRange,
            label: context.l10n.month,
            value: formatHoursShort(stats.monthSeconds),
            tint: context.tokens.warning,
            shape: ExpressShape.clover,
          ),
        ],
      ),
      const SizedBox(height: 20),
      ExpressStatPanel(
        title: context.l10n.focus_total,
        icon: LucideIcons.chartColumn,
        tint: accent,
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
              index: FocusRange.values.indexOf(_range),
              onChanged: (index) => setState(() {
                _range = FocusRange.values[index];
                _offset = 0;
              }),
            ),
            const SizedBox(height: 12),
            FocusPeriodBar(
              range: _range,
              offset: _offset,
              stats: stats,
              accent: accent,
              onOffset: (value) => setState(() => _offset = value),
            ),
            const SizedBox(height: 14),
            FocusRangeBars(stats: stats, range: _range, color: accent),
          ],
        ),
      ),
      if (widget.habitId == null && stats.perHabit.length > 1) ...[
        const SizedBox(height: 12),
        ExpressStatPanel(
          title: context.l10n.by_habit,
          icon: LucideIcons.listOrdered,
          tint: accent,
          shape: ExpressShape.sunny,
          child: ExpressRanking(
            entries: _ranking(stats, habits, accent),
            format: formatHoursShort,
          ),
        ),
      ],
    ];

    return Scaffold(
      appBar: expressBar(
        actions: [
          Center(
            child: ExpressIconButton(
              icon: LucideIcons.history,
              tooltip: context.l10n.focus_history,
              onPressed: () => AppNavigator.push(
                FocusHistoryPage(habitId: widget.habitId),
              ),
            ),
          ),
        ],
      ),
      body: stats.sessionCount == 0
          ? expressBody(
              title: habit?.name ?? context.l10n.focus_stats,
              child: AppEmptyState(
                icon: LucideIcons.timer,
                title: context.l10n.no_data_yet,
                message: context.l10n.focus_history_empty_sub,
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: context.pagePadding(18, 0, 18, 40),
                  children: [
                    ExpressHeadline(
                      title: habit?.name ?? context.l10n.focus_stats,
                    ),
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
  const _TotalHero({required this.stats, required this.accent});

  final FocusStats stats;
  final Color accent;

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
                color: accent.withValues(alpha: 0.18),
                shape: ExpressShape.flower,
                child: Icon(LucideIcons.timer, size: 24, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.total,
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
                        formatHoursShort(stats.totalSeconds),
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
                value: formatHoursShort(stats.todaySeconds),
                label: context.l10n.today,
                tint: accent,
              ),
              ExpressMiniStat(
                icon: LucideIcons.circlePlay,
                value: '${stats.sessionCount}',
                label: context.l10n.focus_sessions,
                tint: context.tokens.info,
              ),
              ExpressMiniStat(
                icon: LucideIcons.activity,
                value: formatHoursShort(stats.averageSeconds),
                label: context.l10n.focus_average,
                tint: context.tokens.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
