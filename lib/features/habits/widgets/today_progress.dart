import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/extensions/date_extensions.dart';

class TodayProgress extends StatelessWidget {
  const TodayProgress({
    super.key,
    required this.done,
    required this.total,
  });

  final int done;
  final int total;

  double get _ratio => total == 0 ? 0 : done / total;

  String _today(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final text = DateFormat('EEEE, d MMM', locale).format(AppClock.now());
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  String _message(BuildContext context) {
    if (total == 0) return context.l10n.motiv_start;
    final pct = _ratio;
    if (pct >= 1) return context.l10n.motiv_perfect;
    if (pct >= 0.5) return context.l10n.motiv_almost;
    if (pct > 0) return context.l10n.motiv_progress;
    return context.l10n.motiv_start;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final allDone = total > 0 && done == total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    total == 0
                        ? context.l10n.no_habits_yet
                        : allDone
                            ? context.l10n.all_done_today
                            : context.l10n.x_of_y_completed('$done', '$total'),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _message(context),
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(
                painter: _RingPainter(
                  ratio: _ratio,
                  color: scheme.primary,
                  track: scheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Text(
                    '${(_ratio * 100).round()}%',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, base);

    if (ratio <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * ratio.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio || old.color != color || old.track != track;
}
