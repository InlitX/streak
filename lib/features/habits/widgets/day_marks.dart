import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';

enum DayMark { chance, vacation }

const _frostLight = Color(0xFFFFF1F6);
const _frostMid = Color(0xFFFBB8CF);
const _frostDeep = Color(0xFFEC7AA3);
const _heartInk = Color(0xFFC0285F);
const _skyTop = Color(0xFF63C3FF);
const _skyLow = Color(0xFFBFE8FF);
const _seaTop = Color(0xFF2EC4C6);
const _seaLow = Color(0xFF86E0D6);
const _sandTop = Color(0xFFFFE6B8);
const _sandLow = Color(0xFFFFC98A);
const _palmInk = Color(0xFF17694D);

DayMark? dayMarkOf(Habit habit, DateTime date) {
  if (date.isAfter(AppClock.today())) return null;
  if (habit.isChanceDay(date)) return DayMark.chance;
  if (habit.isVacationOn(date)) return DayMark.vacation;
  return null;
}

extension DayMarkLook on DayMark {
  Color get fill => switch (this) {
    DayMark.chance => _frostMid,
    DayMark.vacation => _skyLow,
  };

  IconData get icon => switch (this) {
    DayMark.chance => Icons.favorite_rounded,
    DayMark.vacation => LucideIcons.treePalm,
  };

  Color ink(BuildContext context) => switch (this) {
    DayMark.chance => _heartInk,
    DayMark.vacation => _palmInk,
  };

  Widget glyph(BuildContext context, double size) => Icon(
    icon,
    size: size,
    color: ink(context),
    shadows: [
      Shadow(
        color: Colors.white.withValues(alpha: 0.8),
        blurRadius: size * 0.35,
      ),
    ],
  );
}

void paintDayMark(Canvas canvas, RRect shape, DayMark mark, {bool rim = true}) {
  final rect = shape.outerRect;
  canvas.save();
  canvas.clipRRect(shape);
  switch (mark) {
    case DayMark.chance:
      _paintFrost(canvas, rect);
    case DayMark.vacation:
      _paintBeach(canvas, rect);
  }
  canvas.restore();
  if (rim && shape.height >= 14) {
    canvas.drawRRect(
      shape.deflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0.15),
          ],
        ).createShader(rect),
    );
  }
}

void _paintFrost(Canvas canvas, Rect rect) {
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_frostLight, _frostMid, _frostDeep],
        stops: [0, 0.5, 1],
      ).createShader(rect),
  );
  final w = rect.width;
  final h = rect.height;
  canvas.drawPath(
    Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + h * 0.3)
      ..lineTo(rect.left, rect.top + h * 0.5)
      ..close(),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.12),
        ],
      ).createShader(rect),
  );
  canvas.drawPath(
    Path()
      ..moveTo(rect.left + w * 0.62, rect.bottom)
      ..lineTo(rect.left + w * 0.7, rect.bottom)
      ..lineTo(rect.right, rect.top + h * 0.55)
      ..lineTo(rect.right, rect.top + h * 0.42)
      ..close(),
    Paint()..color = Colors.white.withValues(alpha: 0.3),
  );
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 1.1,
        colors: [
          const Color(0xFFE24F86).withValues(alpha: 0.35),
          const Color(0xFFE24F86).withValues(alpha: 0),
        ],
      ).createShader(rect),
  );
  if (h >= 30) {
    final side = math.min(w, h);
    _sparkle(canvas, rect.topLeft + Offset(side * 0.2, side * 0.2), side * 0.1);
    if (h >= 60) {
      _sparkle(
        canvas,
        rect.bottomRight - Offset(side * 0.2, side * 0.22),
        side * 0.055,
      );
    }
  }
}

void _paintBeach(Canvas canvas, Rect rect) {
  final h = rect.height;
  final sea = rect.top + h * 0.5;
  final shore = rect.top + h * 0.68;
  canvas.drawRect(
    Rect.fromLTRB(rect.left, rect.top, rect.right, sea + 1),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyTop, _skyLow],
      ).createShader(Rect.fromLTRB(rect.left, rect.top, rect.right, sea)),
  );
  canvas.drawRect(
    Rect.fromLTRB(rect.left, sea, rect.right, shore + 1),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_seaTop, _seaLow],
      ).createShader(Rect.fromLTRB(rect.left, sea, rect.right, shore)),
  );
  final step = math.max(h * 0.3, 5.0);
  final lift = math.max(h * 0.05, 0.8);
  final sand = Path()..moveTo(rect.left, shore);
  for (var x = rect.left; x < rect.right; x += step) {
    sand.quadraticBezierTo(x + step / 4, shore - lift, x + step / 2, shore);
    sand.quadraticBezierTo(x + step * 3 / 4, shore + lift, x + step, shore);
  }
  final foam = Path.from(sand);
  sand
    ..lineTo(rect.right, rect.bottom)
    ..lineTo(rect.left, rect.bottom)
    ..close();
  canvas.drawPath(
    sand,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_sandTop, _sandLow],
      ).createShader(Rect.fromLTRB(rect.left, shore, rect.right, rect.bottom)),
  );
  canvas.drawPath(
    foam,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(h * 0.045, 0.8)
      ..color = Colors.white.withValues(alpha: 0.9),
  );
  canvas.drawLine(
    Offset(rect.left, sea),
    Offset(rect.right, sea),
    Paint()
      ..strokeWidth = math.max(h * 0.02, 0.5)
      ..color = Colors.white.withValues(alpha: 0.45),
  );
  if (h >= 18) {
    final sun = Offset(rect.right - h * 0.26, rect.top + h * 0.24);
    canvas.drawCircle(
      sun,
      h * 0.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF4B8).withValues(alpha: 0.9),
            const Color(0xFFFFF4B8).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: h * 0.2)),
    );
    canvas.drawCircle(sun, h * 0.085, Paint()..color = const Color(0xFFFFF8D6));
  }
}

void _sparkle(Canvas canvas, Offset center, double r) {
  final path = Path()
    ..moveTo(center.dx, center.dy - r)
    ..quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy)
    ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
    ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
    ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r)
    ..close();
  canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.95));
}

class DayMarkTile extends StatelessWidget {
  const DayMarkTile({
    super.key,
    required this.mark,
    required this.radius,
    this.child,
  });

  final DayMark? mark;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final mark = this.mark;
    if (mark == null) return child ?? const SizedBox.shrink();
    return CustomPaint(
      painter: _DayMarkPainter(mark, radius),
      child: child ??
          LayoutBuilder(
            builder: (context, box) {
              final side = math.min(box.maxWidth, box.maxHeight);
              if (!side.isFinite || side < 10) return const SizedBox.expand();
              return Center(child: mark.glyph(context, side * 0.58));
            },
          ),
    );
  }
}

class _DayMarkPainter extends CustomPainter {
  const _DayMarkPainter(this.mark, this.radius);

  final DayMark mark;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    paintDayMark(
      canvas,
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      mark,
    );
  }

  @override
  bool shouldRepaint(_DayMarkPainter old) =>
      old.mark != mark || old.radius != radius;
}

class DayMarkCorner extends StatelessWidget {
  const DayMarkCorner({
    super.key,
    required this.mark,
    required this.child,
    this.size = 10,
    this.inset = 3,
  });

  final DayMark? mark;
  final Widget child;
  final double size;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final mark = this.mark;
    if (mark == null) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          bottom: inset,
          right: inset,
          child: mark.glyph(context, size),
        ),
      ],
    );
  }
}
