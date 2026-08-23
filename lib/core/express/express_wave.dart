import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:streak/core/express/express_motion.dart';

class ExpressWaveBar extends StatefulWidget {
  const ExpressWaveBar({
    super.key,
    required this.value,
    required this.color,
    required this.track,
    this.stroke = 8,
    this.wavelength = 26,
    this.amplitude = 3.6,
    this.showStop = true,
    this.animate = true,
  });

  final double value;
  final Color color;
  final Color track;
  final double stroke;
  final double wavelength;
  final double amplitude;
  final bool showStop;
  final bool animate;

  @override
  State<ExpressWaveBar> createState() => _ExpressWaveBarState();
}

class _ExpressWaveBarState extends State<ExpressWaveBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _phase.repeat();
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.stroke + widget.amplitude * 2 + 4,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.value.clamp(0.0, 1.0)),
          duration: Express.slow,
          curve: Express.emphasized,
          builder: (context, value, _) => AnimatedBuilder(
            animation: _phase,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _WaveBarPainter(
                value: value,
                phase: _phase.value * 2 * math.pi,
                color: widget.color,
                track: widget.track,
                stroke: widget.stroke,
                wavelength: widget.wavelength,
                amplitude: widget.amplitude,
                showStop: widget.showStop,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveBarPainter extends CustomPainter {
  const _WaveBarPainter({
    required this.value,
    required this.phase,
    required this.color,
    required this.track,
    required this.stroke,
    required this.wavelength,
    required this.amplitude,
    required this.showStop,
  });

  final double value;
  final double phase;
  final Color color;
  final Color track;
  final double stroke;
  final double wavelength;
  final double amplitude;
  final bool showStop;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final stopRoom = showStop ? stroke + 6 : 0.0;
    final span = size.width - stopRoom;
    final active = span * value;
    final gap = value > 0 && value < 1 ? stroke * 0.9 : 0.0;

    final line = Paint()
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (active + gap < span) {
      canvas.drawLine(
        Offset(math.max(active + gap, stroke / 2), mid),
        Offset(span - stroke / 2, mid),
        line..color = track,
      );
    }

    if (showStop) {
      canvas.drawCircle(
        Offset(size.width - stroke / 2, mid),
        stroke / 2,
        Paint()..color = value >= 1 ? color : track,
      );
    }

    if (active <= 0) return;

    final swell = Curves.easeOutCubic.transform(math.min(value * 6, 1));
    final path = Path()..moveTo(stroke / 2, mid);
    for (var x = stroke / 2; x <= active; x += 1.5) {
      final edge = math.min((active - x) / (wavelength / 2), 1).clamp(0.0, 1.0);
      final lift = amplitude * swell * edge;
      path.lineTo(
        x,
        mid + lift * math.sin(2 * math.pi * x / wavelength + phase),
      );
    }
    canvas.drawPath(path, line..color = color);
  }

  @override
  bool shouldRepaint(_WaveBarPainter old) =>
      old.value != value ||
      old.phase != phase ||
      old.color != color ||
      old.track != track;
}

class ExpressWaveRing extends StatefulWidget {
  const ExpressWaveRing({
    super.key,
    required this.value,
    required this.color,
    required this.track,
    this.size = 168,
    this.stroke = 12,
    this.waves = 22,
    this.amplitude = 2.6,
    this.child,
  });

  final double value;
  final Color color;
  final Color track;
  final double size;
  final double stroke;
  final int waves;
  final double amplitude;
  final Widget? child;

  @override
  State<ExpressWaveRing> createState() => _ExpressWaveRingState();
}

class _ExpressWaveRingState extends State<ExpressWaveRing>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.86, end: 1),
        duration: Express.slow,
        curve: Express.bouncy,
        builder: (context, pop, child) =>
            Transform.scale(scale: pop, child: child),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: widget.value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1250),
            curve: Express.springy,
            builder: (context, value, child) => CustomPaint(
              painter: _WaveRingPainter(
                value: value,
                color: widget.color,
                track: widget.track,
                stroke: widget.stroke,
                waves: widget.waves,
                amplitude: widget.amplitude,
              ),
              child: child,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _WaveRingPainter extends CustomPainter {
  const _WaveRingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.stroke,
    required this.waves,
    required this.amplitude,
  });

  final double value;
  final Color color;
  final Color track;
  final double stroke;
  final int waves;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2 - amplitude;
    final line = Paint()
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, line..color = track);

    if (value <= 0) return;

    final sweep = 2 * math.pi * value.clamp(0.0, 1.0);
    final swell = Curves.easeOutCubic.transform(math.min(value * 5, 1));
    final path = Path();
    final steps = math.max((sweep * radius / 2).round(), 8);
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = -math.pi / 2 + sweep * t;
      final edge =
          math.min((1 - t) * 12, 1).clamp(0.0, 1.0) *
          math.min(t * 12, 1).clamp(0.0, 1.0);
      final lift = amplitude * swell * edge * math.sin(waves * angle);
      final r = radius + lift;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, line..color = color);
  }

  @override
  bool shouldRepaint(_WaveRingPainter old) =>
      old.value != value || old.color != color;
}
