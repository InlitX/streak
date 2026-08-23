import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:streak/core/widgets/celebration_palette.dart';

class FireworksOverlay extends StatefulWidget {
  const FireworksOverlay({super.key, required this.trigger});

  final int trigger;

  @override
  State<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _FireworksOverlayState extends State<FireworksOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  static const _count = 5;

  final _random = math.Random();
  final List<_Shell> _shells = [];

  bool _fired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fired || widget.trigger <= 0) return;
    _fired = true;
    _fire();
  }

  @override
  void didUpdateWidget(FireworksOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) _fire();
  }

  void _fire() {
    _spawn(Theme.of(context).brightness);
    _controller.forward(from: 0);
  }

  void _spawn(Brightness brightness) {
    _shells
      ..clear()
      ..addAll(List.generate(_count, (index) {
        final color = celebrationColor(_random, brightness);
        final band = 0.52 / _count;
        return _Shell(
          core: brightness == Brightness.dark
              ? Colors.white
              : Color.lerp(color, Colors.black, 0.4)!,
          hot: Color.lerp(
            color,
            brightness == Brightness.dark ? Colors.white : Colors.black,
            0.42,
          )!,
          x: 0.24 + band * (index + _random.nextDouble()),
          peak: 0.16 + _random.nextDouble() * 0.26,
          start: index * 0.085 + _random.nextDouble() * 0.05,
          color: color,
          sparks: List.generate(62 + _random.nextInt(18), (_) {
            final angle = _random.nextDouble() * 2 * math.pi;
            return _Spark(
              direction: Offset(math.cos(angle), math.sin(angle)),
              speed: 0.30 * (0.6 + _random.nextDouble() * 0.4),
              size: 1.6 + _random.nextDouble() * 2.0,
              twinkle: _random.nextDouble() * 2 * math.pi,
              hot: _random.nextDouble() < 0.25,
            );
          }),
        );
      }));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isDismissed) return const SizedBox.expand();
          return CustomPaint(
            size: Size.infinite,
            painter: _FireworksPainter(_shells, _controller.value),
          );
        },
      ),
    );
  }
}

class _Spark {
  _Spark({
    required this.direction,
    required this.speed,
    required this.size,
    required this.twinkle,
    required this.hot,
  });

  final Offset direction;
  final double speed;
  final double size;
  final double twinkle;
  final bool hot;
}

class _Shell {
  _Shell({
    required this.x,
    required this.peak,
    required this.start,
    required this.color,
    required this.core,
    required this.hot,
    required this.sparks,
  });

  final double x;
  final double peak;
  final double start;
  final Color color;
  final Color core;
  final Color hot;
  final List<_Spark> sparks;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.shells, this.progress);

  final List<_Shell> shells;
  final double progress;

  static const _life = 0.56;
  static const _rise = 0.34;
  static const _gravity = 0.42;
  static const _trail = 0.055;

  @override
  void paint(Canvas canvas, Size size) {
    for (final shell in shells) {
      final t = (progress - shell.start) / _life;
      if (t <= 0 || t >= 1) continue;
      if (t < _rise) {
        _paintRise(canvas, size, shell, t / _rise);
      } else {
        _paintBurst(canvas, size, shell, (t - _rise) / (1 - _rise));
      }
    }
  }

  void _paintRise(Canvas canvas, Size size, _Shell shell, double t) {
    final eased = 1 - math.pow(1 - t, 2.2).toDouble();
    final x = shell.x * size.width;
    final y = size.height * (1.05 - (1.05 - shell.peak) * eased);
    final paint = Paint()..color = shell.color;

    for (var i = 0; i < 6; i++) {
      final trail = y + i * size.height * 0.012;
      paint.color = shell.color.withValues(alpha: (1 - i / 6) * 0.55);
      canvas.drawCircle(Offset(x, trail), 2.6 - i * 0.3, paint);
    }
    paint.color = shell.core.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(x, y), 2.4, paint);
  }

  void _paintBurst(Canvas canvas, Size size, _Shell shell, double e) {
    final origin = Offset(shell.x * size.width, shell.peak * size.height);
    final unit = size.width;
    final spread = e * (2 - e);
    final back = math.max(0.0, e - _trail);
    final backSpread = back * (2 - back);
    final fade = math.pow(1 - e, 1.6).toDouble();

    if (e < 0.09) {
      final flash = 1 - e / 0.09;
      canvas.drawCircle(
        origin,
        unit * 0.015 * flash,
        Paint()..color = shell.core.withValues(alpha: flash),
      );
    }

    final drop = Offset(0, _gravity * e * e * unit);
    final backDrop = Offset(0, _gravity * back * back * unit);
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (final spark in shell.sparks) {
      final twinkle = e < 0.45
          ? 1.0
          : 0.62 + 0.38 * math.sin(e * 26 + spark.twinkle);
      final alpha = (fade * twinkle).clamp(0.0, 1.0);
      if (alpha < 0.04) continue;

      final reach = spark.speed * unit;
      final head = origin + spark.direction * (reach * spread) + drop;
      if (head.dy > size.height + unit || head.dx < -unit ||
          head.dx > size.width + unit) {
        continue;
      }
      final tail = origin + spark.direction * (reach * backSpread) + backDrop;

      paint
        ..color = (spark.hot ? shell.hot : shell.color).withValues(alpha: alpha)
        ..strokeWidth = spark.size * (1 - 0.3 * e) * 1.15;
      canvas.drawLine(tail, head, paint);
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.progress != progress;
}
