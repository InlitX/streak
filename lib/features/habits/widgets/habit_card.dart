import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/quant_progress.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/frequency_chip.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/strength_bar.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/habits/widgets/water_cup.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.onOpen,
    required this.onToggleToday,
    this.onLongPress,
    this.mode = HeatmapMode.month,
  });

  final Habit habit;
  final VoidCallback onOpen;
  final VoidCallback onToggleToday;
  final VoidCallback? onLongPress;
  final HeatmapMode mode;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final doneToday = habit.isCompletedOn(AppClock.now());
    final streak = habit.currentStreak;
    final circleCheck = context.watch<SettingsController>().isCircleCheck;
    final hasCover = CoverImage.exists(habit.coverPath);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onOpen,
          onLongPress: onLongPress == null
              ? null
              : () {
                  HapticFeedback.heavyImpact();
                  onLongPress!();
                },
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (hasCover) ...[
                Positioned.fill(child: CoverImage(path: habit.coverPath)),
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.7)),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: habit.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: HabitGlyph(
                            glyph: habit.icon,
                            color: habit.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (habit.isPausedOn(AppClock.now())) ...[
                                    Icon(
                                      LucideIcons.palmtree,
                                      size: 14,
                                      color: context.tokens.info,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.l10n.paused,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: context.tokens.info,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Icon(
                                    LucideIcons.flame,
                                    size: 14,
                                    color: habit.color,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$streak',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: context.tokens.muted,
                                    ),
                                  ),
                                  if (habit.kind == HabitKind.quantitative) ...[
                                    const SizedBox(width: 8),
                                    _AmountLabel(habit: habit),
                                  ],
                                  if (habitHasExplicitFrequency(habit)) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '·  ${habitFrequencyLabel(context, habit)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: context.tokens.muted,
                                      ),
                                    ),
                                  ],
                                  if (habit.category.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '·  ${context.categoryLabel(habit.category)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.tokens.muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: StrengthBar(
                                      value: habit.strength,
                                      color: habit.color,
                                      track: scheme.surfaceContainerHighest,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${habit.consistency}%',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: context.tokens.muted,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        _ActionButton(
                          habit: habit,
                          doneToday: doneToday,
                          circle: circleCheck,
                          onToggleToday: onToggleToday,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          switchInCurve: const Interval(
                            0.45,
                            1,
                            curve: Curves.easeOutCubic,
                          ),
                          switchOutCurve: const Interval(
                            0.6,
                            1,
                            curve: Curves.easeIn,
                          ),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.05),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              for (final child in previous)
                                Positioned(left: 0, right: 0, child: child),
                              if (current != null) current,
                            ],
                          ),
                          child: HabitHeatmap(
                            key: ValueKey(mode),
                            habit: habit,
                            mode: mode,
                            compact: true,
                            circle: circleCheck,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final count = habit.completions[AppClock.now().dayKey]?.count ?? 0;
    final progress = QuantProgress.of(count: count, target: habit.perDayTarget);
    final unit = habit.unitLabel.isEmpty ? '' : ' ${habit.unitLabel}';
    return Flexible(
      child: Text(
        '·  ${formatAmount(count)}/${formatAmount(habit.perDayTarget)}$unit',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: progress.reachedGoal
              ? progress.solidColor(habit.color)
              : context.tokens.muted,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.habit,
    required this.doneToday,
    required this.circle,
    required this.onToggleToday,
  });

  final Habit habit;
  final bool doneToday;
  final bool circle;
  final VoidCallback onToggleToday;

  Future<void> _handleRelapseTap(BuildContext context, bool relapsed) async {
    final controller = context.read<HabitsController>();
    final today = AppClock.now();
    if (relapsed) {
      HapticFeedback.mediumImpact();
      await controller.clearRelapse(habit.id, today);
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.log_relapse_title,
      message: context.l10n.log_relapse_body(habit.name),
      confirmLabel: context.l10n.log_relapse_confirm,
      icon: LucideIcons.ban,
    );
    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      await controller.logRelapse(habit.id, today);
    }
  }

  String _label(BuildContext context) {
    switch (habit.kind) {
      case HabitKind.positive:
        return doneToday
            ? context.l10n.a11y_mark_not_done(habit.name)
            : context.l10n.a11y_mark_done(habit.name);
      case HabitKind.negative:
        return doneToday
            ? context.l10n.a11y_log_relapse(habit.name)
            : context.l10n.a11y_clear_relapse(habit.name);
      case HabitKind.quantitative:
        return context.l10n.a11y_add_amount(habit.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _label(context),
      child: _button(context),
    );
  }

  Widget _button(BuildContext context) {
    switch (habit.kind) {
      case HabitKind.positive:
        return _TodayButton(
          color: habit.color,
          done: doneToday,
          circle: circle,
          onTap: () {
            HapticFeedback.mediumImpact();
            onToggleToday();
          },
        );
      case HabitKind.negative:
        final relapsed = !doneToday;
        return _RelapseButton(
          color: habit.color,
          relapsed: relapsed,
          circle: circle,
          onTap: () => _handleRelapseTap(context, relapsed),
        );
      case HabitKind.quantitative:
        final today = AppClock.now();
        final count = habit.completions[today.dayKey]?.count ?? 0;
        final ratio = habit.perDayTarget <= 0
            ? 0.0
            : count / habit.perDayTarget;
        Future<void> addProgress() async {
          final controller = context.read<HabitsController>();
          final allowed =
              await confirmUnscheduledDay(context, habit: habit, date: today);
          if (!allowed) return;
          HapticFeedback.mediumImpact();
          await controller.addProgress(habit.id, today, habit.incrementAmount);
        }

        final progress = QuantProgress.of(
          count: count,
          target: habit.perDayTarget,
        );

        switch (habit.quantKind) {
          case QuantKind.water:
            return _WaterButton(
              ratio: ratio.clamp(0.0, 1.0),
              onTap: addProgress,
            );
          case QuantKind.reading:
            return _BookButton(
              color: progress.solidColor(habit.color),
              ratio: ratio.clamp(0.0, 1.0),
              done: doneToday,
              onTap: addProgress,
            );
          case QuantKind.generic:
            return _QuantityButton(
              color: habit.color,
              progress: progress,
              done: doneToday,
              circle: circle,
              onTap: addProgress,
            );
        }
    }
  }
}

