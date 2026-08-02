import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/habits/widgets/note_widgets.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

enum HeatmapMode { week, month, year, mini }

Color heatmapCellColor(
  BuildContext context,
  Habit habit,
  DateTime date, {
  bool inScope = true,
}) {
  if (!inScope) return Colors.transparent;

  final scheme = context.colors;
  final today = AppClock.now().atMidnight;
  final beforeCreation = date.atMidnight.isBefore(habit.createdAt.atMidnight);

  if (!beforeCreation && !date.isAfter(today) && habit.isNeutralOn(date)) {
    return context.tokens.info.withValues(alpha: 0.5);
  }

  if (habit.kind == HabitKind.negative) {
    if (beforeCreation) {
      return scheme.surfaceContainerHighest.withValues(alpha: 0.4);
    }
    if (habit.completions.containsKey(date.dayKey)) return context.tokens.danger;
    final clean = habit.color.withValues(alpha: 0.4);
    return date.isAfter(today) ? clean.withValues(alpha: 0.18) : clean;
  }

  final count = habit.completions[date.dayKey]?.count ?? 0;
  if (count <= 0) {
    final base = scheme.surfaceContainerHighest;
    return date.isAfter(today) ? base.withValues(alpha: 0.4) : base;
  }
  final target = habit.effectiveTarget <= 0 ? 1 : habit.effectiveTarget;
  final ratio = (count / target).clamp(0.25, 1.0);
  return Color.lerp(habit.color.withValues(alpha: 0.4), habit.color, ratio)!;
}

class HabitHeatmap extends StatefulWidget {
  const HabitHeatmap({
    super.key,
    required this.habit,
    this.mode = HeatmapMode.mini,
    this.onToggle,
    this.onLongPress,
    this.compact = false,
    this.circle = false,
    this.showNotes = false,
  });

  final Habit habit;
  final HeatmapMode mode;
  final void Function(DateTime date)? onToggle;
  final void Function(DateTime date)? onLongPress;
  final bool showNotes;

  final bool compact;
  final bool circle;

  @override
  State<HabitHeatmap> createState() => _HabitHeatmapState();
}

class _HabitHeatmapState extends State<HabitHeatmap> {
  final _scroll = ScrollController();
  bool _scrolled = false;

  DateTime get _today => AppClock.now().atMidnight;

  DateTime _mondayOf(DateTime d) =>
      d.atMidnight.subtract(Duration(days: d.weekday - 1));

