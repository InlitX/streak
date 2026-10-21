import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaterCupPainter extends CustomPainter {
  WaterCupPainter({required this.fill});

  final double fill;

  static const glassColor = Color(0xFFE3EAF8);
  static const _glassHi = Color(0xFFF4F7FD);
  static const waterColor = Color(0xFF2E7BF6);
  static const _waterHi = Color(0xFF63A0FA);

  static Path _cup(Size size, double inset) {
    final w = size.width;
    final h = size.height;
    final taper = w * 0.10;
    final pts = <Offset>[
      Offset(inset, inset),
      Offset(w - inset, inset),
      Offset(w - taper - inset, h - inset),
      Offset(taper + inset, h - inset),
    ];
    return _roundedPoly(pts, w * 0.16);
  }

  static Path _roundedPoly(List<Offset> pts, double r) {
    final path = Path();
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final curr = pts[i];
      final prev = pts[(i - 1 + n) % n];
      final next = pts[(i + 1) % n];
      final toPrev = prev - curr;
      final toNext = next - curr;
      final rr = math.min(r, math.min(toPrev.distance, toNext.distance) / 2);
      final p1 = curr + toPrev / toPrev.distance * rr;
      final p2 = curr + toNext / toNext.distance * rr;
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glass = _cup(size, 0);
    canvas.drawPath(glass, Paint()..color = glassColor);

    canvas.save();
    canvas.clipPath(glass);
    final streak = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.15, w * 0.10, h * 0.52),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(streak, Paint()..color = _glassHi);
    canvas.restore();

    if (fill > 0) {
      final interior = _cup(size, w * 0.16);
      final ib = interior.getBounds();
      final waterTopY = ib.bottom - fill * ib.height;

      canvas.save();
      canvas.clipPath(interior);
      canvas.drawRect(
        Rect.fromLTWH(0, waterTopY, w, h - waterTopY),
        Paint()..color = waterColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            ib.left + ib.width * 0.14,
            waterTopY + 3,
            ib.width * 0.12,
            (ib.bottom - waterTopY - 6).clamp(0, ib.height),
          ),
          Radius.circular(w * 0.06),
        ),
        Paint()..color = _waterHi.withValues(alpha: 0.7),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant WaterCupPainter old) => old.fill != fill;
}

class BookPainter extends CustomPainter {
  BookPainter({required this.fill, required this.color, this.ribbon = false});

  final double fill;
  final Color color;
  final bool ribbon;

  void _paintRibbon(Canvas canvas, double w, double h) {
    final band = Color.lerp(color, Colors.black, 0.28)!;
    final left = w * 0.56;
    final width = w * 0.24;
    final drop = h * 0.2;
    final path = Path()
      ..moveTo(left, h - 4)
      ..lineTo(left + width, h - 4)
      ..lineTo(left + width, h + drop)
      ..lineTo(left + width / 2, h + drop - width * 0.55)
      ..lineTo(left, h + drop)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(band, Colors.black, 0.30)!,
            band,
            Color.lerp(band, Colors.white, 0.30)!,
            band,
            Color.lerp(band, Colors.black, 0.30)!,
          ],
          stops: const [0.0, 0.28, 0.45, 0.7, 1.0],
        ).createShader(Rect.fromLTWH(left, 0, width, h)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pale = Color.lerp(color, Colors.white, 0.82)!;
    final hi = Color.lerp(color, Colors.white, 0.42)!;

    if (ribbon) _paintRibbon(canvas, w, h);

    final cover = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, w, h),
      topLeft: const Radius.circular(2.5),
      bottomLeft: const Radius.circular(2.5),
      topRight: const Radius.circular(5),
      bottomRight: const Radius.circular(5),
    );

    canvas.save();
    canvas.clipRRect(cover);

    canvas.drawRect(Offset.zero & size, Paint()..color = pale);

    if (fill > 0) {
      final topY = h - fill * h;
      canvas.drawRect(
        Rect.fromLTWH(0, topY, w, h - topY),
        Paint()..color = color,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, topY, w, 2),
        Paint()..color = hi.withValues(alpha: 0.6),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.24, topY + 3, w * 0.12, (h - topY - 6).clamp(0, h)),
          const Radius.circular(2),
        ),
        Paint()..color = hi.withValues(alpha: 0.65),
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(w - 2.5, 2, 2.5, h - 4),
      Paint()..color = const Color(0xFFF2ECDD),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 3, h),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BookPainter old) =>
      old.fill != fill || old.color != color || old.ribbon != ribbon;
}

