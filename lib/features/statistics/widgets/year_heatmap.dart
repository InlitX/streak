import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';

const _cell = 12.0;
const _gap = 3.0;
const _step = _cell + _gap;

class YearHeatmap extends StatefulWidget {
  const YearHeatmap({
    super.key,
    required this.year,
    required this.dailyCounts,
    required this.maxCount,
    required this.color,
  });

  final int year;
  final Map<String, int> dailyCounts;
  final int maxCount;
  final Color color;

  @override
  State<YearHeatmap> createState() => _YearHeatmapState();
}

class _YearHeatmapState extends State<YearHeatmap> {
  final _scroll = ScrollController();

  DateTime get _start {
    final firstOfYear = DateTime(widget.year, 1, 1);
    return firstOfYear.subtract(Duration(days: firstOfYear.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _focusCurrentMonth();
  }

  @override
  void didUpdateWidget(YearHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.year != oldWidget.year) _focusCurrentMonth();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _focusCurrentMonth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      final today = AppClock.now().atMidnight;
      final target = today.year != widget.year
          ? 0.0
          : (today.difference(_start).inDays ~/ 7) * _step +
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
    final start = _start;
    final lastOfYear = DateTime(widget.year, 12, 31);
    final columns = (lastOfYear.difference(start).inDays / 7).ceil() + 1;
    final empty = context.colors.surfaceContainerHighest;
    final max = widget.maxCount <= 0 ? 1 : widget.maxCount;
    final locale = Localizations.localeOf(context).languageCode;

    Color cellColor(DateTime date) {
      if (date.year != widget.year) return Colors.transparent;
      if (date.isAfter(today)) return empty.withValues(alpha: 0.4);
      final count = widget.dailyCounts[date.dayKey] ?? 0;
      if (count <= 0) return empty;
      final ratio = (count / max).clamp(0.25, 1.0);
      return Color.lerp(widget.color.withValues(alpha: 0.35), widget.color, ratio)!;
    }

    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(columns, (col) {
          final colDate = start.add(Duration(days: col * 7));
          final prevDate = start.add(Duration(days: (col - 1) * 7));
          final isNewMonth = colDate.year == widget.year &&
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
                        color: cellColor(start.add(Duration(days: col * 7 + row))),
                        borderRadius: BorderRadius.circular(3),
                      ),
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
