import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
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

class MinimalFocusStatsPage extends StatefulWidget {
  const MinimalFocusStatsPage({super.key, this.habitId});

  final String? habitId;

  @override
  State<MinimalFocusStatsPage> createState() => _MinimalFocusStatsPageState();
}

class _MinimalFocusStatsPageState extends State<MinimalFocusStatsPage> {
  FocusRange _range = FocusRange.week;
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    final habits = context.watch<HabitsController>();
    final habit = widget.habitId == null ? null : habits.byId(widget.habitId!);
    final accent = habit?.color ?? context.colors.primary;
    final title = habit?.name ?? context.l10n.focus_stats;

    final stats = FocusStats.compute(
      sessions: focus.sessions,
      range: _range,
      offset: _offset,
      now: AppClock.now(),
      weekStart: context.watch<SettingsController>().weekStart,
      habitId: widget.habitId,
    );

    final ranked = [
      for (final entry in stats.perHabit.entries)
        (
          name: habits.byId(entry.key)?.name ?? context.l10n.focus_free_session,
          color: habits.byId(entry.key)?.color ?? accent,
          seconds: entry.value,
        ),
    ]..sort((a, b) => b.seconds.compareTo(a.seconds));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.focus_history,
            icon: const Icon(LucideIcons.history, size: 20),
            onPressed: () => AppNavigator.push(
              FocusHistoryPage(habitId: widget.habitId),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: stats.sessionCount == 0
          ? AppEmptyState(
              icon: LucideIcons.timer,
              title: context.l10n.no_data_yet,
              message: context.l10n.focus_history_empty_sub,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: context.pagePadding(20, 0, 20, 40),
                  children: [
                    MinimalTitle(title: title),
                    MinimalGrid(
                      children: [
                        MinimalTile(
                          icon: LucideIcons.timer,
                          label: context.l10n.focus_total,
                          value: formatHoursShort(stats.totalSeconds),
                        ),
                        MinimalTile(
                          icon: LucideIcons.sun,
                          label: context.l10n.today,
                          value: formatHoursShort(stats.todaySeconds),
                        ),
                        MinimalTile(
                          icon: LucideIcons.circlePlay,
                          label: context.l10n.focus_sessions,
                          value: '${stats.sessionCount}',
                        ),
                        MinimalTile(
                          icon: LucideIcons.activity,
                          label: context.l10n.focus_average,
                          value: formatHoursShort(stats.averageSeconds),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    MinimalSection(
                      title: context.l10n.focus_total,
                      trailing: MinimalSegmented(
                        options: [
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
                      child: MinimalCard(
                        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                        child: Column(
                          children: [
                            FocusPeriodBar(
                              range: _range,
                              offset: _offset,
                              stats: stats,
                              accent: accent,
                              onOffset: (value) =>
                                  setState(() => _offset = value),
                            ),
                            const SizedBox(height: 14),
                            FocusRangeBars(
                              stats: stats,
                              range: _range,
                              color: accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.habitId == null && ranked.length > 1)
                      MinimalSection(
                        title: context.l10n.by_habit,
                        gap: 0,
                        child: MinimalList(
                          children: [
                            for (var i = 0; i < ranked.length; i++)
                              MinimalRow(
                                label: ranked[i].name,
                                value: formatHoursShort(ranked[i].seconds),
                                leading: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: ranked[i].color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                last: i == ranked.length - 1,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