  Color _cell(BuildContext context, DateTime date, {bool inScope = true}) =>
      heatmapCellColor(context, widget.habit, date, inScope: inScope);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return switch (widget.mode) {
        HeatmapMode.week => _weekRow(context, compact: true),
        HeatmapMode.month => _monthCalendar(context),
        HeatmapMode.year => _yearGrid(context),
        HeatmapMode.mini => _grid(context, columns: 17, big: false),
      };
    }
    return switch (widget.mode) {
      HeatmapMode.week => _weekRow(context),
      HeatmapMode.month => _grid(context, columns: _monthColumns(), big: true),
      HeatmapMode.mini => _grid(context, columns: 17, big: false),
      HeatmapMode.year => _yearGrid(context),
    };
  }

  Widget _weekRow(BuildContext context, {bool compact = false}) {
    final weekStart = context.watch<SettingsController>().weekStart;
    final start = _today.startOfWeek(weekStart);
    final letters = WeekdayLabels.narrowFrom(
      Localizations.localeOf(context).languageCode,
      weekStart,
    );
    final height = compact ? 30.0 : 44.0;
    return Row(
      children: List.generate(7, (i) {
        final date = start.add(Duration(days: i));
        final future = date.isAfter(_today);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                Text(
                  letters[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.tokens.muted,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: future || widget.onToggle == null
                      ? null
                      : () => widget.onToggle!(date),
                  onLongPress: widget.onLongPress == null
                      ? null
                      : () => widget.onLongPress!(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: height,
                    decoration: BoxDecoration(
                      color: _cell(context, date),
                      borderRadius: BorderRadius.circular(
                        widget.circle ? height / 2 : (compact ? 9 : 12),
                      ),
                    ),
                  ),
                ),
                if (widget.showNotes) ...[
                  const SizedBox(height: 5),
                  NoteDots(
                    types: context.watch<NotesController>().typesFor(
                      widget.habit.id,
                      date.dayKey,
                    ),
                    size: 5,
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  int _monthColumns() {
    final first = DateTime(_today.year, _today.month, 1);
    final last = DateTime(_today.year, _today.month + 1, 0);
    final start = _mondayOf(first);
    final end = _mondayOf(last).add(const Duration(days: 6));
    return ((end.difference(start).inDays + 1) / 7).round();
  }

  Widget _tappable({
    required DateTime date,
    required bool enabled,
    required Widget child,
  }) {
    final open = enabled && !date.isAfter(_today);
    final onTap = open && widget.onToggle != null
        ? () => widget.onToggle!(date)
        : null;
    final onLongPress = open && widget.onLongPress != null
        ? () => widget.onLongPress!(date)
        : null;
    if (onTap == null && onLongPress == null) return child;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }

  Widget _grid(
    BuildContext context, {
    required int columns,
    required bool big,
  }) {
    final bool monthScope = widget.mode == HeatmapMode.month;
    final DateTime start;
    if (monthScope) {
      start = _mondayOf(DateTime(_today.year, _today.month, 1));
    } else {
      start = _mondayOf(_today).subtract(Duration(days: 7 * (columns - 1)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        var cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        cell = cell.clamp(6.0, big ? 34.0 : 18.0);
        final radius = widget.circle ? cell / 2 : (big ? 8.0 : 4.0);

        return Wrap(
          spacing: gap,
          children: List.generate(columns, (col) {
            return Column(
              children: List.generate(7, (row) {
                final date = start.add(Duration(days: col * 7 + row));
                final inScope = monthScope
                    ? date.month == _today.month && !date.isAfter(_today)
                    : !date.isAfter(_today);
                final future =
                    monthScope &&
                    date.month == _today.month &&
                    date.isAfter(_today);
                return Padding(
                  padding: const EdgeInsets.only(bottom: gap),
                  child: _tappable(
                    date: date,
                    enabled: inScope,
                    child: SizedBox(
                      width: cell,
                      height: cell,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: future
                              ? context.colors.surfaceContainerHighest
                                    .withValues(alpha: 0.4)
                              : _cell(context, date, inScope: inScope),
                          borderRadius: BorderRadius.circular(radius),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        );
      },
    );
  }

  Widget _monthCalendar(BuildContext context) {
    final weekStart = context.watch<SettingsController>().weekStart;
    final monthStart = DateTime(_today.year, _today.month, 1);
    final first = monthStart.startOfWeek(weekStart);
    final lastDay = DateTime(_today.year, _today.month + 1, 0);
    final weeks =
        (lastDay.startOfWeek(weekStart).difference(first).inDays / 7).round() +
        1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              _monthLabel(monthStart),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.tokens.muted,
              ),
            ),
          ),
        for (var w = 0; w < weeks; w++)
          Padding(
            padding: EdgeInsets.only(bottom: widget.compact ? 2 : 3),
            child: Row(
              children: List.generate(7, (d) {
                final date = first.add(Duration(days: w * 7 + d));
                final inMonth = date.month == _today.month;
                final future = date.isAfter(_today);
                final decoration = BoxDecoration(
                  color: !inMonth
                      ? Colors.transparent
                      : future
                      ? context.colors.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        )
                      : _cell(context, date),
                  borderRadius: BorderRadius.circular(widget.circle ? 999 : 9),
                );
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(widget.compact ? 1 : 1.5),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _tappable(
                        date: date,
                        enabled: inMonth,
                        child: widget.compact
                            ? DecoratedBox(decoration: decoration)
                            : AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: decoration,
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

  String _monthLabel(DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    final text = DateFormat.yMMMM(locale).format(date);
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  Widget _yearCell(BuildContext context, DateTime date, double cell) {
    return _tappable(
      date: date,
      enabled: true,
      child: SizedBox(
        width: cell,
        height: cell,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _cell(context, date),
            borderRadius: BorderRadius.circular(widget.circle ? cell / 2 : 3),
          ),
        ),
      ),
    );
  }

  Widget _yearGrid(BuildContext context) {
    const columns = 53;
    const gap = 3.0;
    const cell = 13.0;
    final start = _mondayOf(_today).subtract(
      const Duration(days: 7 * (columns - 1)),
    );
    final months = DateFormat.MMM(Localizations.localeOf(context).languageCode);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrolled && _scroll.hasClients) {
        _scrolled = true;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });

    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(columns, (col) {
          final colDate = start.add(Duration(days: col * 7));
          final prevDate = start.add(Duration(days: (col - 1) * 7));
          final isNewMonth = col == 0 || colDate.month != prevDate.month;
          return Padding(
            padding: const EdgeInsets.only(right: gap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 14,
                  width: cell,
                  child: isNewMonth
                      ? OverflowBox(
                          maxWidth: 40,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            months.format(colDate),
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
                    padding: const EdgeInsets.only(bottom: gap),
                    child: _yearCell(
                      context,
                      start.add(Duration(days: col * 7 + row)),
                      cell,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
