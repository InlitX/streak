import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/timeline_week_strip.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class TodayWeekStrip extends StatelessWidget {
  const TodayWeekStrip({
    super.key,
    required this.habits,
    required this.onSelected,
  });

  final List<Habit> habits;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final today = AppClock.today();
    final first = today.startOfWeek(settings.weekStart);
    final tallies = TimelineWeekStrip.tallies(habits, first);
    final locale = Localizations.localeOf(context);
    final labels = WeekdayLabels.shortFrom(locale.languageCode, first.weekday);
    final scheme = context.colors;
    final accent = settings.isMinimalStyle ? scheme.onSurface : scheme.primary;
    final ink = settings.isMinimalStyle ? scheme.surface : scheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _Day(
                day: first.addDays(i),
                label: labels[i].replaceAll('.', ''),
                done: tallies[i].done,
                due: tallies[i].due,
                today: today,
                accent: accent,
                ink: ink,
                onTap: onSelected,
              ),
            ),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.label,
    required this.done,
    required this.due,
    required this.today,
    required this.accent,
    required this.ink,
    required this.onTap,
  });

  final DateTime day;
  final String label;
  final int done;
  final int due;
  final DateTime today;
  final Color accent;
  final Color ink;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final muted = context.tokens.muted;
    final future = day.isAfter(today);
    final isToday = day.isSameDay(today);
    final complete = due > 0 && done >= due;
    final ratio = due == 0 ? 0.0 : (done / due).clamp(0.0, 1.0);
    final locale = Localizations.localeOf(context).toString();
    final name = DateFormat.MMMMEEEEd(locale).format(day);

    return Semantics(
      button: !future,
      label: due == 0 ? name : '$name, $done/$due',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: future ? null : () => onTap(day),
        child: Opacity(
          opacity: future ? 0.4 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: isToday ? scheme.onSurface : muted,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 38,
                height: 38,
                child: CustomPaint(
                  painter: _RingPainter(
                    ratio: ratio,
                    complete: complete,
                    accent: accent,
                    track: scheme.onSurface.withValues(alpha: 0.12),
                    outline: isToday ? accent : Colors.transparent,
                  ),
                  child: Center(
                    child: complete
                        ? Icon(LucideIcons.check, size: 17, color: ink)
                        : Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w600,
                              color: isToday || due > 0
                                  ? scheme.onSurface
                                  : muted,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.ratio,
    required this.complete,
    required this.accent,
    required this.track,
    required this.outline,
  });

  final double ratio;
  final bool complete;
  final Color accent;
  final Color track;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    if (complete) {
      canvas.drawCircle(center, radius, Paint()..color = accent);
      return;
    }
    const stroke = 3.2;
    final rect = Rect.fromCircle(center: center, radius: radius - 2.5);
    if (outline.a > 0) {
      canvas.drawCircle(
        center,
        radius - 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = outline.withValues(alpha: 0.5),
      );
    }
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (ratio > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * ratio,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke
          ..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio ||
      old.complete != complete ||
      old.accent != accent ||
      old.track != track ||
      old.outline != outline;
}