class _WaterButton extends StatelessWidget {
  const _WaterButton({required this.ratio, required this.onTap});

  final double ratio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => SizedBox(
              width: 30,
              height: 40,
              child: CustomPaint(painter: WaterCupPainter(fill: t)),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({
    required this.color,
    required this.ratio,
    required this.done,
    required this.onTap,
  });

  final Color color;
  final double ratio;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => SizedBox(
              width: 30,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(30, 38),
                    painter: BookPainter(fill: t, color: color),
                  ),
                  if (done)
                    const Icon(
                      LucideIcons.check,
                      size: 15,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayButton extends StatefulWidget {
  const _TodayButton({
    required this.color,
    required this.done,
    required this.onTap,
    this.circle = false,
  });

  final Color color;
  final bool done;
  final VoidCallback onTap;
  final bool circle;

  @override
  State<_TodayButton> createState() => _TodayButtonState();
}

class _TodayButtonState extends State<_TodayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(_TodayButton old) {
    super.didUpdateWidget(old);
    if (widget.done && !old.done) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pop,
        builder: (context, child) {
          final t = _pop.value;
          final scale = 1 + 0.18 * (t < 0.5 ? t * 2 : (1 - t) * 2);
          return Transform.scale(scale: scale, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.done
                ? widget.color
                : widget.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(widget.circle ? 22 : 14),
            border: widget.done
                ? null
                : Border.all(
                    color: widget.color.withValues(alpha: 0.5),
                    width: 1.6,
                  ),
          ),
          child: Icon(
            LucideIcons.check,
            size: 22,
            color: widget.done ? Colors.white : widget.color,
          ),
        ),
      ),
    );
  }
}

class _RelapseButton extends StatefulWidget {
  const _RelapseButton({
    required this.color,
    required this.relapsed,
    required this.onTap,
    this.circle = false,
  });

  final Color color;
  final bool relapsed;
  final VoidCallback onTap;
  final bool circle;

  @override
  State<_RelapseButton> createState() => _RelapseButtonState();
}

class _RelapseButtonState extends State<_RelapseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(_RelapseButton old) {
    super.didUpdateWidget(old);
    if (widget.relapsed && !old.relapsed) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final danger = context.tokens.danger;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          final t = _shake.value;
          final dx = math.sin(t * math.pi * 6) * (1 - t) * 4;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.relapsed
                ? danger
                : widget.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(widget.circle ? 22 : 14),
            border: widget.relapsed
                ? null
                : Border.all(
                    color: widget.color.withValues(alpha: 0.5),
                    width: 1.6,
                  ),
          ),
          child: Icon(
            widget.relapsed ? LucideIcons.x : LucideIcons.shield,
            size: 22,
            color: widget.relapsed ? Colors.white : widget.color,
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatefulWidget {
  const _QuantityButton({
    required this.color,
    required this.progress,
    required this.done,
    required this.onTap,
    this.circle = false,
  });

  final Color color;
  final QuantProgress progress;
  final bool done;
  final VoidCallback onTap;
  final bool circle;

  @override
  State<_QuantityButton> createState() => _QuantityButtonState();
}

class _QuantityButtonState extends State<_QuantityButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void didUpdateWidget(_QuantityButton old) {
    super.didUpdateWidget(old);
    if (widget.progress.laps != old.progress.laps ||
        widget.progress.fraction != old.progress.fraction) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    final reached = progress.reachedGoal;
    final reachedColor = progress.reachedColor(widget.color);
    final activeColor = progress.activeColor(widget.color);
    final track = reached ? reachedColor : widget.color.withValues(alpha: 0.14);
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pop,
        builder: (context, child) {
          final t = _pop.value;
          final scale = 1 + 0.18 * (t < 0.5 ? t * 2 : (1 - t) * 2);
          return Transform.scale(scale: scale, child: child);
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.fraction),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: t,
                    strokeWidth: 3,
                    backgroundColor: track,
                    valueColor: AlwaysStoppedAnimation(activeColor),
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: widget.done
                      ? reachedColor
                      : widget.color.withValues(alpha: 0.14),
                  shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: widget.circle ? null : BorderRadius.circular(9),
                ),
                child: Icon(
                  widget.done ? LucideIcons.check : LucideIcons.plus,
                  size: 15,
                  color: widget.done ? Colors.white : widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
