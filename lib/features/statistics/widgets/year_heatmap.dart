import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:provider/provider.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

const _gap = 3.0;

class YearHeatmap extends StatefulWidget {
  const YearHeatmap({
    super.key,
    required this.year,
    required this.color,
    this.dailyCounts = const {},
    this.maxCount = 1,
    this.habit,
    this.express = false,
  });

  final int year;
  final Map<String, int> dailyCounts;
  final int maxCount;
  final Color color;
  final Habit? habit;
  final bool express;

  @override
  State<YearHeatmap> createState() => _YearHeatmapState();
}

class _YearHeatmapState extends State<YearHeatmap> {
  final _scroll = ScrollController();

  double get _cell => widget.express ? 15 : 12;

  double get _step => _cell + _gap;

  bool _rollingFor(bool on) => on && widget.year == AppClock.now().year;

  DateTime _startFrom(bool rolling) {
    if (rolling) {
      final today = AppClock.now().atMidnight;
      return today
          .subtract(Duration(days: today.weekday - 1))
          .subtract(const Duration(days: 7 * 52));
    }
    final firstOfYear = DateTime(widget.year, 1, 1);
    return firstOfYear.subtract(Duration(days: firstOfYear.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _focusToday();
  }

  @override
  void didUpdateWidget(YearHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.year != oldWidget.year) _focusToday();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _focusToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      final today = AppClock.now().atMidnight;
      final rolling = _rollingFor(
        context.read<SettingsController>().heatmapRolling,
      );
      final target = today.year != widget.year && !rolling
          ? 0.0
          : (today.difference(_startFrom(rolling)).inDays ~/ 7) * _step +
                _cell / 2 -
                position.viewportDimension / 2;
      position.jumpTo(
        target.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final rolling =
        _rollingFor(context.watch<SettingsController>().heatmapRolling);
    final start = _startFrom(rolling);
    final lastOfYear = DateTime(widget.year, 12, 31);
    final columns =
        rolling ? 53 : lastOfYear.difference(start).inDays ~/ 7 + 1;
    final empty = context.colors.surfaceContainerHighest;
    final max = widget.maxCount <= 0 ? 1 : widget.maxCount;
    final locale = Localizations.localeOf(context).languageCode;

    Color cellColor(DateTime date) {
      if (!rolling && date.year != widget.year) return Colors.transparent;
      final habit = widget.habit;
      if (habit != null) return heatmapCellColor(context, habit, date);
      if (date.isAfter(today)) return empty.withValues(alpha: 0.4);
      final count = widget.dailyCounts[date.dayKey] ?? 0;
      if (count <= 0) return empty;
      final ratio = (count / max).clamp(0.25, 1.0);
      return Color.lerp(widget.color.withValues(alpha: 0.35), widget.color, ratio)!;
    }

    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: box.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(columns, (col) {
              final colDate = start.add(Duration(days: col * 7));
              final prevDate = start.add(Duration(days: (col - 1) * 7));
                      final isNewMonth = (rolling || colDate.year == widget.year) &&
                  (col == 0 || colDate.month != prevDate.month);
              return Padding(
                padding: const EdgeInsets.only(right: _gap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 14,
                      width: _cell,
                      child: isNewMonth
                          ? OverflowBox(
                              maxWidth: 40,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                DateFormat.MMM(locale).format(colDate),
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
                        padding: const EdgeInsets.only(bottom: _gap),
                        child: Container(
                          width: _cell,
                          height: _cell,
                          decoration: BoxDecoration(
                            color: cellColor(
                              start.add(Duration(days: col * 7 + row)),
                            ),
                            borderRadius: BorderRadius.circular(
                              widget.express ? 4 : 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
