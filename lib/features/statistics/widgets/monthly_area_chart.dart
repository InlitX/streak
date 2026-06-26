import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/app/theme/app_tokens.dart';

/// Area chart of completions per month across a year (12 values, Jan–Dec).
/// Built on fl_chart for a smooth spline, filled area and entry animation,
/// matching the rest of the statistics charts.
class MonthlyAreaChart extends StatelessWidget {
  const MonthlyAreaChart({super.key, required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final color = scheme.primary;
    final maxValue = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxValue <= 0 ? 1 : maxValue) * 1.18;

    return Column(
      children: [
        SizedBox(
          height: 130,
          child: LineChart(
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
            LineChartData(
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: maxY,
              // Keep the spline and area strictly inside the card.
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY / 3).clamp(1, 9999),
                getDrawingHorizontalLine: (_) => FlLine(
                  color: scheme.surfaceContainerHighest,
                  strokeWidth: 1,
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i].toDouble()),
                  ],
                  isCurved: true,
                  curveSmoothness: 0.35,
                  preventCurveOverShooting: true,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.4),
                        color.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var m = 0; m < 12; m++)
              Expanded(
                child: Text(
                  // First letter of each month, spaced to avoid clutter.
                  m % 2 == 0
                      ? DateFormat.MMM().format(DateTime(2020, m + 1))
                      : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.muted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
