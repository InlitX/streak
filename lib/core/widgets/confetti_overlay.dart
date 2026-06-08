import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_palette.dart';

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.trigger});

  final int trigger;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  final _random = math.Random();
  final List<_Particle> _particles = [];

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _spawn();
      _controller.forward(from: 0);
    }
  }

  void _spawn() {
    _particles
      ..clear()
      ..addAll(List.generate(90, (_) {
        final angle = _random.nextDouble() * 2 * math.pi;
        return _Particle(
          angle: angle,
          speed: 160 + _random.nextDouble() * 320,
          color: AppPalette.habitColors[
              _random.nextInt(AppPalette.habitColors.length)],
          size: 6 + _random.nextDouble() * 8,
          rotation: _random.nextDouble() * 2 * math.pi,
          spin: (_random.nextDouble() - 0.5) * 12,
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
            painter: _ConfettiPainter(_particles, _controller.value),
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.rotation,
    required this.spin,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double rotation;
  final double spin;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress);

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.28);
    const gravity = 520.0;
    final opacity = progress < 0.7 ? 1.0 : (1 - (progress - 0.7) / 0.3);

    for (final p in particles) {
      final dx = origin.dx + math.cos(p.angle) * p.speed * progress;
      final dy = origin.dy +
          math.sin(p.angle) * p.speed * progress +
          gravity * progress * progress;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + p.spin * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
