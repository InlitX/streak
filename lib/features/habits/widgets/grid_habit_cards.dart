import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/core/widgets/scrolling_text.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/amount_actions.dart';
import 'package:streak/features/habits/data/quant_progress.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/heatmap_path.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
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
    return Semantics(
      button: true,
      label: done
          ? context.l10n.a11y_mark_not_done(habit.name)
          : context.l10n.a11y_mark_done(habit.name),
      child: GestureDetector(
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

  Future<void> _add(BuildContext context, DateTime today) async {
    final controller = context.read<HabitsController>();
    final allowed =
        await confirmUnscheduledDay(context, habit: habit, date: today);
    if (!allowed) return;
    HapticFeedback.lightImpact();
    await controller.addProgress(habit.id, today, habit.incrementAmount);
  }

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now();
    final count = habit.completions[today.dayKey]?.count ?? 0;
    final progress = QuantProgress.of(count: count, target: habit.perDayTarget);
    final reached = progress.reachedGoal;
    final settled = reached ? progress.reachedColor(habit.color) : habit.color;

    return Semantics(
      button: true,
      label: context.l10n.a11y_add_amount(habit.name),
      child: GestureDetector(
        onTap: () => _add(context, today),
        onLongPress: () => unawaited(addCustomAmount(context, habit)),
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
                      child: ColoredBox(
                        color: progress.activeColor(habit.color),
                      ),
                    ),
                  ),
                ),
                if (showCheck)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.fraction),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => Icon(
                      Icons.check_rounded,
                      size: size * 0.5,
                      color: reached || t >= 0.45 ? Colors.white : habit.color,
                    ),
                  ),
              ],
            ),
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
  });

  final Habit habit;
  final VoidCallback onOpen;
  final void Function(DateTime date) onToggleDay;
  final VoidCallback? onLongPress;

  static const _cell = 28.0;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final circle = context.watch<SettingsController>().isCircleCheck;
    final labels = WeekdayLabels.shortMonFirst(
      Localizations.localeOf(context).languageCode,
    );
    final scale = MediaQuery.textScalerOf(context).scale(11) / 11;
    final columns = scale > 1.6 ? 3 : (scale > 1.3 ? 4 : 5);

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onOpen,
        onLongPress: onLongPress,
        child: _shell(
          context,
          habit,
          padding: const EdgeInsets.all(12),
          Row(
            children: [
              _GlyphTile(habit: habit, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: ScrollingText(
                  habit.name,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: _titleColor(context, habit),
                  ),
                ),
              ),
              for (var i = columns - 1; i >= 0; i--)
                _DayCell(
                  habit: habit,
                  date: today.subtract(Duration(days: i)),
                  label: labels[today.subtract(Duration(days: i)).weekday - 1],
                  circle: circle,
                  size: _cell,
                  onTap: onToggleDay,
                ),
            ],
          ),
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
    required this.size,
    required this.onTap,
  });

  final Habit habit;
  final DateTime date;
  final String label;
  final bool circle;
  final double size;
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
          ExcludeSemantics(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _mutedColor(context, habit),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          quant && today
              ? _QuantTile(
                  habit: habit,
                  circle: circle,
                  size: size,
                  showCheck: false,
                )
              : Semantics(
                  button: true,
                  label: heatmapDayLabel(context, habit, date),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(date);
                    },
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          circle ? size / 2 : 9,
                        ),
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

    return Semantics(
      button: true,
      child: GestureDetector(
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
                    child: ScrollingText(
                      habit.name,
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
              _GridYearStrip(
                habit: habit,
                circle: circle,
                onToggle: onToggleDay,
              ),
            ],
          ),
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

    return Semantics(
      button: true,
      child: GestureDetector(
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
                        ScrollingText(
                          habit.name,
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
                child: _GridMonthCalendar(
                  habit: habit,
                  circle: circle,
                  onToggle: onToggleDay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridYearStrip extends StatefulWidget {
  const _GridYearStrip({
    required this.habit,
    required this.circle,
    required this.onToggle,
  });

  final Habit habit;
  final bool circle;
  final void Function(DateTime date) onToggle;

  @override
  State<_GridYearStrip> createState() => _GridYearStripState();
}

class _GridYearStripState extends State<_GridYearStrip> {
  static const _weeks = 53;
  static const _cell = 13.0;

  final _scroll = ScrollController();
  bool _scrolled = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final start = monday.subtract(const Duration(days: 7 * (_weeks - 1)));
    final months = DateFormat.MMM(Localizations.localeOf(context).languageCode);
    final path = heatmapPathOn(context);
    final gap = path ? heatmapPathGap : 3.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrolled && _scroll.hasClients) {
        _scrolled = true;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });

    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: withHeatmapPath(
        on: path,
        columns: _weeks,
        rows: 7,
        cell: _cell,
        gap: gap,
        top: 14,
        inkFor: (column, row) {
          final date = start.add(Duration(days: column * 7 + row));
          return widget.habit.isCompletedOn(date)
              ? heatmapPathColor(context, widget.habit.color)
              : context.colors.surfaceContainerHighest;
        },
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_weeks, (column) {
          final first = start.add(Duration(days: column * 7));
          final previous = start.add(Duration(days: (column - 1) * 7));
          final newMonth = column == 0 || first.month != previous.month;

          return Padding(
            padding: EdgeInsets.only(right: gap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 14,
                  width: _cell,
                  child: newMonth
                      ? OverflowBox(
                          maxWidth: 40,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            months.format(first),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: context.tokens.muted,
                            ),
                          ),
                        )
                      : null,
                ),
                for (var row = 0; row < 7; row++)
                  Padding(
                    padding: EdgeInsets.only(bottom: gap),
                    child: _yearCell(context, first.add(Duration(days: row))),
                  ),
              ],
            ),
          );
        }),
        ),
      ),
    );
  }

  Widget _yearCell(BuildContext context, DateTime date) {
    return ExcludeSemantics(
      child: GestureDetector(
        onTap: date.isAfter(AppClock.now().atMidnight)
            ? null
            : () => widget.onToggle(date),
        child: SizedBox(
          width: _cell,
          height: _cell,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: heatmapCellColor(context, widget.habit, date),
              borderRadius: BorderRadius.circular(widget.circle ? _cell / 2 : 3),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridMonthCalendar extends StatelessWidget {
  const _GridMonthCalendar({
    required this.habit,
    required this.circle,
    required this.onToggle,
  });

  final Habit habit;
  final bool circle;
  final void Function(DateTime date) onToggle;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final weekStart = context.watch<SettingsController>().weekStart;
    final first = DateTime(today.year, today.month, 1).startOfWeek(weekStart);
    final lastDay = DateTime(today.year, today.month + 1, 0);
    final weeks =
        (lastDay.startOfWeek(weekStart).difference(first).inDays / 7).round() +
        1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var w = 0; w < weeks; w++)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: List.generate(7, (d) {
                final date = first.add(Duration(days: w * 7 + d));
                final inMonth = date.month == today.month;
                final future = date.isAfter(today);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Semantics(
                        button: inMonth && !future,
                        label: inMonth
                            ? heatmapDayLabel(context, habit, date)
                            : null,
                        child: GestureDetector(
                          onTap: inMonth && !future
                              ? () => onToggle(date)
                              : null,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: !inMonth
                                  ? Colors.transparent
                                  : future
                                  ? context.colors.surfaceContainerHighest
                                        .withValues(alpha: 0.4)
                                  : heatmapCellColor(context, habit, date),
                              borderRadius: BorderRadius.circular(
                                circle ? 999 : 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
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
    (HeatmapMode.week, Icons.checklist_rounded),
    (HeatmapMode.month, Icons.grid_view_rounded),
    (HeatmapMode.year, Icons.view_agenda_outlined),
  ];

  double _slot(HeatmapMode value) {
    final index = _options.indexWhere((option) => option.$1 == value);
    return index <= 0 ? -1 : (index == 1 ? 0 : 1);
  }

  String _label(BuildContext context, HeatmapMode value) => switch (value) {
        HeatmapMode.week => context.l10n.week,
        HeatmapMode.year => context.l10n.year,
        _ => context.l10n.month,
      };

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
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(_slot(mode), 0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (value, icon) in _options)
                Semantics(
                  button: true,
                  selected: value == mode,
                  label: _label(context, value),
                  child: GestureDetector(
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
                      child: AnimatedScale(
                        scale: value == mode ? 1.12 : 1,
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutBack,
                        child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(
                            end: value == mode
                                ? context.colors.primary
                                : context.tokens.muted,
                          ),
                          duration: const Duration(milliseconds: 260),
                          builder: (context, tint, _) =>
                              Icon(icon, size: 24, color: tint),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
