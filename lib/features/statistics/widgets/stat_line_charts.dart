import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';

class _Chrome {
  const _Chrome._();

  static FlGridData grid(BuildContext context, double interval) => FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval > 0 ? interval : 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: context.tokens.muted.withValues(alpha: 0.16),
          strokeWidth: 1,
        ),
      );

  static Color tooltip(BuildContext context) =>
      context.colors.inverseSurface.withValues(alpha: 0.92);

  static TextStyle tooltipText(BuildContext context) => TextStyle(
        color: context.colors.onInverseSurface,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      );
}

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.values,
    required this.color,
    required this.startDate,
    this.suffix = '',
    this.height = 190,
    this.stepped = false,
  });

  final List<double> values;
  final Color color;
  final DateTime startDate;
  final String suffix;
  final double height;

  final bool stepped;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxValue <= 0 ? 1 : maxValue) * 1.25;
    final format = DateFormat.MMMd(Localizations.localeOf(context).toString());
    final average = values.reduce((a, b) => a + b) / values.length;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: DotField(
            child: LineChart(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            LineChartData(
              minX: 0,
              maxX: (values.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              clipData: const FlClipData.all(),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                getTouchedSpotIndicator: (bar, indexes) => [
                  for (final _ in indexes)
                    TouchedSpotIndicatorData(
                      FlLine(color: color.withValues(alpha: 0.5), strokeWidth: 1),
                      FlDotData(
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: context.colors.surface,
                        ),
                      ),
                    ),
                ],
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => _Chrome.tooltip(context),
                  tooltipRoundedRadius: 10,
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        '${spot.y.round()}$suffix\n'
                        '${format.format(startDate.add(Duration(days: spot.x.toInt())))}',
                        _Chrome.tooltipText(context),
                      ),
                  ],
                ),
              ),

              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: average,
                    color: context.tokens.muted.withValues(alpha: 0.55),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(bottom: 2, right: 2),
                      style: statLabel(context),
                      labelResolver: (_) => '⌀ ${average.round()}$suffix',
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i]),
                  ],
                  isCurved: !stepped,
                  curveSmoothness: 0.28,
                  preventCurveOverShooting: true,
                  isStepLineChart: stepped,
                  lineChartStepData: const LineChartStepData(
                    stepDirection: LineChartStepData.stepDirectionForward,
                  ),
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.5), color],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  isStrokeJoinRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.26),
                        color.withValues(alpha: 0.01),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(format.format(startDate), style: statLabel(context)),
            Text(
              format.format(startDate.add(Duration(days: values.length - 1))),
              style: statLabel(context),
            ),
          ],
        ),
      ],
    );
  }
}

class HourArea extends StatelessWidget {
  const HourArea({
    super.key,
    required this.values,
    required this.color,
    this.height = 140,
  });

  final List<int> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxValue <= 0 ? 1 : maxValue) * 1.3;
    var peak = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[peak]) peak = i;
    }

    return SizedBox(
      height: height,
      child: DotField(
        child: LineChart(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        LineChartData(
          minX: 0,
          maxX: 23,
          minY: 0,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => _Chrome.tooltip(context),
              tooltipRoundedRadius: 10,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${spot.y.round()}\n${spot.x.toInt().toString().padLeft(2, '0')}:00',
                    _Chrome.tooltipText(context),
                  ),
              ],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 6,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${value.toInt().toString().padLeft(2, '0')}h',
                    style: statLabel(context),
                  ),
                ),
              ),
            ),
          ),

          extraLinesData: ExtraLinesData(
            verticalLines: [
              if (maxValue > 0)
                VerticalLine(
                  x: peak.toDouble(),
                  color: color.withValues(alpha: 0.55),
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                  label: VerticalLineLabel(
                    show: true,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    style: statNumber(context, 11),
                    labelResolver: (_) =>
                        '${peak.toString().padLeft(2, '0')}h',
                  ),
                ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i].toDouble()),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              isStrokeCapRound: true,
              isStrokeJoinRound: true,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.34),
                    color.withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class MonthlyLine extends StatelessWidget {
  const MonthlyLine({
    super.key,
    required this.values,
    required this.color,
    required this.year,
    this.height = 196,
  });

  final List<int> values;
  final Color color;
  final int year;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 12) return SizedBox(height: height);
    final locale = Localizations.localeOf(context).toString();
    final short = MonthLabels.short(locale);
    final full = MonthLabels.full(locale);
    final now = AppClock.now();
    final last = year >= now.year ? now.month - 1 : 11;
    final shown = values.take(last + 1).toList();
    final maxValue = shown.fold(0, math.max);
    final maxY = (maxValue <= 0 ? 4 : maxValue * 1.32).toDouble();
    final average = shown.isEmpty
        ? 0.0
        : shown.reduce((a, b) => a + b) / shown.length;
    var best = 0;
    for (var i = 1; i < shown.length; i++) {
      if (shown[i] > shown[best]) best = i;
    }

    return SizedBox(
      height: height,
      child: LineChart(
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        LineChartData(
          minX: 0,
          maxX: 11,
          minY: 0,
          maxY: maxY,
          gridData: _Chrome.grid(context, maxY / 4),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 26,
                getTitlesWidget: (value, _) {
                  final index = value.round();
                  if (index < 0 || index > 11) return const SizedBox.shrink();
                  final peak = maxValue > 0 && index == best;
                  return Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Text(
                      short[index],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: peak ? FontWeight.w800 : FontWeight.w600,
                        color: peak
                            ? color
                            : context.tokens.muted
                                .withValues(alpha: index > last ? 0.45 : 1),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            getTouchedSpotIndicator: (bar, indexes) => [
              for (final _ in indexes)
                TouchedSpotIndicatorData(
                  FlLine(
                    color: color.withValues(alpha: 0.45),
                    strokeWidth: 1,
                    dashArray: const [3, 3],
                  ),
                  FlDotData(
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 6,
                      color: color,
                      strokeWidth: 3,
                      strokeColor: context.colors.surface,
                    ),
                  ),
                ),
            ],
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => _Chrome.tooltip(context),
              tooltipRoundedRadius: 10,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${spot.y.round()}\n${full[spot.x.round().clamp(0, 11)]}',
                    _Chrome.tooltipText(context),
                  ),
              ],
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (average > 0)
                HorizontalLine(
                  y: average,
                  color: context.tokens.muted.withValues(alpha: 0.55),
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(bottom: 2, right: 2),
                    style: statLabel(context),
                    labelResolver: (_) => '⌀ ${average.round()}',
                  ),
                ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i <= last; i++)
                  FlSpot(i.toDouble(), values[i].toDouble()),
              ],
              isCurved: true,
              curveSmoothness: 0.28,
              preventCurveOverShooting: true,
              isStrokeCapRound: true,
              isStrokeJoinRound: true,
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.5), color],
              ),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: maxValue > 0 && spot.x.round() == best ? 5 : 3.4,
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
                    color.withValues(alpha: 0.26),
                    color.withValues(alpha: 0.01),
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
