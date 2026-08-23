import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_page.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/express/express_tabs.dart';
import 'package:streak/core/express/express_wave.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_stats_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/quant_stats_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/saved_money.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/data/habit_stats.dart';
import 'package:streak/features/statistics/widgets/express_stat_kit.dart';
import 'package:streak/features/statistics/widgets/stat_charts.dart';
import 'package:streak/features/statistics/widgets/stat_line_charts.dart';
import 'package:streak/features/statistics/widgets/year_heatmap.dart';

class ExpressStatisticsPage extends StatefulWidget {
  const ExpressStatisticsPage({super.key});

  @override
  State<ExpressStatisticsPage> createState() => _ExpressStatisticsPageState();
}

class _ExpressStatisticsPageState extends State<ExpressStatisticsPage> {
  int _tab = 0;
  int _year = AppClock.now().year;
  String? _habitId;

  ({List<Habit> habits, String? id, int year})? _statsKey;
  late HabitStats _stats;

  HabitStats _statsFor(List<Habit> scoped, List<Habit> all) {
    final key = (habits: all, id: _habitId, year: _year);
    if (_statsKey != key) {
      _statsKey = key;
      _stats = HabitStats.compute(scoped, _year);
    }
    return _stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          context.l10n.statistics,
          style: ExpressType.display.at(
            24,
            spacing: -0.2,
            color: context.colors.onSurface,
          ),
        ),
      ),
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
          final scoped = _habitId == null ? all : [controller.byId(_habitId!)!];
          final accent = _habitId == null
              ? context.colors.primary
              : scoped.first.color;
          final stats = _statsFor(scoped, all);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: context.pagePadding(16, 4, 16, 128),
                children: [
                  ExpressTabs(
                    labels: [context.l10n.overview, context.l10n.activity],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 16),
                  _HabitScope(
                    habits: all,
                    selected: _habitId,
                    onSelected: (id) => setState(() => _habitId = id),
                  ),
                  const SizedBox(height: 14),
                  ExpressYearNav(
                    year: _year,
                    canGoForward: _year < AppClock.now().year,
                    onChanged: (delta) => setState(() => _year += delta),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: Express.quick,
                    switchInCurve: Express.emphasized,
                    switchOutCurve: Express.emphasized,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        for (final child in previous)
                          Positioned(left: 0, right: 0, child: child),
                        if (current != null) current,
                      ],
                    ),
                    transitionBuilder: (child, animation) {
                      final incoming = child.key == ValueKey(_tab);
                      final shift =
                          (_tab == 0 ? -1.0 : 1.0) * (incoming ? 1 : -1);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween(
                                begin: Offset(0.08 * shift, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Express.emphasized,
                                ),
                              ),
                          child: child,
                        ),
                      );
                    },
                    child: Builder(
                      key: ValueKey(_tab),
                      builder: (context) {
                        final items = _tab == 0
                            ? _overview(context, stats, scoped, all, accent)
                            : _activity(context, stats, scoped, accent);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < items.length; i++)
                              ExpressReveal(index: i ~/ 2, child: items[i]),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _overview(
    BuildContext context,
    HabitStats stats,
    List<Habit> scoped,
    List<Habit> all,
    Color accent,
  ) {
    final focus = context.watch<FocusController>();
    final settings = context.watch<SettingsController>();

    final ranked = [
      for (final habit in all)
        (
          name: habit.name,
          color: habit.color,
          count: stats.perHabit[habit.id] ?? 0,
        ),
    ]..sort((a, b) => b.count.compareTo(a.count));
    final entries = ranked.where((e) => e.count > 0).toList();
    final sessions = _habitId == null
        ? focus.sessionCount
        : focus.sessions.where((s) => s.habitId == _habitId).length;

    return [
      _ConsistencyHero(percent: stats.consistency, accent: accent),
      const SizedBox(height: 24),
      SectionLabel(context.l10n.streaks),
      ExpressGroup(
        children: [
          ExpressStatRow(
            icon: LucideIcons.flame,
            label: context.l10n.current_streak,
            value: '${stats.currentStreak}',
            tint: context.tokens.warning,
          ),
          ExpressStatRow(
            icon: LucideIcons.trophy,
            label: context.l10n.best_streak,
            value: '${stats.bestStreak}',
            tint: context.tokens.success,
            shape: ExpressShape.gem,
          ),
          ExpressStatRow(
            icon: LucideIcons.sparkles,
            label: context.l10n.perfect_streak,
            value: '${stats.perfectStreak}',
            tint: context.tokens.info,
            shape: ExpressShape.clover,
          ),
        ],
      ),
      const SizedBox(height: 24),
      SectionLabel(context.l10n.completions),
      ExpressGroup(
        children: [
          ExpressStatRow(
            icon: LucideIcons.hash,
            label: context.l10n.completions,
            value: '${stats.total}',
            tint: accent,
            shape: ExpressShape.sunny,
          ),
          ExpressStatRow(
            icon: LucideIcons.repeat2,
            label: context.l10n.per_week,
            value: stats.perWeek.toStringAsFixed(1),
            tint: accent,
            shape: ExpressShape.pebble,
          ),
          ExpressStatRow(
            icon: LucideIcons.calendarCheck,
            label: context.l10n.perfect_days,
            value: '${stats.perfectDays}',
            tint: context.tokens.success,
            shape: ExpressShape.flower,
          ),
        ],
      ),
      if (scoped.length == 1 && scoped.first.hasCost) ...[
        const SizedBox(height: 20),
        SavedMoneyStats(habit: scoped.first),
      ],
      if (scoped.length == 1 &&
          scoped.first.kind == HabitKind.quantitative) ...[
        const SizedBox(height: 20),
        QuantStatsRow(habit: scoped.first),
      ],
      if (settings.focusEnabled && focus.sessionCount > 0) ...[
        const SizedBox(height: 24),
        SectionLabel(context.l10n.focus),
        ExpressGroup(
          children: [
            ExpressStatRow(
              icon: LucideIcons.timer,
              label: context.l10n.focus_total,
              value: formatHoursShort(
                _habitId == null
                    ? focus.totalSeconds
                    : focus.secondsForHabit(_habitId!),
              ),
              tint: accent,
              onTap: () => AppNavigator.push(FocusStatsPage(habitId: _habitId)),
            ),
            ExpressStatRow(
              icon: LucideIcons.circlePlay,
              label: context.l10n.focus_sessions,
              value: '$sessions',
              tint: context.tokens.info,
              shape: ExpressShape.burst,
              onTap: () => AppNavigator.push(FocusStatsPage(habitId: _habitId)),
            ),
          ],
        ),
      ],
      if (entries.length > 1) ...[
        const SizedBox(height: 24),
        SectionLabel(context.l10n.ranking),
        ExpressCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: ExpressRanking(entries: entries),
        ),
      ],
    ];
  }

  List<Widget> _activity(
    BuildContext context,
    HabitStats stats,
    List<Habit> scoped,
    Color accent,
  ) {
    return [
      ExpressStatPanel(
        title: context.l10n.activity,
        icon: LucideIcons.grid2x2,
        tint: accent,
        shape: ExpressShape.gem,
        child: YearHeatmap(
          year: _year,
          dailyCounts: stats.dailyCounts,
          maxCount: scoped.length,
          color: accent,
          habit: _habitId == null ? null : scoped.first,
          express: true,
        ),
      ),
      const SizedBox(height: 12),
      ExpressStatPanel(
        title: context.l10n.completions_per_month,
        icon: LucideIcons.chartSpline,
        tint: accent,
        shape: ExpressShape.sunny,
        child: stats.total > 0
            ? MonthlyLine(
                key: ValueKey('express-monthly-$_year-$_habitId'),
                values: stats.monthly,
                color: accent,
                year: _year,
              )
            : _Placeholder(text: context.l10n.not_enough_data),
      ),
      const SizedBox(height: 12),
      ExpressStatPanel(
        title: context.l10n.when_best,
        icon: LucideIcons.calendarDays,
        tint: accent,
        shape: ExpressShape.clover,
        child: WeekdayBars(values: stats.weekday, color: accent, height: 170),
      ),
    ];
  }
}

