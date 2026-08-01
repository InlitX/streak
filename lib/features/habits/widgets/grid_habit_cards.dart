import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/quant_progress.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class _GlyphTile extends StatelessWidget {
  const _GlyphTile({required this.habit, this.size = 52});

  final Habit habit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: habit.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: HabitGlyph(
        glyph: habit.icon,
        color: habit.color,
        size: size * 0.46,
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.habit,
    required this.done,
    required this.circle,
    required this.onTap,
    this.size = 52,
  });

  final Habit habit;
  final bool done;
  final bool circle;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (habit.kind == HabitKind.quantitative) {
      return _QuantTile(habit: habit, circle: circle, size: size);
    }
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: habit.color.withValues(alpha: done ? 1 : 0.16),
          borderRadius: BorderRadius.circular(
            circle ? size / 2 : size * 0.28,
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          size: size * 0.5,
          color: done ? Colors.white : habit.color.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _QuantTile extends StatelessWidget {
  const _QuantTile({
    required this.habit,
    required this.circle,
    required this.size,
    this.showCheck = true,
  });

  final Habit habit;
  final bool circle;
  final double size;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now();
    final count = habit.completions[today.dayKey]?.count ?? 0;
    final progress = QuantProgress.of(count: count, target: habit.perDayTarget);
    final reached = progress.reachedGoal;
    final settled = reached ? progress.reachedColor(habit.color) : habit.color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<HabitsController>().addProgress(
          habit.id,
          today,
          habit.incrementAmount,
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            circle ? size / 2 : size * 0.28,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: settled.withValues(alpha: reached ? 1 : 0.16),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress.fraction),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) => FractionallySizedBox(
                    heightFactor: t.clamp(0.0, 1.0),
                    widthFactor: 1,
                    child: ColoredBox(color: progress.activeColor(habit.color)),
                  ),
                ),
              ),
              if (showCheck)
                Icon(
                  Icons.check_rounded,
                  size: size * 0.5,
                  color: reached
                      ? Colors.white
                      : habit.color.withValues(alpha: 0.85),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _hasCover(Habit habit) => CoverImage.exists(habit.coverPath);

Widget _shell(
  BuildContext context,
  Habit habit,
  Widget child, {
  EdgeInsets? padding,
}) {
  final cover = _hasCover(habit);
  return Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
    ),

    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: cover
            ? Colors.white.withValues(alpha: 0.14)
            : context.colors.surfaceContainerHighest,
      ),
    ),
    child: Stack(
      children: [
        if (cover) ...[
          Positioned.fill(child: CoverImage(path: habit.coverPath)),
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.7)),
          ),
        ],
        Padding(
          padding: padding ?? const EdgeInsets.all(14),
          child: child,
        ),
      ],
    ),
  );
}

Color _titleColor(BuildContext context, Habit habit) =>
    _hasCover(habit) ? Colors.white : context.colors.onSurface;

Color _mutedColor(BuildContext context, Habit habit) => _hasCover(habit)
    ? Colors.white.withValues(alpha: 0.72)
    : context.tokens.muted;

class GridWeekCard extends StatelessWidget {
  const GridWeekCard({
    super.key,
    required this.habit,
    required this.onOpen,
    required this.onToggleDay,
    this.onLongPress,
    this.days = 5,
  });

  final Habit habit;
  final VoidCallback onOpen;
  final void Function(DateTime date) onToggleDay;
  final VoidCallback? onLongPress;
  final int days;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final circle = context.watch<SettingsController>().isCircleCheck;
    final labels = WeekdayLabels.shortMonFirst(
      Localizations.localeOf(context).languageCode,
    );

