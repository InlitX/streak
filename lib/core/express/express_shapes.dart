import 'dart:math' as math;

import 'package:flutter/material.dart';

class ExpressShape {
  const ExpressShape({
    this.exponent = 4.2,
    this.sides = 8,
    this.amplitude = 0,
    this.rotation = 0,
  });

  static const squircle = ExpressShape();
  static const circle = ExpressShape(exponent: 2);
  static const cookie = ExpressShape(exponent: 2, sides: 9, amplitude: 0.085);
  static const flower = ExpressShape(exponent: 2, sides: 6, amplitude: 0.14);
  static const burst = ExpressShape(exponent: 2, sides: 12, amplitude: 0.055);
  static const pebble = ExpressShape(exponent: 2.6, sides: 4, amplitude: 0.045);
  static const clover = ExpressShape(
    exponent: 2,
    sides: 4,
    amplitude: 0.155,
    rotation: 0.78,
  );
  static const gem = ExpressShape(
    exponent: 3.2,
    sides: 6,
    amplitude: 0.03,
    rotation: 0.52,
  );
  static const sunny = ExpressShape(exponent: 2, sides: 8, amplitude: 0.07);

  static const family = [cookie, clover, burst, gem, flower, sunny, pebble];

  static ExpressShape pick(int index) =>
      family[index.abs() % family.length];

  final double exponent;
  final double sides;
  final double amplitude;
  final double rotation;

  ExpressShape copyWith({double? amplitude, double? rotation}) => ExpressShape(
    exponent: exponent,
    sides: sides,
    amplitude: amplitude ?? this.amplitude,
    rotation: rotation ?? this.rotation,
  );

  static ExpressShape lerp(ExpressShape a, ExpressShape b, double t) =>
      ExpressShape(
        exponent: a.exponent + (b.exponent - a.exponent) * t,
        sides: a.sides + (b.sides - a.sides) * t,
        amplitude: a.amplitude + (b.amplitude - a.amplitude) * t,
        rotation: a.rotation + (b.rotation - a.rotation) * t,
      );

  double _unitRadius(double angle) {
    final a = angle + rotation;
    final cos = math.cos(a).abs();
    final sin = math.sin(a).abs();
    final base = math.pow(
      math.pow(cos, exponent) + math.pow(sin, exponent),
      -1 / exponent,
    );
    return base * (1 - amplitude + amplitude * math.cos(sides * a));
  }

  Path path(Rect rect) {
    const steps = 120;
    final center = rect.center;
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final angle = i * 2 * math.pi / steps;
      final radius = _unitRadius(angle);
      final point = Offset(
        center.dx + radius * math.cos(angle) * rx,
        center.dy + radius * math.sin(angle) * ry,
      );
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool operator ==(Object other) =>
      other is ExpressShape &&
      other.exponent == exponent &&
      other.sides == sides &&
      other.amplitude == amplitude &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(exponent, sides, amplitude, rotation);
}

class ExpressBorder extends OutlinedBorder {
  const ExpressBorder({this.shape = ExpressShape.squircle, super.side});

  final ExpressShape shape;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ExpressBorder copyWith({BorderSide? side, ExpressShape? shape}) =>
      ExpressBorder(shape: shape ?? this.shape, side: side ?? this.side);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      shape.path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      shape.path(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      shape.path(rect.deflate(side.width / 2)),
      side.toPaint()..style = PaintingStyle.stroke,
    );
  }

  @override
  ShapeBorder scale(double t) =>
      ExpressBorder(shape: shape, side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is ExpressBorder
      ? ExpressBorder(
          shape: ExpressShape.lerp(a.shape, shape, t),
          side: BorderSide.lerp(a.side, side, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is ExpressBorder
      ? ExpressBorder(
          shape: ExpressShape.lerp(shape, b.shape, t),
          side: BorderSide.lerp(side, b.side, t),
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is ExpressBorder && other.shape == shape && other.side == side;

  @override
  int get hashCode => Object.hash(shape, side);
}

class ExpressBlob extends StatelessWidget {
  const ExpressBlob({
    super.key,
    required this.size,
    required this.color,
    this.shape = ExpressShape.squircle,
    this.child,
    this.spin = 0,
  });

  final double size;
  final Color color;
  final ExpressShape shape;
  final Widget? child;
  final double spin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color,
          shape: ExpressBorder(shape: shape.copyWith(rotation: spin)),
        ),
        child: Center(child: child),
      ),
    );
  }
}
