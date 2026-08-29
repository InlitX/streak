import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/stat_columns.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_stats_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/quant_stats_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/saved_money.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/data/habit_stats.dart';
import 'package:streak/features/statistics/widgets/stat_charts.dart';
import 'package:streak/features/statistics/widgets/year_heatmap.dart';

class MinimalStatisticsPage extends StatefulWidget {
  const MinimalStatisticsPage({super.key});

  @override
  State<MinimalStatisticsPage> createState() => _MinimalStatisticsPageState();
}

class _MinimalStatisticsPageState extends State<MinimalStatisticsPage> {
  int _year = AppClock.now().year;
  String? _habitId;

  ({List<Habit> habits, String? id, int year})? _key;
  late HabitStats _stats;

  HabitStats _statsFor(List<Habit> scoped, List<Habit> all) {
    final key = (habits: all, id: _habitId, year: _year);
    if (_key != key) {
      _key = key;
      _stats = HabitStats.compute(scoped, _year);
    }
    return _stats;
  }

  List<({String name, Color color, int count})> _ranking(
    List<Habit> all,
    HabitStats stats,
  ) {
    final entries = [
      for (final habit in all)
        (
          name: habit.name,
          color: habit.color,
          count: stats.perHabit[habit.id] ?? 0,
        ),
    ]..sort((a, b) => b.count.compareTo(a.count));
    return entries.where((e) => e.count > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 52),
      body: Consumer<HabitsController>(
        builder: (context, controller, _) {
          final all = controller.habits;
          if (all.isEmpty) {
            return AppEmptyState(
              icon: LucideIcons.chartColumn,
              title: context.l10n.no_data_yet,
              message: context.l10n.stats_empty,
            );
          }

          if (_habitId != null && controller.byId(_habitId!) == null) {
            _habitId = null;
          }
          final scoped = _habitId == null
              ? HabitStats.counted(all)
              : [controller.byId(_habitId!)!];
          final habit = _habitId == null ? null : scoped.first;
          final accent = habit?.color ?? context.colors.primary;
          final stats = _statsFor(scoped, all);
          final ranked = _ranking(all, stats);

          final wide = isWideLayout(context);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1120 : 720),
              child: ListView(
                padding: context.pagePadding(20, 0, 20, 40),
                children: spanned(context, [
                  MinimalTitle(title: context.l10n.statistics),
                  if (all.length > 1) ...[
                    MinimalChips(
                      children: [
                        MinimalChip(
                          label: context.l10n.all,
                          active: _habitId == null,
                          onTap: () => setState(() => _habitId = null),
                        ),
                        for (final entry in all)
                          MinimalChip(
                            label: entry.name,
                            tint: entry.color,
                            active: _habitId == entry.id,
                            onTap: () => setState(() => _habitId = entry.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  MinimalGrid(
                    children: [
                      MinimalTile(
                        icon: LucideIcons.flame,
                        label: context.l10n.current_streak,
                        value: context.l10n.count_days(stats.currentStreak),
                      ),
                      MinimalTile(
                        icon: LucideIcons.trophy,
                        label: context.l10n.best_streak,
                        value: context.l10n.count_days(stats.bestStreak),
                      ),
                      MinimalTile(
                        icon: LucideIcons.check,
                        label: context.l10n.completions,
                        value: '${stats.total}',
                        caption: '${stats.perWeek.toStringAsFixed(1)}  '
                            '${context.l10n.per_week.toLowerCase()}',
                      ),
                      MinimalTile(
                        icon: LucideIcons.target,
                        label: context.l10n.completion_rate_short,
                        value: '${stats.consistency}%',
                        caption: context.l10n.last_90_days,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  MinimalSection(
                    title: context.l10n.activity,
                    trailing: _YearNav(
                      year: _year,
                      canGoForward: _year < AppClock.now().year,
                      onChanged: (delta) => setState(() => _year += delta),
                    ),
                    child: MinimalCard(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                      child: YearHeatmap(
                        year: _year,
                        dailyCounts: stats.dailyCounts,
                        maxCount: scoped.length,
                        color: accent,
                        habit: habit,
                      ),
                    ),
                  ),
                  const SpanEnd(),
                  MinimalSection(
                    title: context.l10n.when_best,
                    child: MinimalCard(
                      padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                      child: WeekdayBars(
                        values: stats.weekday,
                        color: accent,
                        height: 150,
                      ),
                    ),
                  ),
                  if (habit != null && habit.hasCost)
                    MinimalSection(
                      title: context.l10n.money_saved,
                      child: MinimalGrid(
                        children: [
                          MinimalTile(
                            icon: LucideIcons.piggyBank,
                            label: context.l10n.money_saved,
                            value: habitMoneySaved(context, habit),
                          ),
                          MinimalTile(
                            icon: LucideIcons.shieldCheck,
                            label: context.l10n.clean_days,
                            value: '${habit.cleanDays}',
                          ),
                        ],
                      ),
                    ),
                  if (habit != null && habit.kind == HabitKind.quantitative)
                    MinimalSection(
                      title: context.l10n.quant_per_day,
                      child: MinimalList(
                        children: [
                          MinimalRow(
                            label: context.l10n.statistics,
                            caption: habit.name,
                            onTap: () => AppNavigator.push(
                              QuantStatsPage(habitId: habit.id),
                            ),
                            last: true,
                          ),
                        ],
                      ),
                    ),
                  ?_focusSection(context, _habitId),
                  if (_habitId == null && ranked.length > 1)
                    MinimalSection(
                      title: context.l10n.by_habit,
                      gap: 0,
                      child: MinimalList(
                        children: [
                          for (var i = 0; i < ranked.length; i++)
                            MinimalRow(
                              label: ranked[i].name,
                              value: '${ranked[i].count}',
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
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget? _focusSection(BuildContext context, String? habitId) {
  if (!context.watch<SettingsController>().focusEnabled) return null;
  final focus = context.watch<FocusController>();
  if (focus.sessionCount == 0) return null;

  final sessions = habitId == null
      ? focus.sessionCount
      : focus.sessions.where((s) => s.habitId == habitId).length;
  final seconds = habitId == null
      ? focus.totalSeconds
      : focus.secondsForHabit(habitId);

  return MinimalSection(
    title: context.l10n.focus,
    child: MinimalGrid(
      children: [
        MinimalTile(
          icon: LucideIcons.timer,
          label: context.l10n.focus_total,
          value: formatHoursShort(seconds),
          onTap: () => AppNavigator.push(FocusStatsPage(habitId: habitId)),
        ),
        MinimalTile(
          icon: LucideIcons.circlePlay,
          label: context.l10n.focus_sessions,
          value: '$sessions',
          onTap: () => AppNavigator.push(FocusStatsPage(habitId: habitId)),
        ),
      ],
    ),
  );
}

class _YearNav extends StatelessWidget {
  const _YearNav({
    required this.year,
    required this.canGoForward,
    required this.onChanged,
  });

  final int year;
  final bool canGoForward;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Arrow(icon: LucideIcons.chevronLeft, onTap: () => onChanged(-1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$year',
            style: MinimalType.figure(14, color: context.colors.onSurface),
          ),
        ),
        _Arrow(
          icon: LucideIcons.chevronRight,
          onTap: canGoForward ? () => onChanged(1) : null,
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? muted.withValues(alpha: 0.35) : muted,
          ),
        ),
      ),
    );
  }
}
