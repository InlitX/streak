import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flip_board/flip_widget.dart';
import 'package:flutter/material.dart';
import 'package:streak/features/focus/data/focus_session.dart';

enum ClockStyle { ring, flip, dots }

const _flipDepth = 0.22;

class FocusClock extends StatelessWidget {
  const FocusClock({
    super.key,
    required this.style,
    required this.seconds,
    required this.progress,
    required this.color,
    required this.label,
    required this.size,
  });

  final ClockStyle style;
  final int seconds;
  final double progress;
  final Color color;
  final String label;
  final double size;

  static String clockText(int seconds) => formatDuration(seconds);

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      ClockStyle.ring => _RingClock(
          seconds: seconds,
          progress: progress,
          color: color,
          label: label,
          size: size,
        ),
      ClockStyle.flip => _FlipClock(seconds: seconds, size: size),
      ClockStyle.dots => _DotsClock(seconds: seconds, size: size),
    };
  }
}

class _RingClock extends StatelessWidget {
  const _RingClock({
    required this.seconds,
    required this.progress,
    required this.color,
    required this.label,
    required this.size,
  });

  final int seconds;
  final double progress;
  final Color color;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = FocusClock.clockText(seconds);
    final stroke = size * 0.052;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              progress: progress,
              color: color,
              stroke: stroke,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size * 0.18),
                  child: Text(
                    text,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: size * 0.235,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              SizedBox(height: size * 0.045),
              SizedBox(
                width: size * 0.6,
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: size * 0.048,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.75),
          Colors.white,
        ],
        stops: const [0, 0.6, 1],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, paint);

    final angle = -math.pi / 2 + sweep;
    final head = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(head, stroke * 0.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      head,
      stroke * 1.4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _DotsClock extends StatelessWidget {
  const _DotsClock({required this.seconds, required this.size});

  final int seconds;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = FocusClock.clockText(seconds);
    final width = _DotTextPainter.widthFor(text, 1, 0.62);

    return SizedBox(
      width: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: CustomPaint(
          size: Size(width, 7 + 6 * 0.62),
          painter: _DotTextPainter(
            text: text,
            color: Colors.white,
            dot: 1,
            gap: 0.62,
          ),
        ),
      ),
    );
  }
}

const _glyphs = <String, List<String>>{
  '0': ['01110', '10001', '10001', '10001', '10001', '10001', '01110'],
  '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
  '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
  '3': ['11111', '00010', '00100', '00010', '00001', '10001', '01110'],
  '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
  '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
  '6': ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
  '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
  '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
  '9': ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
  ':': ['0', '0', '1', '0', '1', '0', '0'],
};

class _DotTextPainter extends CustomPainter {
  const _DotTextPainter({
    required this.text,
    required this.color,
    required this.dot,
    required this.gap,
  });

  final String text;
  final Color color;
  final double dot;
  final double gap;

  static double widthFor(String text, double dot, double gap) {
    var width = 0.0;
    for (final char in text.split('')) {
      final rows = _glyphs[char];
      if (rows == null) continue;
      final columns = rows.first.length;
      width += columns * dot + (columns - 1) * gap + dot * 1.6;
    }
    return width - dot * 1.6;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = dot / 2;
    var x = 0.0;

    for (final char in text.split('')) {
      final rows = _glyphs[char];
      if (rows == null) continue;
      final columns = rows.first.length;
      for (var r = 0; r < rows.length; r++) {
        for (var c = 0; c < columns; c++) {
          if (rows[r][c] != '1') continue;
          canvas.drawCircle(
            Offset(x + c * (dot + gap) + radius, r * (dot + gap) + radius),
            radius,
            paint,
          );
        }
      }
      x += columns * dot + (columns - 1) * gap + dot * 1.6;
    }
  }

  @override
  bool shouldRepaint(_DotTextPainter old) =>
      old.text != text || old.color != color;
}

class _FlipClock extends StatelessWidget {
  const _FlipClock({required this.seconds, required this.size});

  final int seconds;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hours = seconds ~/ 3600;
    final groups = <({String unit, String value})>[
      if (hours > 0) (unit: 'h', value: hours.toString().padLeft(2, '0')),
      (
        unit: 'm',
        value: ((seconds % 3600) ~/ 60).toString().padLeft(2, '0'),
      ),
      (unit: 's', value: (seconds % 60).toString().padLeft(2, '0')),
    ];

    final width = groups.length > 2 ? size * 0.42 : size * 0.64;
    final height = width * 1.3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0) SizedBox(height: height * 0.13),
          _FlipGroup(
            key: ValueKey('${groups[i].unit}:$width'),
            value: groups[i].value,
            width: width,
            height: height,
          ),
        ],
      ],
    );
  }
}

class _FlipGroup extends StatefulWidget {
  const _FlipGroup({
    super.key,
    required this.value,
    required this.width,
    required this.height,
  });

  final String value;
  final double width;
  final double height;

  @override
  State<_FlipGroup> createState() => _FlipGroupState();
}

class _FlipGroupState extends State<_FlipGroup> {
  final _controller = StreamController<String>.broadcast();

  @override
  void didUpdateWidget(_FlipGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _controller.add(widget.value);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlipWidget<String>(
          flipType: FlipType.middleFlip,
          itemStream: _controller.stream,
          initialValue: widget.value,
          flipDirection: AxisDirection.down,
          flipDuration: const Duration(milliseconds: 450),
          flipCurve: Curves.easeInOut,
          perspectiveEffect: _flipDepth / widget.height,
          itemBuilder: (_, value) => _FlipFace(
            value: value ?? widget.value,
            width: widget.width,
            height: widget.height,
          ),
        ),
      ],
    );
  }
}

class _FlipFace extends StatelessWidget {
  const _FlipFace({
    required this.value,
    required this.width,
    required this.height,
  });

  final String value;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.13),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF232326),
            Color(0xFF1C1C1F),
            Color(0xFF1F1F22),
            Color(0xFF141416),
          ],
          stops: [0, 0.499, 0.501, 1],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: height * 0.56,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
              color: const Color(0xFFE6E6E6),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Container(
            width: double.infinity,
            height: (height * 0.016).clamp(1.4, 3.0),
            color: Colors.black.withValues(alpha: 0.62),
          ),
        ],
      ),
    );
  }
}
