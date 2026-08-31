import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_check.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_month.dart';
import 'package:streak/core/express/express_streak_row.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/express/express_wave.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/core/widgets/scrolling_text.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/amount_actions.dart';
import 'package:streak/features/habits/data/quant_progress.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/frequency_chip.dart';
import 'package:streak/features/habits/widgets/habit_checklist.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class ExpressHabitCard extends StatelessWidget {
  const ExpressHabitCard({
    super.key,
    required this.habit,
    required this.onOpen,
    required this.onToggleToday,
    this.onToggleDay,
    this.onLongPress,
    this.mode = HeatmapMode.month,
    this.radius,
  });

  final Habit habit;
  final VoidCallback onOpen;
  final VoidCallback onToggleToday;
  final void Function(DateTime date)? onToggleDay;
  final VoidCallback? onLongPress;
  final HeatmapMode mode;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final settings = context.watch<SettingsController>();
    final today = AppClock.now();
    final done = habit.isCompletedOn(today);
    final quantitative = habit.kind == HabitKind.quantitative;
    final corners = radius ?? BorderRadius.circular(Express.groupEdge);
    final compact = settings.compactCards;
    final cover = CoverImage.exists(habit.coverPath);
    final skin = done
        ? Color.alphaBlend(
            habit.color.withValues(alpha: 0.06),
            expressSurface(context),
          )
        : expressSurface(context);

    return ExpressSquish(
      onTap: onOpen,
      onLongPress: onLongPress,
      haptic: false,
      child: AnimatedContainer(
        duration: Express.normal,
        curve: Express.emphasized,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: skin,
          borderRadius: corners,
          border: expressHairline(context),
        ),
        child: Stack(
          children: [
            if (cover) ...[
              Positioned.fill(child: CoverImage(path: habit.coverPath)),
              Positioned.fill(
                child: ColoredBox(color: skin.withValues(alpha: 0.82)),
              ),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, compact ? 14 : 12),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Glyph(habit: habit, done: done),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScrollingText(
                        habit.name,
                        style: ExpressType.headline.at(
                          17.5,
                          weight: 800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _MetaPills(
                        habit: habit,
                        planning: settings.planningEnabled,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ExpressAction(
                  habit: habit,
                  done: done,
                  onToggleToday: onToggleToday,
                ),
              ],
            ),
            if (quantitative) ...[
              const SizedBox(height: 12),
              _QuantWave(habit: habit),
            ],
            if (habit.hasSubsteps) ...[
              const SizedBox(height: 6),
              HabitStepsPanel(habit: habit),
            ],
            if (settings.cardActivity && !compact && !quantitative) ...[
              const SizedBox(height: 12),
              switch (mode) {
                HeatmapMode.week => ExpressStreakRow(
                    habit: habit,
                    height: 48,
                    onToggle: onToggleDay,
                  ),
                HeatmapMode.month => ExpressMonthStrip(habit: habit),
                _ => HabitHeatmap(
                    habit: habit,
                    mode: HeatmapMode.year,
                    compact: true,
                  ),
              },
            ],
          ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.habit, required this.done});

  final Habit habit;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Express.normal,
      curve: Express.bouncy,
      width: 48,
      height: 48,
      decoration: ShapeDecoration(
        color: habit.color.withValues(alpha: done ? 0.28 : 0.16),
        shape: ExpressBorder(
          shape: done
              ? ExpressShape.cookie.copyWith(rotation: 0.2)
              : ExpressShape.squircle,
        ),
      ),
      child: HabitGlyph(glyph: habit.icon, color: habit.color, size: 23),
    );
  }
}

class _MetaPills extends StatelessWidget {
  const _MetaPills({required this.habit, required this.planning});

