import 'dart:math' as math;

import 'package:flutter/material.dart';

class QuantProgress {
  const QuantProgress({required this.laps, required this.fraction});

  factory QuantProgress.of({required double count, required double target}) {
    if (target <= 0 || count <= 0) {
      return const QuantProgress(laps: 0, fraction: 0);
    }
    final laps = (count / target).floor();
    return QuantProgress(
      laps: laps,
      fraction: laps == 0 ? count / target : (count % target) / target,
    );
  }

  final int laps;
  final double fraction;

  bool get reachedGoal => laps > 0;

  Color reachedColor(Color base) => shade(base, laps - 1);

  Color activeColor(Color base) => shade(base, laps);

  static Color shade(Color base, int level) {
    if (level <= 0) return base;
    final steps = math.min(level, 4);
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withSaturation((hsl.saturation + 0.05 * steps).clamp(0.0, 1.0))
        .withLightness((hsl.lightness - 0.09 * steps).clamp(0.24, 1.0))
        .toColor();
  }
}
