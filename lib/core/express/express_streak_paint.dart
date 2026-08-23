import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';

enum ExpressDayState { done, covered, neutral, off, empty, future, blank }

class ExpressStreakInk {
  const ExpressStreakInk({
    required this.color,
    required this.track,
    required this.faded,
    required this.neutral,
  });

  final Color color;
  final Color track;
  final Color faded;
  final Color neutral;

  Color fillFor(ExpressDayState state) => switch (state) {
    ExpressDayState.neutral => neutral,
    ExpressDayState.covered => color.withValues(alpha: 0.22),
    ExpressDayState.off || ExpressDayState.future => faded,
    _ => track,
  };
}

ExpressStreakInk expressInk(BuildContext context, Color color) {
  final muted = context.tokens.muted;
  return ExpressStreakInk(
    color: color,
    track: muted.withValues(alpha: 0.3),
    faded: muted.withValues(alpha: 0.14),
    neutral: context.tokens.info.withValues(alpha: 0.4),
  );
}

void paintStreakRow(
  Canvas canvas,
  Rect area,
  List<ExpressDayState> states,
  ExpressStreakInk ink,
  double progress, {
  double thicknessRatio = 1.4,
  double gap = 5,
  double edge = 2,
}) {
  if (states.isEmpty) return;
  final cell = area.width / states.length;
  final centerY = area.center.dy;
  final thickness = math.min(area.height, cell * thicknessRatio);

  for (var i = 0; i < states.length; i++) {
    final state = states[i];
    if (state == ExpressDayState.done || state == ExpressDayState.blank) {
      continue;
    }
    final height = thickness - gap;
    final rect = Rect.fromCenter(
      center: Offset(area.left + cell * (i + 0.5), centerY),
      width: math.min(cell - gap, height * 2.4),
      height: height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      Paint()..color = ink.fillFor(state),
    );
  }

  final grow = 0.94 + 0.06 * progress.clamp(0.0, 1.2);
  var i = 0;
  while (i < states.length) {
    if (states[i] != ExpressDayState.done) {
      i++;
      continue;
    }
    var end = i;
    while (end + 1 < states.length && states[end + 1] == ExpressDayState.done) {
      end++;
    }

    final left = area.left + cell * i + (i == 0 ? edge : 0);
    final right =
        area.left + cell * (end + 1) - (end == states.length - 1 ? edge : 0);
    final height = (thickness - edge * 2) * grow;
    final rect = Rect.fromCenter(
      center: Offset((left + right) / 2, centerY),
      width: right - left,
      height: height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(height / 2)),
      Paint()
        ..shader = LinearGradient(
          colors: [ink.color.withValues(alpha: 0.82), ink.color],
        ).createShader(rect),
    );
    i = end + 1;
  }
}

bool sameStates(List<ExpressDayState> a, List<ExpressDayState> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