class FootPainter extends CustomPainter {
  FootPainter({required this.fill, required this.color, this.mirror = false});

  final double fill;
  final Color color;
  final bool mirror;

  static Path _sole(double w, double h) => Path()
    ..moveTo(0.50 * w, 0.99 * h)
    ..cubicTo(0.26 * w, 0.99 * h, 0.20 * w, 0.82 * h, 0.26 * w, 0.67 * h)
    ..cubicTo(0.31 * w, 0.55 * h, 0.13 * w, 0.48 * h, 0.15 * w, 0.36 * h)
    ..cubicTo(0.17 * w, 0.25 * h, 0.40 * w, 0.23 * h, 0.58 * w, 0.26 * h)
    ..cubicTo(0.80 * w, 0.29 * h, 0.89 * w, 0.39 * h, 0.85 * w, 0.53 * h)
    ..cubicTo(0.81 * w, 0.66 * h, 0.79 * w, 0.80 * h, 0.75 * w, 0.90 * h)
    ..cubicTo(0.71 * w, 0.98 * h, 0.61 * w, 0.99 * h, 0.50 * w, 0.99 * h)
    ..close();

  static Path _toes(double w, double h) {
    Rect toe(double x, double y, double rx, double ry) => Rect.fromCenter(
          center: Offset(x * w, y * h),
          width: 2 * rx * w,
          height: 2 * ry * h,
        );
    return Path()
      ..addOval(toe(0.25, 0.115, 0.115, 0.095))
      ..addOval(toe(0.465, 0.065, 0.075, 0.062))
      ..addOval(toe(0.625, 0.085, 0.066, 0.055))
      ..addOval(toe(0.76, 0.135, 0.058, 0.048))
      ..addOval(toe(0.865, 0.215, 0.05, 0.041));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pale = Color.lerp(color, Colors.white, 0.80)!;
    final hi = Color.lerp(color, Colors.white, 0.45)!;

    if (mirror) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    final foot = Path.combine(PathOperation.union, _sole(w, h), _toes(w, h));
    canvas.drawPath(foot, Paint()..color = pale);

    canvas.save();
    canvas.clipPath(foot);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.27, h * 0.38, w * 0.10, h * 0.26),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    if (fill > 0) {
      final topY = h - fill * h;
      canvas.drawRect(
        Rect.fromLTWH(0, topY, w, h - topY),
        Paint()..color = color,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, topY, w, 1.5),
        Paint()..color = hi.withValues(alpha: 0.7),
      );
      final streakTop = math.max(topY + 3, h * 0.38);
      final streakBottom = h * 0.64;
      if (streakBottom > streakTop) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(w * 0.27, streakTop, w * 0.37, streakBottom),
            Radius.circular(w * 0.06),
          ),
          Paint()..color = hi.withValues(alpha: 0.7),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FootPainter old) =>
      old.fill != fill || old.color != color || old.mirror != mirror;
}

class StopwatchPainter extends CustomPainter {
  StopwatchPainter({required this.fill, required this.color});

