import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/color_extensions.dart';
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
import 'package:streak/features/focus/widgets/focus_insights.dart';
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
    context.select<FocusController, int>((f) => f.revision);
    final focus = context.read<FocusController>();
    final habits = context.watch<HabitsController>();
    final habit = widget.habitId == null ? null : habits.byId(widget.habitId!);
    final accent = habit?.color.shownIn(context) ?? context.colors.primary;
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
          color: habits.byId(entry.key)?.color.shownIn(context) ?? context.tokens.muted,
          seconds: entry.value,
        ),
    ]..sort((a, b) => b.seconds.compareTo(a.seconds));

    final muted = TextStyle(fontSize: 13, color: context.tokens.muted);

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
                        MinimalTile(
                          icon: LucideIcons.flame,
                          label: context.l10n.focus_streak,
                          value: context.l10n.count_days(stats.streak),
                        ),
                        MinimalTile(
                          icon: LucideIcons.calendarRange,
                          label: context.l10n.month,
                          value: formatHoursShort(stats.monthSeconds),
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
                              stacks: widget.habitId == null
                                  ? focusStacks(context, stats, accent)
                                  : null,
                            ),
                            if (focusChangeLine(context, stats)
                                case final change?) ...[
                              const SizedBox(height: 10),
                              Text(change, style: muted),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (stats.measured > 0)
                      MinimalSection(
                        title: context.l10n.focus_plan_vs_real,
                        child: MinimalCard(
                          child: FocusPlanFacts(
                            stats: stats,
                            headline: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.colors.onSurface,
                            ),
                            body: muted,
                          ),
                        ),
                      ),
                    if (stats.rangeSeconds > 0) ...[
                      MinimalSection(
                        title: context.l10n.focus_by_hour,
                        child: MinimalCard(
                          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  context.l10n.focus_busiest(
                                    focusHour(context, stats.busiestHour),
                                  ),
                                  style: muted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FocusHourBars(stats: stats, color: accent),
                            ],
                          ),
                        ),
                      ),
                      MinimalSection(
                        title: context.l10n.focus_by_weekday,
                        child: MinimalCard(
                          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                          child: FocusWeekdayBars(stats: stats, color: accent),
                        ),
                      ),
                    ],
                    MinimalSection(
                      title: context.l10n.focus_heatmap,
                      child: MinimalCard(
                        child: FocusHeat(stats: stats, color: accent),
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
                    if (stats.perLabel.isNotEmpty)
                      MinimalSection(
                        title: context.l10n.by_label,
                        gap: 0,
                        child: MinimalList(
                          children: [
                            for (final (i, entry) in stats.labelRanking.indexed)
                              MinimalRow(
                                label: entry.key,
                                value: formatHoursShort(entry.value),
                                leading: Icon(
                                  LucideIcons.tag,
                                  size: 14,
                                  color: context.tokens.muted,
                                ),
                                last: i == stats.labelRanking.length - 1,
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
