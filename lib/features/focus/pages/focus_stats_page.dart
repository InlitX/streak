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
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/data/focus_stats.dart';
import 'package:streak/features/focus/pages/focus_history_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/settings_rows.dart';
import 'package:streak/features/statistics/widgets/stat_charts.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';

class FocusStatsPage extends StatefulWidget {
  const FocusStatsPage({super.key, this.habitId});

  final String? habitId;

  @override
  State<FocusStatsPage> createState() => _FocusStatsPageState();
}

class _FocusStatsPageState extends State<FocusStatsPage> {
  FocusRange _range = FocusRange.week;

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

  String _barLabel(FocusStats stats, int index) {
    if (index < 0 || index >= stats.buckets.length) return '';
    final locale = Localizations.localeOf(context).toString();
    switch (_range) {
      case FocusRange.week:
        return WeekdayLabels.narrowFrom(
          Localizations.localeOf(context).languageCode,
          context.read<SettingsController>().weekStart,
        )[index];
      case FocusRange.month:
        final day = index + 1;
        return day == 1 || day % 5 == 0 ? '$day' : '';
      case FocusRange.year:
        return index.isEven
            ? DateFormat.MMM(locale).format(stats.buckets[index])
            : '';
    }
  }

  double _barWidth() {
    switch (_range) {
      case FocusRange.week:
        return 14;
      case FocusRange.month:
        return 5;
      case FocusRange.year:
        return 11;
    }
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
      now: AppClock.now(),
      weekStart: context.watch<SettingsController>().weekStart,
      habitId: widget.habitId,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: Text(habit?.name ?? context.l10n.focus_stats),
        actions: [
          IconButton(
            tooltip: context.l10n.focus_history,
            icon: const Icon(LucideIcons.history),
            onPressed: () =>
                AppNavigator.push(FocusHistoryPage(habitId: widget.habitId)),
          ),
        ],
      ),
      body: stats.sessionCount == 0
          ? AppEmptyState(
              icon: LucideIcons.timer,
              title: context.l10n.no_data_yet,
              message: context.l10n.focus_history_empty_sub,
            )
          : ListView(
              padding: context.pagePadding(16, 8, 16, 28),
              children: [
                StatReveal(
                  child: StatPair(
                    left: MiniStat(
                      icon: LucideIcons.sun,
                      color: accent,
                      value: formatHoursShort(stats.todaySeconds),
                      label: context.l10n.today,
                    ),
                    right: MiniStat(
                      icon: LucideIcons.calendarDays,
                      color: context.tokens.info,
                      value: formatHoursShort(stats.weekSeconds),
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
                      value: formatHoursShort(stats.monthSeconds),
                      label: context.l10n.month,
                    ),
                    right: MiniStat(
                      icon: LucideIcons.timer,
                      color: context.tokens.success,
                      value: formatHoursShort(stats.totalSeconds),
                      label: context.l10n.total,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StatReveal(
                  child: StatPair(
                    left: MiniStat(
                      icon: LucideIcons.circlePlay,
                      color: accent,
                      value: '${stats.sessionCount}',
                      label: context.l10n.focus_sessions,
                    ),
                    right: MiniStat(
                      icon: LucideIcons.activity,
                      color: context.tokens.info,
                      value: formatHoursShort(stats.averageSeconds),
                      label: context.l10n.focus_average,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                StatReveal(
                  child: StatCard(
                    title: context.l10n.focus_total,
                    icon: LucideIcons.chartColumn,
                    color: accent,
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
                            index: FocusRange.values.indexOf(_range),
                            onChanged: (index) => setState(
                              () => _range = FocusRange.values[index],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ValueBars(
                          key: ValueKey(_range),
                          values: [
                            for (final seconds in stats.series) seconds / 60,
                          ],
                          color: accent,
                          barWidth: _barWidth(),
                          label: (index) => _barLabel(stats, index),
                          tooltip: (value) =>
                              formatHoursShort((value * 60).round()),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.habitId == null && stats.perHabit.length > 1) ...[
                  const SizedBox(height: 16),
                  StatReveal(
                    child: StatCard(
                      title: context.l10n.by_habit,
                      icon: LucideIcons.listOrdered,
                      color: accent,
                      child: HabitRanking(
                        entries: _ranking(stats, habits, accent),
                        format: formatHoursShort,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
