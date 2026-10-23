import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:streak/features/habits/widgets/health_steps_widgets.dart';
import 'package:streak/features/habits/widgets/reading_books.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/habits/widgets/water_cup.dart';
import 'package:streak/core/extensions/color_extensions.dart';

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
      target: habit.hasGoal ? habit.perDayTarget : null,
      decimals: true,
      clock: habit.isTimeAmount,
      accent: habit.color.shownIn(context),
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
      await controller.addProgress(habit.id, today, delta);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            switch (habit.hasGoal ? habit.quantKind : QuantKind.generic) {
              QuantKind.water =>
                _WaterCups(count: count, target: habit.perDayTarget),
              QuantKind.reading =>
                ReadingBooks(habit: habit, ratio: ratio, count: count),
              QuantKind.time => _Stopwatch(
                  progress: habit.progressFor(count),
                  color: habit.color.shownIn(context),
                ),
              QuantKind.generic when habit.readsSteps && habit.hasGoal =>
                _StepsTrail(
                  ratio: ratio,
                  color: habit.progressFor(count)
                      .solidColor(habit.color.shownIn(context)),
                ),
              QuantKind.generic => _GenericRing(
                  progress: habit.progressFor(count),
                  color: habit.color.shownIn(context),
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
                        habit.hasGoal
                            ? '${habit.amountText(count)} / '
                                '${habit.amountText(habit.perDayTarget)}'
                                '${habit.isTimeAmount ? '' : ' ${habit.unitLabel}'}'
                            : '${habit.amountText(count)}'
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
            if (habit.tracksBook) ...[
              const SizedBox(height: 10),
              _BookLine(habit: habit),
            ],
            if (habit.readsSteps) ...[
              const SizedBox(height: 10),
              HealthStepsBadge(color: habit.color.shownIn(context)),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundActionButton(
                  icon: LucideIcons.minus,
                  label: context.l10n.a11y_decrease,
                  color: habit.color.shownIn(context),
                  onTap: count > 0 ? () => add(-habit.incrementAmount) : null,
                ),
                const SizedBox(width: 20),
                _RoundActionButton(
                  icon: LucideIcons.plus,
                  label: context.l10n.a11y_increase,
                  color: habit.color.shownIn(context),
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
                    ? color.ink
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


class _StepsTrail extends StatelessWidget {
  const _StepsTrail({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  static const _prints = 10;
  static const _perRow = 5;

  @override
  Widget build(BuildContext context) {
    final progress = ratio * _prints;

    Widget footprint(int i) {
      final fill = (progress - i).clamp(0.0, 1.0);
      final left = i.isEven;
      return Transform.translate(
        offset: Offset(0, left ? 5 : -5),
        child: Transform.rotate(
          angle: left ? -0.12 : 0.12,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fill),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => SizedBox(
              width: 32,
              height: 44,
              child: CustomPaint(
                painter: FootPainter(fill: t, color: color, mirror: left),
              ),
            ),
          ),
        ),
      );
    }

    Widget row(int start) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = start; i < start + _perRow; i++) ...[
              if (i > start) const SizedBox(width: 14),
              footprint(i),
            ],
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(0),
        const SizedBox(height: 18),
        row(_perRow),
      ],
    );
  }
}

class _Stopwatch extends StatelessWidget {
  const _Stopwatch({required this.progress, required this.color});

  final QuantProgress progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final solid = progress.solidColor(color);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.reachedGoal && !progress.exceededGoal
            ? 1.0
            : progress.fraction),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => SizedBox(
          width: 132,
          height: 152,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: StopwatchPainter(fill: t, color: solid),
                ),
              ),
              if (progress.reachedGoal)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CheckSeal(color: solid),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookLine extends StatelessWidget {
  const _BookLine({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final book = habit.book;
    final color = habit.color.shownIn(context);
    final page = context.l10n.book_page(
      habit.amountText(book.page),
      habit.amountText(book.pages),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.bookOpen, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              book.finished > 0
                  ? '$page · ${context.l10n.book_reads(book.finished)}'
                  : page,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
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
    final solid = progress.solidColor(color);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: 0,
          end: reached && !progress.exceededGoal ? 1.0 : progress.fraction,
        ),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => SizedBox.square(
          dimension: 138,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: DialPainter(fill: t, color: solid),
                ),
              ),
              if (reached)
                CheckSeal(color: solid)
              else
                Text(
                  '${(t * 100).round()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Color.lerp(solid, Colors.black, 0.25),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
