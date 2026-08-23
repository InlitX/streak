import 'package:flutter/material.dart';

class MinimalType {
  const MinimalType._();

  static TextStyle display(double size, {Color? color, double height = 1.05}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: height,
        letterSpacing: -0.9,
        color: color,
      );

  static TextStyle figure(double size, {Color? color, double height = 1.05}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: height,
        letterSpacing: -0.8,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle title(double size, {Color? color, double weight = 600}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle body(
    double size, {
    Color? color,
    double height = 1.35,
    double weight = 500,
  }) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    height: height,
    letterSpacing: -0.1,
    color: color,
  );

  static TextStyle label({Color? color, double size = 12.5}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: color,
  );
}
