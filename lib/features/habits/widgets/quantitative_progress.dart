import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/quant_progress.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/check_seal.dart';
import 'package:streak/features/habits/widgets/reading_books.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/habits/widgets/water_cup.dart';

class QuantitativeProgress extends StatelessWidget {
  const QuantitativeProgress({super.key, required this.habit});

  final Habit habit;

  Future<void> _editAmount(BuildContext context, double current) async {
    final allowed = await confirmUnscheduledDay(
      context,
      habit: habit,
      date: AppClock.now(),
    );
    if (!allowed || !context.mounted) return;

    final result = await showNumberKeypadDialog(
      context,
      title: context.l10n.quant_edit_title,
      value: current,
      unit: habit.unitLabel,
      target: habit.perDayTarget,
      decimals: true,
      accent: habit.color,
    );
    if (result != null && result >= 0 && result != current && context.mounted) {
      context.read<HabitsController>().setProgress(habit.id, AppClock.now(), result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now();
    final count = habit.completions[today.dayKey]?.count ?? 0;
    final ratio =
        habit.perDayTarget <= 0 ? 0.0 : (count / habit.perDayTarget).clamp(0.0, 1.0);
    final controller = context.read<HabitsController>();

    Future<void> add(double delta) async {
      if (delta > 0) {
        final allowed =
            await confirmUnscheduledDay(context, habit: habit, date: today);
        if (!allowed) return;
      }
      HapticFeedback.selectionClick();
      await controller.addProgress(habit.id, today, delta);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            switch (habit.quantKind) {
              QuantKind.water =>
                _WaterCups(count: count, target: habit.perDayTarget),
              QuantKind.reading =>
                ReadingBooks(habit: habit, ratio: ratio, count: count),
              QuantKind.generic || QuantKind.time => _GenericRing(
                  progress: QuantProgress.of(
                    count: count,
                    target: habit.perDayTarget,
                  ),
                  color: habit.color,
                ),
            },
            const SizedBox(height: 18),
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: () => _editAmount(context, count),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${habit.amountText(count)} / '
                        '${habit.amountText(habit.perDayTarget)}'
                        '${habit.isTimeAmount ? '' : ' ${habit.unitLabel}'}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.pencil,
                          size: 14, color: context.tokens.muted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              context.l10n.quant_daily_goal,
              style: TextStyle(fontSize: 13, color: context.tokens.muted),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundActionButton(
                  icon: LucideIcons.minus,
                  label: context.l10n.a11y_decrease,
                  color: habit.color,
                  onTap: count > 0 ? () => add(-habit.incrementAmount) : null,
                ),
                const SizedBox(width: 20),
                _RoundActionButton(
                  icon: LucideIcons.plus,
                  label: context.l10n.a11y_increase,
                  color: habit.color,
                  filled: true,
                  onTap: () => add(habit.incrementAmount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatefulWidget {
  const _RoundActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;

  @override
  State<_RoundActionButton> createState() => _RoundActionButtonState();
}

class _RoundActionButtonState extends State<_RoundActionButton> {
  Timer? _timer;
  int _count = 0;

  void _tick() {
    final onTap = widget.onTap;
    if (onTap == null) {
      _stop();
      return;
    }
    onTap();
    _count++;
    final ms = _count < 5 ? 140 : (_count < 12 ? 80 : 45);
    _timer = Timer(Duration(milliseconds: ms), _tick);
  }

  void _startRepeat() {
    if (widget.onTap == null) return;
    _count = 0;
    _tick();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final disabled = widget.onTap == null;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPressStart: disabled ? null : (_) => _startRepeat(),
        onLongPressEnd: (_) => _stop(),
        onLongPressCancel: _stop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: disabled
                ? color.withValues(alpha: 0.08)
                : widget.filled
                    ? color
                    : color.withValues(alpha: 0.14),
          ),
          child: Icon(
            widget.icon,
            size: 22,
            color: disabled
                ? color.withValues(alpha: 0.3)
                : widget.filled
                    ? Colors.white
                    : color,
          ),
        ),
      ),
    );
  }
}

class _WaterCups extends StatelessWidget {
  const _WaterCups({required this.count, required this.target});

  final double count;
  final double target;

  static const cupCount = 10;
  static const _firstRow = 6;

  @override
  Widget build(BuildContext context) {
    final perCup = target <= 0 ? 1.0 : target / cupCount;
    var progress = perCup <= 0 ? 0.0 : count / perCup;
    if (!progress.isFinite) progress = 0.0;

    Widget glass(int i) {
      final fill = (progress - i).clamp(0.0, 1.0);
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fill),
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => SizedBox(
          width: 33,
          height: 48,
          child: CustomPaint(painter: WaterCupPainter(fill: t)),
        ),
      );
    }

    Widget row(int start, int end) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = start; i < end; i++) ...[
              if (i > start) const SizedBox(width: 12),
              glass(i),
            ],
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(0, _firstRow),
        const SizedBox(height: 14),
        row(_firstRow, cupCount),
      ],
    );
  }
}


class _GenericRing extends StatelessWidget {
  const _GenericRing({required this.progress, required this.color});

  final QuantProgress progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reached = progress.reachedGoal;
    final reachedColor = progress.reachedColor(color);
    final activeColor = progress.activeColor(color);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.fraction),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => SizedBox(
          width: 138,
          height: 138,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(138, 138),
                painter: _RingPainter(
                  ratio: t,
                  color: activeColor,
                  track: reached ? reachedColor : color.withValues(alpha: 0.13),
                ),
              ),
              if (reached)
                CheckSeal(color: progress.solidColor(color))
              else
                Text(
                  '${(t * 100).round()}%',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: color,
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
  _RingPainter({required this.ratio, required this.color, required this.track});

  final double ratio;
  final Color color;
  final Color track;

  static const _stroke = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - _stroke) / 2;
    final arc = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = track,
    );

    if (ratio <= 0) return;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * ratio;
    final light = Color.lerp(color, Colors.white, 0.35)!;
    canvas.drawArc(
      arc,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + 2 * math.pi,
          colors: [light, color, light],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientRotation(start),
        ).createShader(arc),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.ratio != ratio || old.color != color || old.track != track;
}
