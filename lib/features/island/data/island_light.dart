import 'dart:ui';

class IslandLight {
  const IslandLight._();

  static const List<double> _luma = [0.2126, 0.7152, 0.0722];

  static const List<(double, double, double, double, double)> _sky = [
    (0, 0.50, 0.56, 0.72, 0.14),
    (5, 0.50, 0.56, 0.72, 0.14),
    (6.5, 0.80, 0.74, 0.74, 0.06),
    (8.5, 1.00, 0.99, 0.97, 0.00),
    (17, 1.00, 1.00, 1.00, 0.00),
    (19, 1.02, 0.90, 0.76, 0.00),
    (20.5, 0.80, 0.70, 0.72, 0.05),
    (22, 0.50, 0.56, 0.72, 0.14),
    (24, 0.50, 0.56, 0.72, 0.14),
  ];

  static double hourOf(DateTime now) => now.hour + now.minute / 60;

  static bool isDark(DateTime now) {
    final tone = _toneAt(hourOf(now));
    return (tone.$1 + tone.$2 + tone.$3) / 3 < 0.82;
  }

  static (double, double, double, double) _toneAt(double hour) {
    for (var i = 1; i < _sky.length; i++) {
      final next = _sky[i];
      if (hour > next.$1) continue;
      final prev = _sky[i - 1];
      final span = next.$1 - prev.$1;
      final t = span == 0 ? 0.0 : (hour - prev.$1) / span;
      return (
        prev.$2 + (next.$2 - prev.$2) * t,
        prev.$3 + (next.$3 - prev.$3) * t,
        prev.$4 + (next.$4 - prev.$4) * t,
        prev.$5 + (next.$5 - prev.$5) * t,
      );
    }
    return (1, 1, 1, 0);
  }

  static List<double>? matrixFor(DateTime now) {
    final (r, g, b, desat) = _toneAt(hourOf(now));
    if (desat < 0.005 && (r - 1).abs() < 0.02 && (g - 1).abs() < 0.02 &&
        (b - 1).abs() < 0.02) {
      return null;
    }
    final keep = 1 - desat;
    return [
      r * (keep + desat * _luma[0]), r * desat * _luma[1], r * desat * _luma[2], 0, 0,
      g * desat * _luma[0], g * (keep + desat * _luma[1]), g * desat * _luma[2], 0, 0,
      b * desat * _luma[0], b * desat * _luma[1], b * (keep + desat * _luma[2]), 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static Color ghostFor(DateTime now, bool darkTheme) {
    final dark = darkTheme || isDark(now);
    return dark
        ? const Color(0xFFDCE6F2).withValues(alpha: 0.30)
        : const Color(0xFF4A5665).withValues(alpha: 0.28);
  }
}
