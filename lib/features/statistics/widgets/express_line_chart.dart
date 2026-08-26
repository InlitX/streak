import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/features/statistics/widgets/stat_axis.dart';

class ExpressLineChart extends StatefulWidget {
  const ExpressLineChart({
    super.key,
    required this.values,
    required this.color,
    required this.label,
    this.subLabel,
    this.format,
    this.axisFormat,
    this.window = 12,
    this.height = 208,
    this.goal,
  });

  final List<double> values;
  final Color color;
  final String Function(int index) label;
  final String? Function(int index)? subLabel;
  final String Function(double value)? format;
  final String Function(double value)? axisFormat;
  final int window;
  final double height;
  final double? goal;

  @override
  State<ExpressLineChart> createState() => _ExpressLineChartState();
}

class _ExpressLineChartState extends State<ExpressLineChart>
    with SingleTickerProviderStateMixin {
  late double _start = _maxStart;
  late final AnimationController _glide = AnimationController(vsync: this);
  double _fling = 0;

  int get _span => math.min(widget.window, widget.values.length);

  double get _maxStart => (widget.values.length - _span).toDouble();

  bool get _scrolls => widget.values.length > _span;

  @override
  void initState() {
    super.initState();
    _glide.addListener(() => _pan(_fling * (1 - _glide.value)));
  }

  @override
  void didUpdateWidget(covariant ExpressLineChart old) {
    super.didUpdateWidget(old);
    if (old.values.length != widget.values.length) _start = _maxStart;
  }

  @override
  void dispose() {
    _glide.dispose();
    super.dispose();
  }

  void _pan(double pixels) {
    if (!_scrolls || pixels == 0) return;
    final width = context.size?.width ?? 1;
    final perPoint = width / math.max(_span - 1, 1);
    final next = (_start - pixels / perPoint).clamp(0.0, _maxStart);
    if (next == _start) return;
    setState(() => _start = next);
  }

  void _release(DragEndDetails details) {
    if (!_scrolls) return;
    _fling = details.velocity.pixelsPerSecond.dx / 90;
    if (_fling.abs() < 1) return;
    _glide
      ..duration = const Duration(milliseconds: 420)
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    if (values.isEmpty) return SizedBox(height: widget.height);

    final color = widget.color;
    final format = widget.format ?? (double v) => '${v.round()}';
    final goal = widget.goal;
    final peak = values.reduce(math.max);
    final ceiling = goal == null || goal < peak ? peak : goal;
    final scale = axisScale(ceiling, lines: 3, headroom: 0.35);
    final minX = _start;
    final maxX = _start + _span - 1;
    final onColor = color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        onHorizontalDragStart: (_) => _glide.stop(),
        onHorizontalDragUpdate: (details) => _pan(details.primaryDelta ?? 0),
        onHorizontalDragEnd: _release,
        child: LineChart(
          duration: Express.morph,
          curve: Express.emphasized,
          LineChartData(
            minX: minX - 0.35,
            maxX: maxX + 0.35,
            minY: 0,
            maxY: scale.maxY,
            clipData: const FlClipData.all(),
            gridData: axisGrid(context, scale.step, top: scale.top),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: axisLeftTitles(
                context,
                interval: scale.step,
                top: scale.top,
                format: widget.axisFormat ?? format,
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: widget.subLabel == null ? 28 : 40,
                  getTitlesWidget: (value, _) => _bottom(context, value),
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (goal != null && goal > 0)
                  HorizontalLine(
                    y: goal,
                    color: color.withValues(alpha: 0.5),
                    strokeWidth: 1.5,
                    dashArray: const [6, 5],
                  ),
              ],
            ),
            lineTouchData: LineTouchData(
              getTouchedSpotIndicator: (bar, indexes) => [
                for (final _ in indexes)
                  TouchedSpotIndicatorData(
                    FlLine(
                      color: color.withValues(alpha: 0.45),
                      strokeWidth: 1.5,
                      dashArray: const [4, 4],
                    ),
                    FlDotData(
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 6.5,
                        color: color,
                        strokeWidth: 3,
                        strokeColor: context.colors.surface,
                      ),
                    ),
                  ),
              ],
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => color,
                tooltipRoundedRadius: 14,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                tooltipMargin: 12,
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      format(spot.y),
                      ExpressType.headline.at(
                        14,
                        weight: 800,
                        color: onColor,
                        tabular: true,
                      ),
                      children: [
                        TextSpan(
                          text: '\n${widget.label(spot.x.round())}',
                          style: ExpressType.body.at(
                            11.5,
                            weight: 700,
                            color: onColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < values.length; i++)
                    FlSpot(i.toDouble(), values[i]),
                ],
                isCurved: true,
                curveSmoothness: 0.2,
                preventCurveOverShooting: true,
                isStrokeCapRound: true,
                isStrokeJoinRound: true,
                barWidth: 3.5,
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.65), color],
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: peak > 0 && spot.y >= peak ? 5 : 3.6,
                    color: context.colors.surface,
                    strokeWidth: 2.4,
                    strokeColor: color,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.28),
                      color.withValues(alpha: 0.02),
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

  Widget _bottom(BuildContext context, double value) {
    final index = value.round();
    if (index < 0 || index >= widget.values.length) {
      return const SizedBox.shrink();
    }
    if ((value - index).abs() > 0.01) return const SizedBox.shrink();
    final sub = widget.subLabel?.call(index);
    final muted = context.tokens.muted;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label(index),
              maxLines: 1,
              style: ExpressType.body.at(
                11,
                weight: 700,
                color: muted,
                tabular: true,
              ),
            ),
            if (sub != null && sub.isNotEmpty)
              Text(
                sub,
                maxLines: 1,
                style: ExpressType.body.at(
                  9.5,
                  weight: 700,
                  color: muted.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
