import 'package:flutter/material.dart';

class CheckProgress extends StatelessWidget {
  const CheckProgress({
    super.key,
    required this.value,
    required this.size,
    required this.color,
    required this.track,
    this.circle = true,
    this.stroke = 3,
  });

  final double value;
  final double size;
  final Color color;
  final Color track;
  final bool circle;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: circle
          ? CircularProgressIndicator(
              value: value,
              strokeWidth: stroke,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation(color),
            )
          : CustomPaint(
              painter: _SquareProgressPainter(
                value: value,
                color: color,
                track: track,
                stroke: stroke,
              ),
            ),
    );
  }
}

class _SquareProgressPainter extends CustomPainter {
  const _SquareProgressPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final corner = size.shortestSide * 0.3;
    final radius = Radius.circular(corner);
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right - corner, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + corner), radius: radius)
      ..lineTo(rect.right, rect.bottom - corner)
      ..arcToPoint(Offset(rect.right - corner, rect.bottom), radius: radius)
      ..lineTo(rect.left + corner, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - corner), radius: radius)
      ..lineTo(rect.left, rect.top + corner)
      ..arcToPoint(Offset(rect.left + corner, rect.top), radius: radius)
      ..lineTo(rect.center.dx, rect.top);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    final done = value.clamp(0.0, 1.0);
    if (done <= 0) return;

    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * done),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SquareProgressPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke;
}
