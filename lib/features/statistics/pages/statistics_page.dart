import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/stat_columns.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_stats_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/quant_stats_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/saved_money.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/statistics/data/habit_stats.dart';
import 'package:streak/features/statistics/pages/express_statistics_page.dart';
import 'package:streak/features/statistics/pages/minimal_statistics_page.dart';
import 'package:streak/features/statistics/widgets/stat_charts.dart';
import 'package:streak/features/statistics/widgets/statistics_filters.dart';
import 'package:streak/features/statistics/widgets/stat_donut.dart';
import 'package:streak/features/statistics/widgets/stat_gauge.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';
import 'package:streak/features/statistics/widgets/stat_line_charts.dart';
import 'package:streak/features/statistics/widgets/year_heatmap.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
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
    final settings = context.watch<SettingsController>();
    if (settings.isExpressStyle) return const ExpressStatisticsPage();
    if (settings.isMinimalStyle) return const MinimalStatisticsPage();
    final minimal = settings.isMinimalStyle;

    return Scaffold(
      appBar: minimal
          ? AppBar(toolbarHeight: 52)
          : AppBar(title: Text(context.l10n.statistics)),
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
          final scoped =
              _habitId == null ? all : [controller.byId(_habitId!)!];
          final accent =
              _habitId == null ? context.colors.primary : scoped.first.color;
          final stats = _statsFor(scoped, all);
          final currentYear = AppClock.now().year;

          return ListView(
            padding: context.pagePadding(
              16,
              minimal ? 0 : 8,
              16,
              minimal ? 28 : 104,
            ),
            children: spanned(context, [
              if (minimal)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: MinimalTitle(title: context.l10n.statistics),
                ),
              HabitFilter(
                habits: all,
                selected: _habitId,
                onSelected: (id) => setState(() => _habitId = id),
              ),
              const SizedBox(height: 16),
              YearNavigator(
                year: _year,
                canGoForward: _year < currentYear,
                onChanged: (delta) => setState(() => _year += delta),
              ),
              const SizedBox(height: 16),
              StatReveal(
                child: Container(
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: YearHeatmap(
                    year: _year,
                    dailyCounts: stats.dailyCounts,
                    maxCount: scoped.length,
                    color: accent,
                    habit: _habitId == null ? null : scoped.first,
                  ),
                ),
                ),
              ),
              const SpanEnd(),
              const SizedBox(height: 16),
              StatReveal(
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: MiniStat(
                          icon: LucideIcons.hash,
                          color: accent,
                          value: '${stats.total}',
                          label: context.l10n.completions,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MiniStat(
                          icon: LucideIcons.trophy,
                          color: context.tokens.success,
                          value: '${stats.bestStreak}',
                          label: context.l10n.best_streak,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StatReveal(
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: MiniStat(
                          icon: LucideIcons.flame,
                          color: context.tokens.warning,
                          value: '${stats.currentStreak}',
                          label: context.l10n.current_streak,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MiniStat(
                          icon: LucideIcons.percent,
                          color: context.tokens.info,
                          value: '${stats.monthRate}%',
                          label: context.l10n.completion_rate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (scoped.length == 1 && scoped.first.hasCost) ...[
                const SizedBox(height: 12),
                StatReveal(child: SavedMoneyStats(habit: scoped.first)),
              ],
              if (scoped.length == 1 &&
                  scoped.first.kind == HabitKind.quantitative) ...[
                const SizedBox(height: 12),
                StatReveal(child: QuantStatsRow(habit: scoped.first)),
              ],
              if (context.watch<SettingsController>().focusEnabled &&
                  context.watch<FocusController>().sessionCount > 0) ...[
                const SizedBox(height: 12),
                StatReveal(
                  child: _FocusStats(habitId: _habitId, accent: accent),
                ),
              ],
              const SizedBox(height: 16),
              StatReveal(
                child: _PerfectStreakCard(
                  streak: stats.perfectStreak,
                  best: stats.bestPerfectStreak,
                  color: accent,
                ),
              ),
              const SizedBox(height: 24),
              _TrendCard(stats: stats, color: accent),
              const SizedBox(height: 16),
              StatReveal(
                child: StatCard(
                  title: context.l10n.completions_per_month,
                  icon: LucideIcons.chartSpline,
                  color: accent,
                  child: stats.total > 0
                      ? MonthlyLine(
                          key: ValueKey('monthly-$_year-$_habitId'),
                          values: stats.monthly,
                          color: accent,
                          year: _year,
                        )
                      : _ChartPlaceholder(text: context.l10n.not_enough_data),
                ),
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatCard(
                        title: context.l10n.completion_rate_short,
                        icon: LucideIcons.target,
                        color: accent,
                        child: Center(
                          child: ConsistencyGauge(
                            percent: stats.consistency,
                            color: accent,
                            caption: context.l10n.last_90_days,
                            size: 130,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: context.l10n.when_best,
                        icon: LucideIcons.calendarDays,
                        color: accent,
                        child: WeekdayBars(
                          values: stats.weekday,
                          color: accent,
                          height: 150,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StatReveal(
                child: StatCard(
                  title: context.l10n.completion_time,
                  icon: LucideIcons.clock,
                  color: accent,
                  child: stats.hourSamples >= 5
                      ? HourArea(values: stats.hours, color: accent)
                      : _ChartPlaceholder(text: context.l10n.not_enough_data),
                ),
              ),

              if (_habitId == null && all.length > 1) ...[
                const SizedBox(height: 16),
                StatReveal(
                  child: StatCard(
                    title: context.l10n.by_habit,
                    icon: LucideIcons.chartPie,
                    color: accent,
                    child: HabitDonut(entries: _ranking(all, stats)),
                  ),
                ),
                const SizedBox(height: 16),
                StatReveal(
                  child: _RankingCard(
                    accent: accent,
                    entries: _ranking(all, stats, limit: all.length),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              StatReveal(
                child: _SecondaryStats(stats: stats, accent: accent),
              ),
            ]),
          );
        },
      ),
    );
  }
}

List<({String name, Color color, int count})> _ranking(
  List<Habit> habits,
  HabitStats stats, {
  int limit = 5,
}) {
  final ranked = [
    for (final habit in habits)
      (
        name: habit.name,
        color: habit.color,
        count: stats.perHabit[habit.id] ?? 0,
      ),
  ]..sort((a, b) => b.count.compareTo(a.count));
  return ranked.take(limit).where((e) => e.count > 0).toList();
}

class _RankingCard extends StatefulWidget {
  const _RankingCard({required this.entries, required this.accent});

  final List<({String name, Color color, int count})> entries;
  final Color accent;

  @override
  State<_RankingCard> createState() => _RankingCardState();
}

class _RankingCardState extends State<_RankingCard> {
  static const _collapsed = 5;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final shown = _expanded ? entries : entries.take(_collapsed).toList();

    return StatCard(
      title: context.l10n.ranking,
      icon: LucideIcons.listOrdered,
      color: widget.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: HabitRanking(
              key: ValueKey(shown.length),
              entries: shown,
            ),
          ),
          if (entries.length > _collapsed)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  foregroundColor: widget.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  _expanded ? context.l10n.see_less : context.l10n.see_more,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.stats, required this.color});

  final HabitStats stats;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final start = AppClock.now().atMidnight.subtract(
          const Duration(days: HabitStats.window - 1),
        );
    return StatCard(
      title: context.l10n.streak_evolution,
      icon: LucideIcons.trendingUp,
      color: color,
      child: TrendChart(
        key: const ValueKey('streak'),
        values: stats.streakSeries,
        color: color,
        startDate: start,
      ),
    );
  }
}

class _SecondaryStats extends StatelessWidget {
  const _SecondaryStats({required this.stats, required this.accent});

  final HabitStats stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final months = DateFormat.MMMM(
      Localizations.localeOf(context).toString(),
    );
    final bestMonth = stats.total == 0
        ? '—'
        : months.format(DateTime(2024, stats.bestMonth + 1));

    Widget cell(Widget child) => Expanded(child: child);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.overview.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: context.tokens.muted,
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell(
                MiniStat(
                  value: '${stats.activeDays}',
                  label: context.l10n.active_days,
                  icon: LucideIcons.calendarCheck,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              cell(
                MiniStat(
                  value: '${stats.perfectDays}',
                  label: context.l10n.perfect_days,
                  icon: LucideIcons.sparkles,
                  color: context.tokens.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell(
                MiniStat(
                  value: stats.perWeek.toStringAsFixed(1),
                  label: context.l10n.per_week,
                  icon: LucideIcons.repeat2,
                  color: context.tokens.info,
                ),
              ),
              const SizedBox(width: 12),
              cell(
                MiniStat(
                  value: bestMonth,
                  label: context.l10n.best_month,
                  icon: LucideIcons.calendarRange,
                  color: context.tokens.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerfectStreakCard extends StatelessWidget {
  const _PerfectStreakCard({
    required this.streak,
    required this.best,
    required this.color,
  });

  final int streak;
  final int best;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = streak > 0
        ? context.l10n.streak_on('$streak')
        : context.l10n.streak_off;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.perfect_streak.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: context.tokens.muted,
                  ),
                ),
              ),
              if (best > streak) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '${context.l10n.best_streak}  $best',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: context.tokens.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: AppEmptyState(
        icon: LucideIcons.sparkles,
        title: text,
        compact: true,
      ),
    );
  }
}

class _FocusStats extends StatelessWidget {
  const _FocusStats({required this.habitId, required this.accent});

  final String? habitId;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    final seconds = habitId == null
        ? focus.totalSeconds
        : focus.secondsForHabit(habitId!);
    final sessions = habitId == null
        ? focus.sessionCount
        : focus.sessions.where((s) => s.habitId == habitId).length;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => AppNavigator.push(FocusStatsPage(habitId: habitId)),
        child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: MiniStat(
                icon: LucideIcons.timer,
                color: accent,
                value: formatHoursShort(seconds),
                label: context.l10n.focus_total,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MiniStat(
                icon: LucideIcons.circlePlay,
                color: context.tokens.info,
                value: '$sessions',
                label: context.l10n.focus_sessions,
              ),
            ),
            if (context.watch<SettingsController>().focusDailyGoal > 0) ...[
              const SizedBox(width: 12),
              Expanded(
                child: MiniStat(
                  icon: LucideIcons.target,
                  color: context.tokens.success,
                  value: context.l10n.focus_goal_today(
                    formatHoursShort(focus.secondsForDay(AppClock.now())),
                    formatHoursShort(
                      context.watch<SettingsController>().focusDailyGoal * 60,
                    ),
                  ),
                  label: context.l10n.focus_daily_goal,
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