class _HabitScope extends StatelessWidget {
  const _HabitScope({
    required this.habits,
    required this.selected,
    required this.onSelected,
  });

  final List<Habit> habits;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return ExpressChipBar(
      children: [
        ExpressChip(
          label: context.l10n.all,
          icon: LucideIcons.layers,
          active: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final habit in habits)
          ExpressChip(
            label: habit.name,
            glyph: habit.icon,
            active: selected == habit.id,
            tint: habit.color,
            onTap: () => onSelected(habit.id),
          ),
      ],
    );
  }
}

class _ConsistencyHero extends StatelessWidget {
  const _ConsistencyHero({required this.percent, required this.accent});

  final int percent;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ExpressCard(
      radius: 30,
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          ExpressWaveRing(
            value: percent / 100,
            color: accent,
            track: context.colors.surfaceContainerHighest,
            size: 168,
            stroke: 18,
            waves: 10,
            amplitude: 2.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: ExpressType.display.at(
                    38,
                    height: 1,
                    spacing: -1,
                    color: context.colors.onSurface,
                    tabular: true,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.completion_rate_short,
                  style: ExpressType.body.at(
                    12.5,
                    weight: 700,
                    color: context.tokens.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.last_90_days,
            style: ExpressType.body.at(
              13,
              weight: 700,
              color: context.tokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 110),
      child: AppEmptyState(
        icon: LucideIcons.sparkles,
        title: text,
        compact: true,
      ),
    );
  }
}
