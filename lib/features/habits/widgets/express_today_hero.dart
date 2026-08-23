import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_tabs.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/express/express_wave.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/daily_quote.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/today_intro.dart';

class ExpressTodayHero extends StatelessWidget {
  const ExpressTodayHero({
    super.key,
    required this.habits,
    required this.done,
    required this.total,
  });

  final List<Habit> habits;
  final int done;
  final int total;

  String _greeting(BuildContext context) {
    final hour = AppClock.now().hour;
    if (hour < 12) return context.l10n.good_morning;
    if (hour < 19) return context.l10n.good_afternoon;
    return context.l10n.good_evening;
  }

  String _date(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final text = DateFormat('EEEE, d MMM', locale).format(AppClock.now());
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final ratio = total == 0 ? 0.0 : done / total;
    final allDone = total > 0 && done == total;

    var streak = 0;
    var best = 0;
    var consistency = 0;
    for (final habit in habits) {
      if (habit.currentStreak > streak) streak = habit.currentStreak;
      if (habit.longestStreak > best) best = habit.longestStreak;
      consistency += habit.consistency;
    }
    if (habits.isNotEmpty) consistency = (consistency / habits.length).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ExpressType.display.at(
                      27,
                      height: 1.05,
                      spacing: -0.2,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    _date(context),
                    style: ExpressType.body.at(
                      12,
                      weight: 600,
                      color: context.tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CountLine(done: done, total: total),
          ],
        ),
        const SizedBox(height: 12),
        ExpressCard(
          radius: 26,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PulseLabel(
                text: total == 0
                    ? context.l10n.no_habits_yet
                    : allDone
                    ? context.l10n.all_done_today
                    : context.l10n.x_of_y_completed('$done', '$total'),
              ),
              const SizedBox(height: 11),
              ExpressWaveBar(
                value: ratio,
                color: allDone ? context.tokens.success : scheme.primary,
                track: scheme.surfaceContainerHighest,
                stroke: 9,
                wavelength: 34,
                amplitude: 3.2,
              ),
              const SizedBox(height: 14),
              ExpressMiniRow(
                children: [
                  ExpressMiniStat(
                    icon: LucideIcons.flame,
                    value: '$streak',
                    label: context.l10n.current_streak,
                    tint: scheme.primary,
                  ),
                  ExpressMiniStat(
                    icon: LucideIcons.trophy,
                    value: '$best',
                    label: context.l10n.best_streak,
                    tint: context.tokens.warning,
                  ),
                  ExpressMiniStat(
                    icon: LucideIcons.target,
                    value: '$consistency%',
                    label: context.l10n.completion_rate_short,
                    tint: context.tokens.success,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const DailyQuote(),
      ],
    );
  }
}

class _PulseLabel extends StatefulWidget {
  const _PulseLabel({required this.text});

  final String text;

  @override
  State<_PulseLabel> createState() => _PulseLabelState();
}

class _PulseLabelState extends State<_PulseLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ExpressType.body.at(
              13.5,
              weight: 700,
              spacing: 0.2,
              color: context.tokens.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountLine extends StatefulWidget {
  const _CountLine({required this.done, required this.total});

  final int done;
  final int total;

  @override
  State<_CountLine> createState() => _CountLineState();
}

class _CountLineState extends State<_CountLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: Express.slow,
  );

  @override
  void initState() {
    super.initState();
    TodayIntro.tick.addListener(_replay);
    if (TodayIntro.claim(ExpressTodayHero)) {
      _pop.forward();
    } else {
      _pop.value = 1;
    }
  }

  @override
  void dispose() {
    TodayIntro.tick.removeListener(_replay);
    _pop.dispose();
    super.dispose();
  }

  void _replay() {
    if (!mounted || !TodayIntro.claim(ExpressTodayHero)) return;
    _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return AnimatedBuilder(
      animation: _pop,
      builder: (context, child) {
        final t = Express.bouncy.transform(_pop.value);
        return Transform.scale(
          scale: 0.82 + 0.18 * t,
          child: Opacity(opacity: _pop.value.clamp(0.0, 1.0), child: child),
        );
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${widget.done}',
              style: ExpressType.display.at(
                44,
                height: 1,
                spacing: -1,
                color: scheme.primary,
                tabular: true,
              ),
            ),
            Text(
              '/${widget.total}',
              style: ExpressType.display.at(
                21,
                height: 1,
                weight: 750,
                color: context.tokens.muted,
                tabular: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpressTodayHeader extends StatelessWidget {
  const ExpressTodayHeader({
    super.key,
    required this.habits,
    required this.done,
    required this.total,
    required this.mode,
    required this.onMode,
    required this.showModes,
    required this.categories,
    required this.category,
    required this.onCategory,
  });

  final List<Habit> habits;
  final int done;
  final int total;
  final HeatmapMode mode;
  final ValueChanged<HeatmapMode> onMode;
  final bool showModes;
  final List<String> categories;
  final String? category;
  final ValueChanged<String?> onCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpressTodayHero(habits: habits, done: done, total: total),
        if (showModes) ...[
          const SizedBox(height: 18),
          ExpressTabs(
            labels: [
              context.l10n.week,
              context.l10n.month,
              context.l10n.year,
            ],
            index: mode.index.clamp(0, 2),
            onChanged: (i) => onMode(HeatmapMode.values[i]),
          ),
        ],
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          ExpressChipBar(
            children: [
              ExpressChip(
                label: context.l10n.all,
                active: category == null,
                onTap: () => onCategory(null),
              ),
              for (final name in categories)
                ExpressChip(
                  label: context.categoryLabel(name),
                  active: category == name,
                  onTap: () => onCategory(name),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
