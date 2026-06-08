import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/app/theme/app_tokens.dart';

/// Area chart of completions per month across a year (12 values, Jan–Dec).
class MonthlyAreaChart extends StatelessWidget {
  const MonthlyAreaChart({super.key, required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final maxValue = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 130,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => CustomPaint(
              size: Size.infinite,
              painter: _AreaPainter(
                values: values,
                maxValue: maxValue == 0 ? 1 : maxValue,
                color: scheme.primary,
                grid: scheme.surfaceContainerHighest,
                progress: t,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var m = 0; m < 12; m++)
              Expanded(
                child: Text(
                  // First letter of each month, spaced to avoid clutter.
                  m % 2 == 0
                      ? DateFormat.MMM().format(DateTime(2020, m + 1))
                      : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.muted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter({
    required this.values,
    required this.maxValue,
    required this.color,
    required this.grid,
    required this.progress,
  });

  final List<int> values;
  final int maxValue;
  final Color color;
  final Color grid;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final norm = values[i] / maxValue;
      final x = stepX * i;
      final y = size.height - size.height * norm * 0.9 * progress - 4;
      points.add(Offset(x, y));
    }

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      line.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.4),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_AreaPainter old) => old.progress != progress;
}
