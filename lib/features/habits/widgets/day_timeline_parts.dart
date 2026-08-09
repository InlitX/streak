import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/quant_progress.dart';

const timelineGutter = 46.0;
const _cardPadding = 12.0;
const _tile = 44.0;
const _iconCenter = _cardPadding + _tile / 2;

class TimelineBlock extends StatelessWidget {
  const TimelineBlock({
    super.key,
    required this.habit,
    required this.date,
    required this.done,
    required this.onOpen,
    required this.onCheck,
  });

  final Habit habit;
  final DateTime date;
  final bool done;
  final VoidCallback onOpen;
  final VoidCallback onCheck;

  double get _tileHeight {
    if (habit.durationMinutes <= 0) return _tile;
    final grown = _tile + (habit.durationMinutes - 15) * 0.85;
    return grown.clamp(_tile, 148.0);
  }

  String _subtitle(BuildContext context) {
    final start = minuteLabel(habit.startMinute);
    if (habit.durationMinutes <= 0) return start;
    return '$start - ${minuteLabel(habit.endMinute)}'
        '  ·  ${spanLabel(habit.durationMinutes)}';
  }

  String? _progressLabel(BuildContext context) {
    if (habit.kind == HabitKind.quantitative) {
      final count = habit.completions[date.dayKey]?.count ?? 0;
      final unit = habit.unitLabel.isEmpty ? '' : ' ${habit.unitLabel}';
      return '${formatAmount(count)}/${formatAmount(habit.perDayTarget)}$unit';
    }
    if (habit.hasSubsteps) {
      final steps = habit.completions[date.dayKey]?.steps.length ?? 0;
      return '$steps/${habit.substeps.length}';
    }
    if (habit.needsFocusSession) return context.l10n.focus_only;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final progress = _progressLabel(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: timelineGutter,
          child: Padding(
            padding: const EdgeInsets.only(top: 14, right: 8),
            child: Text(
              minuteLabel(habit.startMinute),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: context.tokens.muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            button: true,
            child: GestureDetector(
              onTap: onOpen,
              child: Container(
                padding: const EdgeInsets.all(_cardPadding),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(
                    alpha: done ? 0.35 : 0.6,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: _tile,
                      height: _tileHeight,
                      decoration: BoxDecoration(
                        color: habit.color.withValues(alpha: done ? 0.5 : 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: HabitGlyph(
                        glyph: habit.icon,
                        color: done ? scheme.surface : habit.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color:
                                  done ? context.tokens.muted : scheme.onSurface,
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                              decorationColor: context.tokens.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitle(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: context.tokens.muted,
                            ),
                          ),
                          if (progress != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              progress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: habit.color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TimelineCheck(
                      habit: habit,
                      date: date,
                      done: done,
                      onTap: onCheck,
                    ),
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

class TimelineCheck extends StatelessWidget {
  const TimelineCheck({
    super.key,
    required this.habit,
    required this.date,
    required this.done,
    required this.onTap,
  });

  final Habit habit;
  final DateTime date;
  final bool done;
  final VoidCallback onTap;

  bool get _quant => habit.kind == HabitKind.quantitative;

  @override
  Widget build(BuildContext context) {
    final count = habit.completions[date.dayKey]?.count ?? 0;
    final progress = QuantProgress.of(
      count: count,
      target: habit.perDayTarget,
    );
    final color = _quant ? progress.activeColor(habit.color) : habit.color;

    return Semantics(
      button: true,
      label: _quant
          ? context.l10n.a11y_add_amount(habit.name)
          : done
              ? context.l10n.a11y_mark_not_done(habit.name)
              : context.l10n.a11y_mark_done(habit.name),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_quant && !done)
                SizedBox(
                  width: 38,
                  height: 38,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.fraction),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 3,
                      backgroundColor: color.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _quant ? 28 : 34,
                height: _quant ? 28 : 34,
                decoration: BoxDecoration(
                  color: done ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(_quant ? 14 : 11),
                  border: _quant && !done
                      ? null
                      : Border.all(
                          color: done ? color : color.withValues(alpha: 0.55),
                          width: 1.8,
                        ),
                ),
                child: Icon(
                  done
                      ? LucideIcons.check
                      : habit.needsFocusSession
                          ? LucideIcons.timer
                          : _quant
                              ? LucideIcons.plus
                              : LucideIcons.check,
                  size: _quant ? 15 : 18,
                  color: done ? context.colors.surface : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimelineGap extends StatelessWidget {
  const TimelineGap({
    super.key,
    required this.minutes,
    required this.from,
    required this.to,
  });

  final int minutes;
  final Color from;
  final Color to;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          const SizedBox(width: timelineGutter),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(
                      painter: _Hatching(
                        color: context.colors.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _iconCenter + 18,
                          0,
                          12,
                          0,
                        ),
                        child: Center(
                          child: Text(
                            context.l10n.day_timeline_free(spanLabel(minutes)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: context.tokens.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _iconCenter - 2,
                  top: 0,
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(4, double.infinity),
                    painter: _DottedLine(from: from, to: to),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLine extends CustomPainter {
  const _DottedLine({required this.from, required this.to});

  final Color from;
  final Color to;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 9.0;
    final count = (size.height / step).floor();
    if (count <= 0) return;
    for (var i = 0; i <= count; i++) {
      final t = count == 0 ? 0.0 : i / count;
      final paint = Paint()..color = Color.lerp(from, to, t)!;
      canvas.drawCircle(
        Offset(size.width / 2, 3 + i * step),
        2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DottedLine old) => old.from != from || old.to != to;
}

class _Hatching extends CustomPainter {
  const _Hatching({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 7;
    for (var x = -size.height; x < size.width; x += 16) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Hatching old) => old.color != color;
}
