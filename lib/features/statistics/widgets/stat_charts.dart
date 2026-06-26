import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/date_labels.dart';

/// Número que cuenta de 0 al valor real al aparecer.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.suffix = '',
    this.style,
  });

  final int value;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Bar chart de completions por día de la semana (L..D).
class WeekdayBars extends StatelessWidget {
  const WeekdayBars({
    super.key,
    required this.values,
    required this.color,
    this.height = 150,
  });

  final List<int> values; // length 7, Mon..Sun
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final labels = WeekdayLabels.narrowMonFirst(
      Localizations.localeOf(context).languageCode,
    );
    final maxV = (values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b))
        .toDouble();
    final maxY = (maxV <= 0 ? 1.0 : maxV) * 1.2;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => context.colors.surfaceContainerHighest,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.round()}',
                TextStyle(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[value.toInt() % 7],
                    style: TextStyle(
                      color: context.tokens.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < 7; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    color: color,
                    width: 12,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      // Faint track so the proportional bars stay readable.
                      color: context.colors.surfaceContainerHighest
                          .withValues(alpha: 0.22),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Cumulative progress over time: thick gradient line, filled area, last-point
/// dot and month labels on the X axis. [startDate] is the date at x = 0.
class StreakLine extends StatelessWidget {
  const StreakLine({
    super.key,
    required this.values,
    required this.color,
    this.startDate,
    this.height = 210,
  });

  final List<double> values;
  final Color color;
  final DateTime? startDate;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final last = values.length - 1;
    final start = startDate;
    final monthFmt = DateFormat.MMM(
      Localizations.localeOf(context).languageCode,
    );

    return SizedBox(
      height: height,
      child: LineChart(
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        LineChartData(
          minY: 0,
          maxY: (maxV <= 0 ? 1 : maxV) * 1.18,
          // Keep the curved line and filled area from overshooting the card.
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxV <= 0 ? 1 : maxV) / 3).clamp(1, 9999),
            getDrawingHorizontalLine: (_) => FlLine(
              color: context.colors.surfaceContainerHighest,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: start != null,
                interval: 1,
                reservedSize: 24,
                getTitlesWidget: (value, _) {
                  if (start == null) return const SizedBox.shrink();
                  final date = start.add(Duration(days: value.toInt()));
                  // One label per month: only render on the first of the month.
                  if (date.day != 1) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      monthFmt.format(date),
                      style: TextStyle(
                        color: context.tokens.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [color.withValues(alpha: 0.55), color],
              ),
              barWidth: 4.5,
              // Soft glow so the line lifts off the dark card.
              shadow: Shadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => spot.x == last.toDouble(),
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 5,
                  color: color,
                  strokeWidth: 3,
                  strokeColor: context.colors.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.45),
                    color.withValues(alpha: 0.10),
                    color.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Usual completion hour across the day (0-23h).
class HourLine extends StatelessWidget {
  const HourLine({
    super.key,
    required this.values,
    required this.color,
    this.height = 140,
  });

  final List<int> values; // length 24
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    // Highlight the busiest hour with a dot.
    var peakHour = 5;
    var peakVal = -1;
    for (var h = 5; h < 24; h++) {
      if (values[h] > peakVal) {
        peakVal = values[h];
        peakHour = h;
      }
    }
    return SizedBox(
      height: height,
      child: LineChart(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        LineChartData(
          minX: 5,
          maxX: 23,
          minY: 0,
          maxY: (maxV <= 0 ? 1 : maxV) * 1.2,
          clipData: const FlClipData.all(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 6,
                reservedSize: 24,
                getTitlesWidget: (value, _) {
                  final h = value.toInt();
                  if (h % 6 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${h.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        color: context.tokens.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var h = 5; h < 24; h++)
                  FlSpot(h.toDouble(), values[h].toDouble()),
              ],
              isCurved: true,
              curveSmoothness: 0.22,
              // Stop the spline from dipping below zero on the climbs/descents,
              // which the clip would otherwise slice into odd notches.
              preventCurveOverShooting: true,
              color: color,
              barWidth: 3,
              shadow: Shadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
              dotData: FlDotData(
                show: peakVal > 0,
                checkToShowDot: (spot, _) => spot.x == peakHour.toDouble(),
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2.5,
                  strokeColor: context.colors.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
