import 'package:flutter/material.dart';

class ExpressAxes {
  const ExpressAxes({
    required this.weight,
    required this.width,
    required this.optical,
    required this.round,
  });

  final double weight;
  final double width;
  final double optical;
  final double round;

  List<FontVariation> get variations => [
    FontVariation('wght', weight),
    FontVariation('wdth', width),
    FontVariation('opsz', optical),
    FontVariation('ROND', round),
  ];

  ExpressAxes copyWith({
    double? weight,
    double? width,
    double? optical,
    double? round,
  }) => ExpressAxes(
    weight: weight ?? this.weight,
    width: width ?? this.width,
    optical: optical ?? this.optical,
    round: round ?? this.round,
  );

  TextStyle at(
    double size, {
    Color? color,
    double? weight,
    double? width,
    double? round,
    double? height,
    double? spacing,
    bool tabular = false,
    TextDecoration? decoration,
  }) {
    final axes = copyWith(weight: weight, width: width, round: round);
    return TextStyle(
      fontFamily: ExpressType.family,
      fontSize: size,
      height: height,
      letterSpacing: spacing,
      color: color,
      decoration: decoration,
      fontVariations: axes.variations,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }
}

class ExpressType {
  const ExpressType._();

  static const family = 'GoogleSansFlex';

  static const display = ExpressAxes(
    weight: 950,
    width: 85,
    optical: 30,
    round: 100,
  );
  static const headline = ExpressAxes(
    weight: 700,
    width: 115,
    optical: 32,
    round: 60,
  );
  static const body = ExpressAxes(
    weight: 450,
    width: 100,
    optical: 16,
    round: 0,
  );
  static const emphasis = ExpressAxes(
    weight: 1000,
    width: 120,
    optical: 40,
    round: 40,
  );
  static const rounded = ExpressAxes(
    weight: 700,
    width: 100,
    optical: 20,
    round: 100,
  );

  static TextTheme theme(Color onSurface) {
    TextStyle d(double size, double line, double spacing) => display.at(
      size,
      height: line / size,
      spacing: spacing,
      color: onSurface,
    );
    TextStyle h(double size, double line, double weight) => headline.at(
      size,
      height: line / size,
      weight: weight,
      color: onSurface,
    );
    TextStyle b(double size, double line, double weight, double spacing) =>
        body.at(
          size,
          height: line / size,
          weight: weight,
          spacing: spacing,
          color: onSurface,
        );

    return TextTheme(
      displayLarge: d(57, 64, -0.25),
      displayMedium: d(45, 52, 0),
      displaySmall: d(36, 44, 0),
      headlineLarge: h(32, 40, 700),
      headlineMedium: h(28, 36, 700),
      headlineSmall: h(24, 32, 700),
      titleLarge: h(22, 28, 800),
      titleMedium: h(16, 24, 800),
      titleSmall: h(14, 20, 800),
      bodyLarge: b(16, 24, 500, 0.5),
      bodyMedium: b(14, 20, 500, 0.25),
      bodySmall: b(12, 16, 500, 0.4),
      labelLarge: b(14, 20, 700, 0.1),
      labelMedium: b(12, 16, 700, 0.5),
      labelSmall: b(11, 16, 700, 0.5),
    );
  }
}
