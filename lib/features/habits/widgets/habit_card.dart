import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/core/widgets/scrolling_text.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/amount_actions.dart';
import 'package:streak/features/habits/widgets/streak_label.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/frequency_chip.dart';
import 'package:streak/features/habits/widgets/compact_activity_strip.dart';
import 'package:streak/features/habits/widgets/habit_checklist.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/strength_bar.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/habits/widgets/water_cup.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/app/theme/app_theme.dart';
import 'package:streak/core/widgets/glass.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.onOpen,
    required this.onToggleToday,
    this.onToggleDay,
    this.onLongPress,
    this.mode = HeatmapMode.month,
    this.corners,
  });

  final Habit habit;
  final VoidCallback onOpen;
  final VoidCallback onToggleToday;
  final void Function(DateTime date)? onToggleDay;
  final VoidCallback? onLongPress;
  final HeatmapMode mode;
  final BorderRadius? corners;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final doneToday = habit.isCompletedOn(AppClock.now());
    final settings = context.watch<SettingsController>();
    final circleCheck = settings.isCircleCheck;
    final hasCover = CoverImage.exists(habit.coverPath);
    final compact = settings.compactCards;
    final corners = this.corners ?? BorderRadius.circular(24);

    return _HoverRing(
      corners: corners,
      child: Pressable(
      scale: 0.98,
      child: Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: corners,
        side: AppTheme.cardEdge(Theme.of(context).brightness == Brightness.dark),
      ),
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onOpen,
          hoverColor: Colors.transparent,
          onLongPress: onLongPress == null
              ? null
              : () {
                  onLongPress!();
                },
          borderRadius: corners,
          child: Stack(
            children: [
              if (hasCover) ...[
                Positioned.fill(
                  child: CoverImage(
                    path: habit.coverPath,
                    clarity: habit.coverClarity,
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.all(compact ? 11 : 16),
                  child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: compact ? 34 : 46,
                          height: compact ? 34 : 46,
                          decoration: BoxDecoration(
                            color: habit.color.shownIn(context).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(compact ? 11 : 14),
                          ),
                          child: HabitGlyph(
                            glyph: habit.icon,
                            color: habit.color.shownIn(context),
                            size: compact ? 18 : 24,
                          ),
                        ),
                        SizedBox(width: compact ? 11 : 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ScrollingText(
                                habit.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ScrollingLine(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                      habitMarkIcon(habit),
                                      size: 14,
                                      color: habit.color.shownIn(context),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      habitMarkLabel(context, habit, mode),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: context.tokens.muted,
                                      ),
                                    ),
                                    if (habit.isPlanned &&
                                        settings.planningEnabled) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        LucideIcons.clock,
                                        size: 13,
                                        color: context.tokens.muted,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        minuteLabel(habit.startMinute),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: context.tokens.muted,
                                        ),
                                      ),
                                    ],
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
                                      Text(
                                        '·  ${context.categoryLabel(habit.category)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.tokens.muted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!compact && settings.showTodayProgress) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: StrengthBar(
                                        value: habit.strength,
                                        color: habit.color.shownIn(context),
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
                            ],
                          ),
                        ),
                        SizedBox(width: compact ? 10 : 14),
                        if (compact)
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: FittedBox(
                              child: _ActionButton(
                                habit: habit,
                                doneToday: doneToday,
                                circle: circleCheck,
                                onToggleToday: onToggleToday,
                              ),
                            ),
                          )
                        else
                          _ActionButton(
                            habit: habit,
                            doneToday: doneToday,
                            circle: circleCheck,
                            onToggleToday: onToggleToday,
                          ),
                      ],
                    ),
                    if (habit.hasSubsteps) ...[
                      const SizedBox(height: 6),
                      HabitStepsPanel(habit: habit),
                    ],
                    if (settings.cardActivity &&
                        compact &&
                        mode != HeatmapMode.week) ...[
                      const SizedBox(height: 10),
                      CompactActivityStrip(habit: habit, mode: mode),
                    ],
                    if (settings.cardActivity && !compact) ...[
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
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
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
                              onToggle: onToggleDay,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  ),
                ),
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

class _HoverRing extends StatefulWidget {
  const _HoverRing({required this.corners, required this.child});

  final BorderRadius corners;
  final Widget child;

  @override
  State<_HoverRing> createState() => _HoverRingState();
}

