import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';

const scaleLevels = 5;

const _scaleColors = [
  Color(0xFFE5484D),
  Color(0xFFF2803A),
  Color(0xFFF2C14B),
  Color(0xFF93CF58),
  Color(0xFF34C07A),
];

Color scaleColor(int level) => _scaleColors[(level.clamp(1, scaleLevels)) - 1];

int scaleLevelOf(double count) => count.round().clamp(0, scaleLevels);

String scaleLabel(BuildContext context, int level) => switch (level) {
      1 => context.l10n.scale_1,
      2 => context.l10n.scale_2,
      3 => context.l10n.scale_3,
      4 => context.l10n.scale_4,
      _ => context.l10n.scale_5,
    };

class ScaleFacePainter extends CustomPainter {
  const ScaleFacePainter({required this.level, required this.empty});

  final int level;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final r = side / 2;
    final on = level > 0;
    final ink = on ? const Color(0xFF1C1A22) : empty;

    if (on) {
      canvas.drawCircle(center, r, Paint()..color = scaleColor(level));
    } else {
      canvas.drawCircle(
        center,
        r - side * 0.04,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * 0.08
          ..color = empty,
      );
    }

    final eyeY = center.dy - r * 0.18;
    final eyeX = r * 0.34;
    final eye = Paint()..color = ink;
    final eyeSize = Size(r * 0.17, r * (level == 5 ? 0.17 : 0.24));
    for (final dx in [-eyeX, eyeX]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + dx, eyeY),
          width: eyeSize.width,
          height: eyeSize.height,
        ),
        eye,
      );
    }

    final mouthY = center.dy + r * 0.34;
    final half = r * (level == 3 ? 0.3 : 0.4);
    final bend = switch (level) {
      1 => -0.32,
      2 => -0.16,
      3 => 0.0,
      4 => 0.2,
      5 => 0.42,
      _ => 0.0,
    };
    final left = Offset(center.dx - half, mouthY - r * bend * 0.5);
    final right = Offset(center.dx + half, mouthY - r * bend * 0.5);
    final control = Offset(center.dx, mouthY + r * bend * 0.9);
    final mouth = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(control.dx, control.dy, right.dx, right.dy);
    if (level == 5) {
      mouth.close();
      canvas.drawPath(mouth, Paint()..color = ink);
      return;
    }
    canvas.drawPath(
      mouth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
  }

  @override
  bool shouldRepaint(ScaleFacePainter old) =>
      old.level != level || old.empty != empty;
}

class ScaleFace extends StatelessWidget {
  const ScaleFace({super.key, required this.level, this.size = 24});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: ScaleFacePainter(
          level: level,
          empty: context.tokens.muted.withValues(alpha: 0.6),
        ),
      );
}

class ScaleFaceRow extends StatelessWidget {
  const ScaleFaceRow({
    super.key,
    required this.selected,
    required this.onPick,
    this.size = 44,
    this.labels = true,
  });

  final int selected;
  final ValueChanged<int> onPick;
  final double size;
  final bool labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var level = 1; level <= scaleLevels; level++)
          Expanded(
            child: Semantics(
              button: true,
              selected: level == selected,
              label: scaleLabel(context, level),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(level),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: level == selected ? 1.12 : 1,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity:
                              selected == 0 || level == selected ? 1 : 0.4,
                          duration: const Duration(milliseconds: 180),
                          child: ScaleFace(level: level, size: size),
                        ),
                      ),
                      if (labels) ...[
                        const SizedBox(height: 8),
                        Text(
                          scaleLabel(context, level),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: level == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: level == selected
                                ? context.colors.onSurface
                                : context.tokens.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<int?> showScalePicker(
  BuildContext context, {
  required Habit habit,
  required DateTime date,
}) {
  final current = scaleLevelOf(habit.completions[date.dayKey]?.count ?? 0);
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              habit.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              sheet.l10n.scale_pick_title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: sheet.tokens.muted),
            ),
            const SizedBox(height: 18),
            ScaleFaceRow(
              selected: current,
              onPick: (level) => Navigator.of(sheet).pop(level),
            ),
            if (current > 0) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheet).pop(0),
                child: Text(sheet.l10n.clear),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<void> logScale(
  BuildContext context,
  Habit habit, {
  DateTime? date,
}) async {
  final day = date ?? AppClock.now();
  if (!await confirmUnscheduledDay(context, habit: habit, date: day)) return;
  if (!context.mounted) return;
  await pickScaleLevel(context, habit, day);
}

Future<void> pickScaleLevel(
  BuildContext context,
  Habit habit,
  DateTime day,
) async {
  final level = await showScalePicker(context, habit: habit, date: day);
  if (level == null || !context.mounted) return;
  await context.read<HabitsController>().setProgress(
        habit.id,
        day,
        level.toDouble(),
      );
}

class ScaleChart extends StatelessWidget {
  const ScaleChart({super.key, required this.habit, this.days = 30});

  final Habit habit;
  final int days;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.today();
    final start = today.addDays(-(days - 1));
    final levels = [
      for (var i = 0; i < days; i++)
        scaleLevelOf(habit.completions[start.addDays(i).dayKey]?.count ?? 0),
    ];
    final totals = List.filled(scaleLevels, 0);
    for (final entry in habit.completions.values) {
      final level = scaleLevelOf(entry.count);
      if (level > 0) totals[level - 1]++;
    }
    final muted = context.tokens.muted;
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var level = scaleLevels; level >= 1; level--)
                    ScaleFace(level: level, size: 18),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomPaint(
                  painter: _ScaleLinePainter(
                    levels: levels,
                    grid: muted.withValues(alpha: 0.18),
                    line: habit.color.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                MaterialLocalizations.of(context).formatShortMonthDay(start),
                style: TextStyle(fontSize: 11.5, color: muted),
              ),
              Text(
                MaterialLocalizations.of(context).formatShortMonthDay(today),
                style: TextStyle(fontSize: 11.5, color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            for (var level = 1; level <= scaleLevels; level++)
              Expanded(
                child: Column(
                  children: [
                    ScaleFace(level: level, size: 30),
                    const SizedBox(height: 6),
                    Text(
                      '${totals[level - 1]}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      context.l10n.scale_days(totals[level - 1]),
                      style: TextStyle(fontSize: 11.5, color: muted),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ScaleLinePainter extends CustomPainter {
  const _ScaleLinePainter({
    required this.levels,
    required this.grid,
    required this.line,
  });

  final List<int> levels;
  final Color grid;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 9.0;
    final height = size.height - pad * 2;
    double y(int level) => pad + height * (scaleLevels - level) / (scaleLevels - 1);
    const side = 5.0;
    final step = levels.length > 1 ? (size.width - side * 2) / (levels.length - 1) : 0.0;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var level = 1; level <= scaleLevels; level++) {
      canvas.drawLine(Offset(0, y(level)), Offset(size.width, y(level)), gridPaint);
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = line;
    Path? path;
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      if (level == 0) {
        if (path != null) canvas.drawPath(path, stroke);
        path = null;
        continue;
      }
      final point = Offset(side + step * i, y(level));
      if (path == null) {
        path = Path()..moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    if (path != null) canvas.drawPath(path, stroke);
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      if (level == 0) continue;
      canvas.drawCircle(
        Offset(side + step * i, y(level)),
        4.2,
        Paint()..color = scaleColor(level),
      );
    }
  }

  @override
  bool shouldRepaint(_ScaleLinePainter old) =>
      old.levels.join() != levels.join() ||
      old.grid != grid ||
      old.line != line;
}
