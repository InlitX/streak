import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/app_strings.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/statistics/widgets/monthly_area_chart.dart';
import 'package:streak/features/statistics/widgets/stat_charts.dart';
import 'package:streak/features/statistics/widgets/year_heatmap.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _year = DateTime.now().year;
  String? _habitId; // null = todos

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('statistics'))),
      body: SafeArea(
        top: false,
        child: Consumer<HabitsController>(
          builder: (context, controller, _) {
            final all = controller.habits;
            if (all.isEmpty) {
              return AppEmptyState(
                icon: LucideIcons.chartColumn,
                title: context.tr('no_data_yet'),
                message: context.tr('stats_empty'),
              );
            }

            if (_habitId != null && controller.byId(_habitId!) == null) {
              _habitId = null;
            }
            final scoped =
                _habitId == null ? all : [controller.byId(_habitId!)!];
            final accent =
                _habitId == null ? context.colors.primary : scoped.first.color;
            final stats = _Stats.compute(scoped, _year);
            final currentYear = DateTime.now().year;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _HabitFilter(
                  habits: all,
                  selected: _habitId,
                  onSelected: (id) => setState(() => _habitId = id),
                ),
                const SizedBox(height: 16),
                _YearNavigator(
                  year: _year,
                  canGoForward: _year < currentYear,
                  onChanged: (delta) => setState(() => _year += delta),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: YearHeatmap(
                      year: _year,
                      dailyCounts: stats.dailyCounts,
                      maxCount: scoped.length,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: LucideIcons.hash,
                        color: accent,
                        value: stats.total,
                        label: context.tr('completions'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        icon: LucideIcons.trophy,
                        color: context.tokens.success,
                        value: stats.bestStreak,
                        label: context.tr('best_streak'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: LucideIcons.flame,
                        color: context.tokens.warning,
                        value: stats.currentStreak,
                        label: context.tr('current_streak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        icon: LucideIcons.percent,
                        color: context.tokens.info,
                        value: stats.monthRate,
                        suffix: '%',
                        label: context.tr('completion_rate'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _PerfectStreakCard(streak: stats.currentStreak, color: accent),
                const SizedBox(height: 24),
                _ChartCard(
                  title: context.tr('completions_per_month'),
                  icon: LucideIcons.chartArea,
                  color: accent,
                  child: MonthlyAreaChart(values: stats.monthly),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ChartCard(
                          title: context.tr('completion_time'),
                          icon: LucideIcons.clock,
                          color: accent,
                          child: stats.hourSamples >= 5
                              ? HourLine(
                                  values: stats.hours,
                                  color: accent,
                                  height: 120,
                                )
                              : _ChartPlaceholder(
                                  text: context.tr('not_enough_data'),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ChartCard(
                          title: context.tr('when_best'),
                          icon: LucideIcons.chartColumn,
                          color: accent,
                          child: WeekdayBars(
                            values: stats.weekday,
                            color: accent,
                            height: 120,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: context.tr('streak_evolution'),
                  icon: LucideIcons.trendingUp,
                  color: accent,
                  child: StreakLine(
                    values: stats.streakSeries,
                    color: accent,
                    startDate: DateTime.now().atMidnight.subtract(
                      const Duration(days: 89),
                    ),
                    height: 210,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Stats {
  _Stats({
    required this.dailyCounts,
    required this.monthly,
    required this.weekday,
    required this.hours,
    required this.hourSamples,
    required this.streakSeries,
    required this.total,
    required this.activeDays,
    required this.currentStreak,
    required this.bestStreak,
    required this.monthRate,
  });

  final Map<String, int> dailyCounts;
  final List<int> monthly;
  final List<int> weekday; // 7
  final List<int> hours; // 24
  final int hourSamples;
  final List<double> streakSeries;
  final int total;
  final int activeDays;
  final int currentStreak;
  final int bestStreak;
  final int monthRate;

  static _Stats compute(List<Habit> habits, int year) {
    final daily = <String, int>{};
    final monthly = List<int>.filled(12, 0);
    final weekday = List<int>.filled(7, 0);
    final hours = List<int>.filled(24, 0);
    var total = 0;
    var hourSamples = 0;

    for (final habit in habits) {
      // Negatives store relapses (failures): exclude from completion totals.
      if (habit.kind == HabitKind.negative) continue;
      for (final entry in habit.completions.values) {
        if (entry.count < habit.perDayTarget) continue;
        final date = parseDayKey(entry.date);
        if (date.year != year) continue;
        daily[entry.date] = (daily[entry.date] ?? 0) + 1;
        monthly[date.month - 1]++;
        weekday[date.weekday - 1]++;
        total++;
        if (entry.hour != null) {
          hours[entry.hour!.clamp(0, 23)]++;
          hourSamples++;
        }
      }
    }

    // Cumulative completions over the last 90 days.
    final today = DateTime.now().atMidnight;
    var running = 0;
    final streakSeries = List<double>.generate(90, (i) {
      final date = today.subtract(Duration(days: 89 - i));
      for (final habit in habits) {
        if (habit.isCompletedOn(date)) running++;
      }
      return running.toDouble();
    });

    var done = 0;
    for (var i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      for (final habit in habits) {
        if (habit.isCompletedOn(date)) done++;
      }
    }
    final possible = habits.length * 30;
    final monthRate = possible == 0 ? 0 : (done / possible * 100).round();

    final currentStreak = habits
        .map((h) => h.currentStreak)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final bestStreak = habits
        .map((h) => h.longestStreak)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return _Stats(
      dailyCounts: daily,
      monthly: monthly,
      weekday: weekday,
      hours: hours,
      hourSamples: hourSamples,
      streakSeries: streakSeries,
      total: total,
      activeDays: daily.length,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      monthRate: monthRate,
    );
  }
}

class _HabitFilter extends StatelessWidget {
  const _HabitFilter({
    required this.habits,
    required this.selected,
    required this.onSelected,
  });

  final List<Habit> habits;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: context.tr('all'),
            color: context.colors.primary,
            active: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final habit in habits)
            _FilterChip(
              label: habit.name,
              color: habit.color,
              active: selected == habit.id,
              onTap: () => onSelected(habit.id),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : context.tokens.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _YearNavigator extends StatelessWidget {
  const _YearNavigator({
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ArrowButton(
          icon: LucideIcons.chevronLeft,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(-1);
          },
        ),
        SizedBox(
          width: 96,
          child: Text(
            '$year',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
            ),
          ),
        ),
        _ArrowButton(
          icon: LucideIcons.chevronRight,
          onTap: canGoForward
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged(1);
                }
              : null,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 22,
        color: enabled
            ? context.colors.onSurface
            : context.tokens.muted.withValues(alpha: 0.4),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.suffix = '',
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                _IconSquare(icon: icon, color: color),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedCounter(
              value: value,
              suffix: suffix,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -0.5,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: context.tokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerfectStreakCard extends StatelessWidget {
  const _PerfectStreakCard({required this.streak, required this.color});

  final int streak;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = streak > 0
        ? context.tr('streak_on', {'n': '$streak'})
        : context.tr('streak_off');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed 2-line height: a wrapping Text mismeasures inside IntrinsicHeight.
            SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
                  _IconSquare(icon: icon, color: color),
                ],
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // No fixed height so the empty state never clips; minHeight matches the charts.
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

class _IconSquare extends StatelessWidget {
  const _IconSquare({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
