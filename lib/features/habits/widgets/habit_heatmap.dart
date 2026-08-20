import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/quant_progress.dart';
import 'package:streak/features/habits/widgets/day_stamp.dart';
import 'package:streak/features/habits/widgets/heatmap_path.dart';
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

  if (!beforeCreation && habit.isCoveredOn(date)) {
    return habit.color.withValues(alpha: 0.22);
  }

  final count = habit.completions[date.dayKey]?.count ?? 0;
  if (count <= 0) {
    final base = scheme.surfaceContainerHighest;
    final untouched = date.isAfter(today) || habit.isOffDay(date);
    return untouched ? base.withValues(alpha: 0.4) : base;
  }
  final target = habit.effectiveTarget <= 0 ? 1.0 : habit.effectiveTarget;
  final ratio = (count / target).clamp(0.25, 1.0);
  final full = QuantProgress.of(count: count, target: target)
      .solidColor(habit.color);
  return Color.lerp(habit.color.withValues(alpha: 0.4), full, ratio)!;
}

String heatmapDayLabel(BuildContext context, Habit habit, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  final state = habit.isCompletedOn(date)
      ? context.l10n.done
      : context.l10n.a11y_not_done;
  return '${DateFormat.yMMMMd(locale).format(date)}, $state';
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
  static const _monthCellMax = 40.0;

  final _scroll = ScrollController();
  bool _scrolled = false;

  DateTime get _today => AppClock.now().atMidnight;

  DateTime _mondayOf(DateTime d) =>
      d.atMidnight.subtract(Duration(days: d.weekday - 1));

  Color _cell(BuildContext context, DateTime date, {bool inScope = true}) =>
      heatmapCellColor(context, widget.habit, date, inScope: inScope);

  bool _isToday(DateTime date) => date.atMidnight == _today;

  Border _todayRing(BuildContext context, Color fill, double width) {
    final plain =
        fill.a < 0.55 || fill == context.colors.surfaceContainerHighest;
    final color = plain
        ? widget.habit.color
        : (fill.computeLuminance() > 0.55 ? Colors.black : Colors.white);
    return Border.all(
      color: color.withValues(alpha: plain ? 1 : 0.6),
      width: width,
    );
  }

  Color? _pathInk(BuildContext context, DateTime date, {bool inMonth = false}) {
    if (inMonth && date.month != _today.month) return null;
    return widget.habit.isCompletedOn(date)
        ? heatmapPathColor(context, widget.habit.color)
        : context.colors.surfaceContainerHighest;
  }

  bool get _dense =>
      widget.mode == HeatmapMode.mini || widget.mode == HeatmapMode.year;

  String _dayLabel(DateTime date) =>
      heatmapDayLabel(context, widget.habit, date);

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
    final labels = WeekdayLabels.shortFrom(
      Localizations.localeOf(context).languageCode,
      weekStart,
    );
    final height = compact ? 40.0 : 46.0;
    return Row(
      children: List.generate(7, (i) {
        final date = start.add(Duration(days: i));
        final future = date.isAfter(_today);
        final fill = _cell(context, date);
        final ink = fill.a < 0.55
            ? context.tokens.muted
            : (fill.computeLuminance() > 0.55 ? Colors.black : Colors.white);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Semantics(
                  button: !future,
                  label: _dayLabel(date),
                  child: GestureDetector(
                    onTap: future || widget.onToggle == null
                        ? null
                        : () => widget.onToggle!(date),
                    onLongPress: widget.onLongPress == null
                        ? null
                        : () => widget.onLongPress!(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      width: double.infinity,
                      height: height,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(
                          widget.circle ? 16 : 11,
                        ),
                        border: _isToday(date)
                            ? _todayRing(context, fill, 2)
                            : null,
                      ),
                      child: ExcludeSemantics(
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.15,
                          child: DayStamp(
                            date: date,
                            label: labels[i].replaceAll('.', '').toUpperCase(),
                            compact: compact,
                            color: future ? ink.withValues(alpha: 0.45) : ink,
                          ),
                        ),
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
    final gesture = GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
    if (_dense) return ExcludeSemantics(child: gesture);
    return Semantics(
      button: true,
      label: _dayLabel(date),
      child: gesture,
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

    final path = heatmapPathOn(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = path ? heatmapPathGap : 3.0;
        var cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        cell = cell.clamp(6.0, big ? 34.0 : 18.0);
        final radius = widget.circle ? cell / 2 : (big ? 8.0 : 4.0);

        final grid = Wrap(
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
                final fill = future
                    ? context.colors.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      )
                    : _cell(context, date, inScope: inScope);
                return Padding(
                  padding: EdgeInsets.only(bottom: gap),
                  child: _tappable(
                    date: date,
                    enabled: inScope,
                    child: SizedBox(
                      width: cell,
                      height: cell,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius: BorderRadius.circular(radius),
                          border: big && _isToday(date)
                              ? _todayRing(context, fill, 1.5)
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        );

        return withHeatmapPath(
          on: path,
          columns: columns,
          rows: 7,
          cell: cell,
          gap: gap,
          inkFor: (col, row) => _pathInk(
            context,
            start.add(Duration(days: col * 7 + row)),
            inMonth: monthScope,
          ),
          child: grid,
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
    final path = heatmapPathOn(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (constraints.maxWidth / 7 - (widget.compact ? 2 : 3))
            .clamp(0.0, _monthCellMax);
        final gap = (constraints.maxWidth - side * 7) / 6;

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
        withHeatmapPath(
          on: path,
          columns: 7,
          rows: weeks,
          cell: side,
          gap: gap,
          byRows: true,
          inkFor: (column, row) => _pathInk(
            context,
            first.add(Duration(days: row * 7 + column)),
            inMonth: true,
          ),
          child: Column(
            children: [
        for (var w = 0; w < weeks; w++)
          Padding(
            padding: EdgeInsets.only(bottom: w == weeks - 1 ? 0 : gap),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (d) {
                final date = first.add(Duration(days: w * 7 + d));
                final inMonth = date.month == _today.month;
                final future = date.isAfter(_today);
                final fill = !inMonth
                    ? Colors.transparent
                    : future
                    ? context.colors.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      )
                    : _cell(context, date);
                final decoration = BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(widget.circle ? 999 : 9),
                  border: _isToday(date)
                      ? _todayRing(context, fill, widget.compact ? 1.2 : 1.5)
                      : null,
                );
                return SizedBox(
                  width: side,
                  height: side,
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
                );
              }),
            ),
          ),
            ],
          ),
        ),
      ],
        );
      },
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
    final path = heatmapPathOn(context);
    final gap = path ? heatmapPathGap : 3.0;
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
      child: withHeatmapPath(
        on: path,
        columns: columns,
        rows: 7,
        cell: cell,
        gap: gap,
        top: 14,
        inkFor: (col, row) =>
            _pathInk(context, start.add(Duration(days: col * 7 + row))),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(columns, (col) {
          final colDate = start.add(Duration(days: col * 7));
          final prevDate = start.add(Duration(days: (col - 1) * 7));
          final isNewMonth = col == 0 || colDate.month != prevDate.month;
          return Padding(
            padding: EdgeInsets.only(right: gap),
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
                    padding: EdgeInsets.only(bottom: gap),
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
      ),
    );
  }
}
