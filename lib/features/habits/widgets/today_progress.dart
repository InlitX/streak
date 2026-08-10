import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/widgets/today_intro.dart';

class TodayProgress extends StatefulWidget {
  const TodayProgress({
    super.key,
    required this.done,
    required this.total,
  });

  final int done;
  final int total;

  double get _ratio => total == 0 ? 0 : done / total;

  @override
  State<TodayProgress> createState() => _TodayProgressState();
}

class _TodayProgressState extends State<TodayProgress>
    with SingleTickerProviderStateMixin {
  static const _introMs = 1900;
  static const _updateMs = 1100;

  late final AnimationController _controller = AnimationController(vsync: this);
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  Tween<double> _tween = Tween(begin: 0, end: 0);

  double get _shown => _tween.transform(_curve.value);

  @override
  void initState() {
    super.initState();
    TodayIntro.tick.addListener(_replay);
    if (TodayIntro.claim(TodayProgress)) {
      _animateTo(widget._ratio, from: 0, ms: _introMs);
    } else {
      _tween = Tween(begin: widget._ratio, end: widget._ratio);
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(TodayProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._ratio != oldWidget._ratio) {
      _animateTo(widget._ratio, from: _shown, ms: _updateMs);
    }
  }

  @override
  void dispose() {
    TodayIntro.tick.removeListener(_replay);
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    if (!mounted || !TodayIntro.claim(TodayProgress)) return;
    _animateTo(widget._ratio, from: 0, ms: _introMs);
  }

  void _animateTo(double value, {required double from, required int ms}) {
    _tween = Tween(begin: from, end: value);
    _controller.duration = Duration(milliseconds: ms);
    _controller.forward(from: 0);
  }

  String _today(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final text = DateFormat('EEEE, d MMM', locale).format(AppClock.now());
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final done = widget.done;
    final total = widget.total;
    final allDone = total > 0 && done == total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _today(context),
                    style: TextStyle(
                      color: context.tokens.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0
                        ? context.l10n.no_habits_yet
                        : allDone
                            ? context.l10n.all_done_today
                            : context.l10n.x_of_y_completed('$done', '$total'),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 58,
              height: 58,
              child: AnimatedBuilder(
                animation: _curve,
                builder: (context, _) {
                  final ratio = _shown;
                  return CustomPaint(
                    painter: _RingPainter(
                      ratio: ratio,
                      color: scheme.primary,
                      track: scheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Text(
                        '${(ratio * 100).round()}%',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.ratio, required this.color, required this.track});

  final double ratio;
  final Color color;
  final Color track;

  static const _stroke = 7.0;
  static const _waves = 14;
  static const _amplitude = 1.4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - _stroke) / 2 - _amplitude;

    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawCircle(center, radius, base);

    if (ratio <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_wave(center, radius), arc);
  }

  Path _wave(Offset center, double radius) {
    final sweep = 2 * math.pi * ratio.clamp(0.0, 1.0);
    final steps = (sweep * 36).ceil().clamp(8, 240);
    final path = Path();

    for (var i = 0; i <= steps; i++) {
      final angle = -math.pi / 2 + sweep * i / steps;
      final wave = radius + _amplitude * math.sin(angle * _waves);
      final point = Offset(
        center.dx + wave * math.cos(angle),
        center.dy + wave * math.sin(angle),
      );
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio || old.color != color || old.track != track;
}
