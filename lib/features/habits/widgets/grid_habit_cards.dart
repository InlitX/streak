import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/features/habits/data/habit.dart';
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
    required this.onTap,
    this.size = 52,
  });

  final Habit habit;
  final bool done;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
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
            context.watch<SettingsController>().isCircleCheck
                ? size / 2
                : size * 0.28,
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

bool _hasCover(Habit habit) =>
    habit.coverPath.isNotEmpty && File(habit.coverPath).existsSync();

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
          Positioned.fill(
            child: Image.file(File(habit.coverPath), fit: BoxFit.cover),
          ),
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
    final today = DateTime.now().atMidnight;
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
    required this.onTap,
  });

  final Habit habit;
  final DateTime date;
  final String label;
  final void Function(DateTime date) onTap;

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedOn(date);
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
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: habit.color.withValues(alpha: done ? 1 : 0.14),
                borderRadius: BorderRadius.circular(
                  context.watch<SettingsController>().isCircleCheck ? 15 : 9,
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
    final today = DateTime.now().atMidnight;
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
                  onTap: onToggleToday,
                ),
              ],
            ),
            const SizedBox(height: 14),
            HabitHeatmap(
              habit: habit,
              mode: HeatmapMode.year,
              compact: true,
              circle: context.watch<SettingsController>().isCircleCheck,
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
    final today = DateTime.now().atMidnight;
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
              circle: context.watch<SettingsController>().isCircleCheck,
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