class _HoverRingState extends State<_HoverRing> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.corners,
          border: Border.all(
            color: _hover
                ? context.colors.onSurface.withValues(alpha: 0.16)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: widget.child,
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
    final progress = habit.progressFor(count);
    final unit = habit.isTimeAmount || habit.unitLabel.isEmpty
        ? ''
        : ' ${habit.unitLabel}';
    return Text(
      habit.hasGoal
          ? '·  ${habit.amountText(count)}/'
              '${habit.amountText(habit.perDayTarget)}$unit'
          : '·  ${habit.amountText(count)}$unit',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: progress.reachedGoal
            ? progress.solidColor(habit.color.shownIn(context))
            : context.tokens.muted,
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
          color: habit.color.shownIn(context),
          done: doneToday,
          circle: circle,
          onTap: () {
            onToggleToday();
          },
        );
      case HabitKind.negative:
        final relapsed = !doneToday;
        return _RelapseButton(
          color: habit.color.shownIn(context),
          relapsed: relapsed,
          circle: circle,
          onTap: () => _handleRelapseTap(context, relapsed),
        );
      case HabitKind.quantitative:
        final today = AppClock.now();
        final count = habit.completions[today.dayKey]?.count ?? 0;
        final ratio = habit.perDayTarget <= 0
            ? (count > 0 ? 1.0 : 0.0)
            : count / habit.perDayTarget;
        Future<void> addProgress() async {
          final controller = context.read<HabitsController>();
          final allowed =
              await confirmUnscheduledDay(context, habit: habit, date: today);
          if (!allowed) return;
          await controller.addProgress(habit.id, today, habit.incrementAmount);
        }

        final progress = habit.progressFor(count);

        void addCustom() => unawaited(addCustomAmount(context, habit));

        switch (habit.quantKind) {
          case QuantKind.water:
            return _WaterButton(
              ratio: ratio.clamp(0.0, 1.0),
              onTap: addProgress,
              onLongPress: addCustom,
            );
          case QuantKind.reading:
            final color = progress.solidColor(habit.color.shownIn(context));
            return _ArtButton(
              size: const Size(30, 35),
              painter: (t) => BookPainter(fill: t, color: color, ribbon: true),
              color: color,
              ratio: ratio.clamp(0.0, 1.0),
              done: doneToday,
              onTap: addProgress,
              onLongPress: addCustom,
            );
          case QuantKind.time:
            final color = progress.solidColor(habit.color.shownIn(context));
            return _ArtButton(
              size: const Size(32, 37),
              painter: (t) => StopwatchPainter(fill: t, color: color),
              color: color,
              ratio: ratio.clamp(0.0, 1.0),
              done: false,
              onTap: addProgress,
              onLongPress: addCustom,
            );
          case QuantKind.generic when habit.readsSteps:
            final color = progress.solidColor(habit.color.shownIn(context));
            return _ArtButton(
              size: const Size(28, 38),
              painter: (t) => FootPainter(fill: t, color: color),
              color: color,
              ratio: ratio.clamp(0.0, 1.0),
              done: doneToday,
              onTap: addProgress,
              onLongPress: addCustom,
            );
          case QuantKind.generic:
            final color = progress.solidColor(habit.color.shownIn(context));
            return _ArtButton(
              size: const Size(36, 36),
              painter: (t) => DialPainter(fill: t, color: color),
              color: color,
              ratio: ratio.clamp(0.0, 1.0),
              done: false,
              onTap: addProgress,
              onLongPress: addCustom,
            );
        }
    }
  }
}

class _WaterButton extends StatelessWidget {
  const _WaterButton({
    required this.ratio,
    required this.onTap,
    this.onLongPress,
  });

  final double ratio;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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

class _ArtButton extends StatelessWidget {
  const _ArtButton({
    required this.size,
    required this.painter,
    required this.color,
    required this.ratio,
    required this.done,
    required this.onTap,
    this.onLongPress,
  });

  final Size size;
  final CustomPainter Function(double t) painter;
  final Color color;
  final double ratio;
  final bool done;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => SizedBox.fromSize(
              size: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(size: size, painter: painter(t)),
                  if (done)
                    Icon(
                      LucideIcons.check,
                      size: 15,
                      color: color.ink,
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
            color: widget.done
                ? widget.color.ink
                : widget.color.withValues(alpha: 0.3),
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