  final double fill;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = math.min(w / 2, h * 0.43);
    final center = Offset(w / 2, h - r);
    final pale = Color.lerp(color, Colors.white, 0.80)!;
    final face = Color.lerp(color, Colors.white, 0.93)!;
    final hi = Color.lerp(color, Colors.white, 0.45)!;
    final ink = Color.lerp(color, Colors.black, 0.30)!;
    final paleFill = Paint()..color = pale;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, center.dy - r - r * 0.10),
          width: r * 0.22,
          height: r * 0.26,
        ),
        Radius.circular(r * 0.04),
      ),
      paleFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, center.dy - r - r * 0.24),
          width: r * 0.50,
          height: r * 0.20,
        ),
        Radius.circular(r * 0.10),
      ),
      paleFill,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -r - r * 0.06),
          width: r * 0.24,
          height: r * 0.24,
        ),
        Radius.circular(r * 0.06),
      ),
      paleFill,
    );
    canvas.restore();

    canvas.drawCircle(center, r, paleFill);
    final inner = r * 0.80;
    canvas.drawCircle(center, inner, Paint()..color = face);

    final tick = Paint()
      ..color = pale
      ..strokeWidth = math.max(1.2, r * 0.07)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(center + dir * inner * 0.70, center + dir * inner * 0.88, tick);
    }

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * fill.clamp(0.0, 1.0);
    if (fill > 0) {
      final disc = Rect.fromCircle(center: center, radius: inner);
      canvas.drawArc(disc, start, sweep, true, Paint()..color = color);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: inner * 0.62),
        start + sweep * 0.12,
        sweep * 0.5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, r * 0.08)
          ..strokeCap = StrokeCap.round
          ..color = hi.withValues(alpha: 0.7),
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.90),
      math.pi * 1.08,
      math.pi * 0.34,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, r * 0.07)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.7),
    );

    final hand = start + sweep;
    canvas.drawLine(
      center,
      center + Offset(math.cos(hand), math.sin(hand)) * inner * 0.86,
      Paint()
        ..color = ink
        ..strokeWidth = math.max(1.4, r * 0.09)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, math.max(1.6, r * 0.11), Paint()..color = ink);
  }

  @override
  bool shouldRepaint(covariant StopwatchPainter old) =>
      old.fill != fill || old.color != color;
}

class DialPainter extends CustomPainter {
  DialPainter({required this.fill, required this.color});

  final double fill;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    final pale = Color.lerp(color, Colors.white, 0.80)!;
    final face = Color.lerp(color, Colors.white, 0.93)!;
    final ink = Color.lerp(color, Colors.black, 0.30)!;
    final amount = fill.clamp(0.0, 1.0);

    canvas.drawCircle(center, r, Paint()..color = pale);

    final small = r <= 30;
    final count = small ? 12 : 28;
    final tick = Paint()
      ..strokeWidth = small ? math.max(2.0, r * 0.16) : r * 0.10
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final lit = (amount * count - i).clamp(0.0, 1.0);
      final a = 2 * math.pi * (i + 0.5) / count;
      final dir = Offset(math.sin(a), -math.cos(a));
      tick.color = Color.lerp(Colors.white.withValues(alpha: 0.75), color, lit)!;
      canvas.drawLine(
        center + dir * r * (small ? 0.70 : 0.74),
        center + dir * r * (small ? 0.84 : 0.86),
        tick,
      );
    }

    final knob = r * (small ? 0.50 : 0.60);
    final knobPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: knob));
    canvas.drawShadow(knobPath, ink, math.max(1.5, r * 0.08), false);
    canvas.drawCircle(
      center,
      knob,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [Colors.white, face, Color.lerp(face, pale, 0.6)!],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: knob)),
    );
    canvas.drawCircle(
      center,
      knob * 0.86,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.025)
        ..color = pale,
    );

    final angle = -math.pi / 2 + 2 * math.pi * amount;
    final dir = Offset(math.cos(angle), math.sin(angle));
    canvas.drawLine(
      center + dir * knob * 0.56,
      center + dir * knob * 0.76,
      Paint()
        ..color = amount > 0 ? color : pale
        ..strokeWidth = math.max(1.8, r * 0.11)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant DialPainter old) =>
      old.fill != fill || old.color != color;
}
