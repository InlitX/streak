import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_palette.dart';

Color celebrationColor(math.Random random, Brightness brightness) {
  final base =
      AppPalette.habitColors[random.nextInt(AppPalette.habitColors.length)];
  final hsl = HSLColor.fromColor(base);
  final lightness = brightness == Brightness.dark
      ? hsl.lightness.clamp(0.52, 0.78)
      : hsl.lightness.clamp(0.30, 0.48);
  return hsl
      .withSaturation(math.max(hsl.saturation, 0.62))
      .withLightness(lightness)
      .toColor();
}