    return GestureDetector(
      onTap: onOpen,
      onLongPress: onLongPress,
      child: _shell(
        context,
        habit,
        Row(
          children: [
            _GlyphTile(habit: habit, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _titleColor(context, habit),
                ),
              ),
            ),
            for (var i = days - 1; i >= 0; i--)
              _DayCell(
                habit: habit,
                date: today.subtract(Duration(days: i)),
                label: labels[today.subtract(Duration(days: i)).weekday - 1],
                circle: circle,
                onTap: onToggleDay,
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.habit,
    required this.date,
    required this.label,
    required this.circle,
    required this.onTap,
  });

  final Habit habit;
  final DateTime date;
  final String label;
  final bool circle;
  final void Function(DateTime date) onTap;

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedOn(date);
    final quant = habit.kind == HabitKind.quantitative;
    final today = date.atMidnight == AppClock.now().atMidnight;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _mutedColor(context, habit),
            ),
          ),
          const SizedBox(height: 6),
          quant && today
              ? _QuantTile(
                  habit: habit,
                  circle: circle,
                  size: 30,
                  showCheck: false,
                )
              : GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(date);
                  },
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(circle ? 15 : 9),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: habit.color.withValues(
                              alpha: done ? 1 : 0.14,
                            ),
                          ),
                          if (!done && quant)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: QuantProgress.of(
                                  count:
                                      habit.completions[date.dayKey]?.count ??
                                      0,
                                  target: habit.perDayTarget,
                                ).fraction,
                                widthFactor: 1,
                                child: ColoredBox(color: habit.color),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class GridYearCard extends StatelessWidget {
  const GridYearCard({
    super.key,
    required this.habit,
    required this.onOpen,
    required this.onToggleToday,
    required this.onToggleDay,
    this.onLongPress,
  });

  final Habit habit;
  final VoidCallback onOpen;
  final VoidCallback onToggleToday;
  final void Function(DateTime date) onToggleDay;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final circle = context.watch<SettingsController>().isCircleCheck;

    return GestureDetector(
      onTap: onOpen,
      onLongPress: onLongPress,
      child: _shell(
        context,
        habit,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _GlyphTile(habit: habit),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _titleColor(context, habit),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _CheckTile(
                  habit: habit,
                  done: habit.isCompletedOn(today),
                  circle: circle,
                  onTap: onToggleToday,
                ),
              ],
            ),
            const SizedBox(height: 14),
            HabitHeatmap(
              habit: habit,
              mode: HeatmapMode.year,
              compact: true,
              circle: circle,
              onToggle: onToggleDay,
            ),
          ],
        ),
      ),
    );
  }
}

class GridMonthCard extends StatelessWidget {
  const GridMonthCard({
    super.key,
    required this.habit,
    required this.onOpen,
    required this.onToggleToday,
    required this.onToggleDay,
    this.onLongPress,
  });

  final Habit habit;
  final VoidCallback onOpen;
  final VoidCallback onToggleToday;
  final void Function(DateTime date) onToggleDay;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final circle = context.watch<SettingsController>().isCircleCheck;
    final month = DateFormat.yMMM(
      Localizations.localeOf(context).toString(),
    ).format(today);

    return GestureDetector(
      onTap: onOpen,
      onLongPress: onLongPress,
      child: _shell(
        context,
        habit,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _CheckTile(
                  habit: habit,
                  done: habit.isCompletedOn(today),
                  circle: circle,
                  onTap: onToggleToday,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _titleColor(context, habit),
                        ),
                      ),
                      Text(
                        month,
                        style: TextStyle(
                          fontSize: 12,
                          color: _mutedColor(context, habit),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: HabitHeatmap(
                habit: habit,
                mode: HeatmapMode.month,
                compact: true,
                circle: circle,
                onToggle: onToggleDay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridViewSwitcher extends StatelessWidget {
  const GridViewSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final HeatmapMode mode;
  final ValueChanged<HeatmapMode> onChanged;

  static const _options = [
    (HeatmapMode.month, Icons.grid_view_rounded),
    (HeatmapMode.week, Icons.checklist_rounded),
    (HeatmapMode.year, Icons.view_agenda_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, icon) in _options)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(value);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: value == mode
                      ? context.colors.primary
                      : context.tokens.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
