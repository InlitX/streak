import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaterCupPainter extends CustomPainter {
  WaterCupPainter({required this.fill});

  final double fill; // 0..1

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
  BookPainter({required this.fill, required this.color});

  final double fill; // 0..1
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pale = Color.lerp(color, Colors.white, 0.82)!;
    final hi = Color.lerp(color, Colors.white, 0.42)!;

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
      old.fill != fill || old.color != color;
}
