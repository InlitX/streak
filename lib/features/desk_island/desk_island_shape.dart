import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

class IslandShape {
  const IslandShape(this.body, this.radius);

  static const window = Size(680, 460);
  static const shoulder = 12.0;

  final Rect body;
  final double radius;

  static IslandShape centered(Size size, double radius, {double? width}) =>
      IslandShape(
        Rect.fromLTWH(
          ((width ?? window.width) - size.width) / 2,
          0,
          size.width,
          size.height,
        ),
        radius,
      );

  double get _shoulder => math.min(shoulder, body.height / 2);

  double get _corner =>
      math.max(0, math.min(radius, math.min(body.width / 2, body.height - _shoulder)));

  Path path() {
    final s = _shoulder;
    final r = _corner;
    final b = body;
    return Path()
      ..moveTo(b.left - s, 0)
      ..arcToPoint(Offset(b.left, s), radius: Radius.circular(s))
      ..lineTo(b.left, b.bottom - r)
      ..arcToPoint(
        Offset(b.left + r, b.bottom),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(b.right - r, b.bottom)
      ..arcToPoint(
        Offset(b.right, b.bottom - r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(b.right, s)
      ..arcToPoint(Offset(b.right + s, 0), radius: Radius.circular(s))
      ..close();
  }

  Path edge() {
    final r = _corner;
    final b = body;
    return Path()
      ..moveTo(b.left, _shoulder)
      ..lineTo(b.left, b.bottom - r)
      ..arcToPoint(
        Offset(b.left + r, b.bottom),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(b.right - r, b.bottom)
      ..arcToPoint(
        Offset(b.right, b.bottom - r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(b.right, _shoulder);
  }

  Int32List region(double ratio) {
    final s = _shoulder;
    final r = _corner + 1;
    final b = body.inflate(1);
    final points = <double>[];
    void arc(Offset center, double radius, double from, double to) {
      const steps = 10;
      for (var i = 0; i <= steps; i++) {
        final angle = from + (to - from) * i / steps;
        points
          ..add(center.dx + radius * math.cos(angle))
          ..add(center.dy + radius * math.sin(angle));
      }
    }

    arc(Offset(b.left - s, s), s, -math.pi / 2, 0);
    arc(Offset(b.left + r, b.bottom - r), r, math.pi, math.pi / 2);
    arc(Offset(b.right - r, b.bottom - r), r, math.pi / 2, 0);
    arc(Offset(b.right + s, s), s, math.pi, math.pi * 1.5);
    points
      ..add(b.right + s)
      ..add(-2)
      ..add(b.left - s)
      ..add(-2);
    return Int32List.fromList([for (final v in points) (v * ratio).round()]);
  }

  static IslandShape lerp(IslandShape a, IslandShape b, double t) => IslandShape(
        Rect.lerp(a.body, b.body, t)!,
        a.radius + (b.radius - a.radius) * t,
      );
}

class IslandPainter extends CustomPainter {
  const IslandPainter({
    required this.shape,
    required this.progress,
    required this.accent,
    required this.glow,
  });

  final IslandShape shape;
  final double? progress;
  final Color accent;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.path();
    canvas.drawPath(path, Paint()..color = Colors.black);
    canvas.drawPath(
      shape.edge(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.07),
    );
    if (glow > 0) {
      canvas.save();
      canvas.clipPath(path);
      final b = shape.body;
      canvas.drawRect(
        Rect.fromLTRB(b.left, b.bottom - 26, b.right, b.bottom),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              accent.withValues(alpha: 0.28 * glow),
              accent.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTRB(b.left, b.bottom - 26, b.right, b.bottom)),
      );
      canvas.restore();
    }
    final value = progress;
    if (value == null) return;
    final b = shape.body;
    final inner = IslandShape(
      Rect.fromLTRB(b.left + 1.6, 0, b.right - 1.6, b.bottom - 1.6),
      math.max(0, shape.radius - 1.6),
    ).edge();
    final metrics = inner.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    final done = value.clamp(0.0, 1.0);
    if (done <= 0) return;
    final length = metric.length * done;
    final ramp = math.min(length, 64.0);
    canvas.save();
    canvas.clipPath(path);
    if (length > ramp * 0.5) {
      canvas.drawPath(
        metric.extractPath(ramp * 0.5, length),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = accent.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    final left = <Offset>[];
    final right = <Offset>[];
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final at = metric.getTangentForOffset(ramp * t);
      if (at == null) continue;
      final eased = t * t * (3 - 2 * t);
      final half = 1.2 * eased;
      final normal = Offset(-at.vector.dy, at.vector.dx);
      left.add(at.position + normal * half);
      right.add(at.position - normal * half);
    }
    if (left.length > 1) {
      canvas.drawPath(
        Path()..addPolygon([...left, ...right.reversed], true),
        Paint()..color = accent,
      );
    }
    if (length > ramp) {
      canvas.drawPath(
        metric.extractPath(ramp - 0.5, length),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = accent,
      );
    }
    final tip = metric.getTangentForOffset(length)?.position;
    if (tip != null) {
      canvas.drawCircle(
        tip,
        4,
        Paint()
          ..color = accent.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(tip, 1.6, Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(IslandPainter old) =>
      old.shape.body != shape.body ||
      old.shape.radius != shape.radius ||
      old.progress != progress ||
      old.accent != accent ||
      old.glow != glow;
}
