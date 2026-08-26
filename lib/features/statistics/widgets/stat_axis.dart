import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

const _maxAxisScale = 1.15;

TextStyle axisLabelStyle(BuildContext context) {
  final settings = context.read<SettingsController>();
  final muted = context.tokens.muted;
  if (settings.isExpressStyle) {
    return ExpressType.body.at(10.5, weight: 700, color: muted, tabular: true);
  }
  if (settings.isMinimalStyle) return MinimalType.figure(10.5, color: muted);
  return TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: muted,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

double axisStep(double maxValue, int lines) {
  if (maxValue <= 0) return 1;
  final raw = maxValue / lines;
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final normalised = raw / magnitude;
  final rounded = normalised <= 1
      ? 1.0
      : normalised <= 2
      ? 2.0
      : normalised <= 2.5
      ? 2.5
      : normalised <= 3
      ? 3.0
      : normalised <= 5
      ? 5.0
      : 10.0;
  return math.max(magnitude >= 1 ? 1 : magnitude, rounded * magnitude);
}

({double step, double top, double maxY}) axisScale(
  double maxValue, {
  int lines = 3,
  double headroom = 0.3,
}) {
  final step = axisStep(maxValue, lines);
  final top = maxValue <= 0 ? step : (maxValue / step).ceil() * step;
  return (step: step, top: top, maxY: top + step * headroom);
}

FlGridData axisGrid(BuildContext context, double interval, {double top = 0}) =>
    FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval > 0 ? interval : 1,
      checkToShowHorizontalLine: (value) => top <= 0 || value <= top + 0.001,
      getDrawingHorizontalLine: (value) => FlLine(
        color: context.tokens.muted.withValues(alpha: value == 0 ? 0.3 : 0.14),
        strokeWidth: 1,
        dashArray: value == 0 ? null : const [5, 5],
      ),
    );

double axisWidth(
  BuildContext context,
  TextStyle style,
  Iterable<String> samples,
) {
  final scaler = MediaQuery.textScalerOf(
    context,
  ).clamp(maxScaleFactor: _maxAxisScale);
  var width = 0.0;
  for (final sample in samples) {
    final painter = TextPainter(
      text: TextSpan(text: sample, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    width = math.max(width, painter.width);
  }
  return width + 8;
}

AxisTitles axisLeftTitles(
  BuildContext context, {
  required double interval,
  required double top,
  required String Function(double value) format,
}) {
  final style = axisLabelStyle(context);
  final samples = [
    for (var value = 0.0; value <= top + 0.001; value += interval)
      format(value),
  ];

  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      interval: interval,
      reservedSize: axisWidth(context, style, samples),
      getTitlesWidget: (value, meta) {
        if (value < -0.001 || value > top + 0.001) {
          return const SizedBox.shrink();
        }
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: _maxAxisScale,
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              format(value),
              maxLines: 1,
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
        );
      },
    ),
  );
}