  final Habit habit;
  final bool planning;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    final paused = habit.isPausedOn(AppClock.now());

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (paused)
          _Pill(
            icon: LucideIcons.palmtree,
            text: context.l10n.paused,
            tint: context.tokens.info,
          ),
        _Pill(
          icon: LucideIcons.flame,
          text: '${habit.currentStreak}',
          tint: habit.color,
        ),
        if (habit.isPlanned && planning)
          _Pill(
            icon: LucideIcons.clock,
            text: minuteLabel(habit.startMinute),
            tint: muted,
          ),
        if (habitHasExplicitFrequency(habit))
          _Pill(text: habitFrequencyLabel(context, habit), tint: muted),
        if (habit.category.isNotEmpty)
          _Pill(text: context.categoryLabel(habit.category), tint: muted),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.tint, this.icon});

  final String text;
  final Color tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 9 : 7, 3, 9, 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: ExpressType.body.at(12, weight: 700, color: tint),
          ),
        ],
      ),
    );
  }
}

class _QuantWave extends StatelessWidget {
  const _QuantWave({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final count = habit.completions[AppClock.now().dayKey]?.count ?? 0;
    final progress = QuantProgress.of(count: count, target: habit.perDayTarget);
    final tint = progress.activeColor(habit.color);
    final unit = habit.isTimeAmount || habit.unitLabel.isEmpty
        ? ''
        : ' ${habit.unitLabel}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpressWaveBar(
          value: progress.reachedGoal ? 1 : progress.fraction,
          color: tint,
          track: context.colors.surfaceContainerHighest,
          stroke: 7,
          wavelength: 30,
          amplitude: 2.8,
          animate: false,
        ),
        const SizedBox(height: 6),
        Text(
          '${habit.amountText(count)} / '
          '${habit.amountText(habit.perDayTarget)}$unit',
          style: ExpressType.body.at(
            12.5,
            weight: 700,
            color: progress.reachedGoal ? tint : context.tokens.muted,
          ),
        ),
      ],
    );
  }
}

class ExpressAction extends StatelessWidget {
  const ExpressAction({
    super.key,
    required this.habit,
    required this.done,
    required this.onToggleToday,
    this.size = 48,
  });

  final Habit habit;
  final bool done;
  final VoidCallback onToggleToday;
  final double size;

  Future<void> _relapse(BuildContext context, bool relapsed) async {
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
    if (confirmed == true) await controller.logRelapse(habit.id, today);
  }

  Future<void> _addAmount(BuildContext context) async {
    final controller = context.read<HabitsController>();
    final today = AppClock.now();
    if (!await confirmUnscheduledDay(context, habit: habit, date: today)) {
      return;
    }
    await controller.addProgress(habit.id, today, habit.incrementAmount);
  }

  String _label(BuildContext context) => switch (habit.kind) {
    HabitKind.positive =>
      done
          ? context.l10n.a11y_mark_not_done(habit.name)
          : context.l10n.a11y_mark_done(habit.name),
    HabitKind.negative =>
      done
          ? context.l10n.a11y_log_relapse(habit.name)
          : context.l10n.a11y_clear_relapse(habit.name),
    HabitKind.quantitative => context.l10n.a11y_add_amount(habit.name),
  };

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now();
    final (icon, color, onTap) = switch (habit.kind) {
      HabitKind.positive => (LucideIcons.check, habit.color, onToggleToday),
      HabitKind.negative => (
        done ? LucideIcons.shieldCheck : LucideIcons.ban,
        done ? habit.color : context.tokens.danger,
        () => _relapse(context, !done),
      ),
      HabitKind.quantitative => (
        LucideIcons.plus,
        QuantProgress.of(
          count: habit.completions[today.dayKey]?.count ?? 0,
          target: habit.perDayTarget,
        ).activeColor(habit.color),
        () => _addAmount(context),
      ),
    };

    return Semantics(
      button: true,
      label: _label(context),
      excludeSemantics: true,
      child: ExpressCheck(
        done: done,
        color: color,
        icon: icon,
        size: size,
        circle: context.watch<SettingsController>().isCircleCheck,
        onTap: onTap,
        onLongPress: habit.kind == HabitKind.quantitative
            ? () => unawaited(addCustomAmount(context, habit))
            : null,
      ),
    );
  }
}
