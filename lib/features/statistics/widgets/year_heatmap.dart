import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';

class YearHeatmap extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final firstOfYear = DateTime(year, 1, 1);
    final start = firstOfYear.subtract(Duration(days: firstOfYear.weekday - 1));
    final lastOfYear = DateTime(year, 12, 31);
    final columns = (lastOfYear.difference(start).inDays / 7).ceil() + 1;
    final empty = context.colors.surfaceContainerHighest;
    final max = maxCount <= 0 ? 1 : maxCount;
    final locale = Localizations.localeOf(context).languageCode;

    const cell = 12.0;
    const gap = 3.0;

    Color cellColor(DateTime date) {
      if (date.year != year) return Colors.transparent;
      if (date.isAfter(today)) return empty.withValues(alpha: 0.4);
      final count = dailyCounts[date.dayKey] ?? 0;
      if (count <= 0) return empty;
      final ratio = (count / max).clamp(0.25, 1.0);
      return Color.lerp(color.withValues(alpha: 0.35), color, ratio)!;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(columns, (col) {
          final colDate = start.add(Duration(days: col * 7));
          final prevDate = start.add(Duration(days: (col - 1) * 7));
          final isNewMonth =
              colDate.year == year && (col == 0 || colDate.month != prevDate.month);
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
                    padding: const EdgeInsets.only(bottom: gap),
                    child: Container(
                      width: cell,
                      height: cell,
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
