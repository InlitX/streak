import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/clock_extensions.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/pages/focus_stats_page.dart';
import 'package:streak/features/focus/widgets/focus_setup_parts.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/check_history.dart';
import 'package:streak/features/habits/widgets/frequency_chip.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/saved_money.dart';
import 'package:streak/features/habits/widgets/vacation_sheet.dart';
import 'package:streak/core/extensions/color_extensions.dart';

class MinimalDetailHeader extends StatelessWidget {
  const MinimalDetailHeader({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final meta = [
      habitFrequencyLabel(context, habit),
      if (habit.isPlanned) context.clockAt(habit.startMinute),
      if (habit.category.isNotEmpty) context.categoryLabel(habit.category),
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: HabitGlyph(glyph: habit.icon, color: habit.color.shownIn(context), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MinimalType.display(
                    28,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MinimalType.label(color: context.tokens.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MinimalStreakTiles extends StatelessWidget {
  const MinimalStreakTiles({super.key, required this.habit, required this.mode});

  final Habit habit;
  final HeatmapMode mode;

  String _format(BuildContext context, int value) => switch (habit.interval) {
    HabitInterval.weekly => context.l10n.count_weeks(value),
    HabitInterval.monthly => context.l10n.count_months(value),
    _ => context.l10n.count_days(value),
  };

  @override
  Widget build(BuildContext context) {
    final negative = habit.kind == HabitKind.negative;
    final (period, count) = periodTotal(context, habit, mode);
    return MinimalGrid(
      children: [
        if (habit.tracking)
          MinimalTile(
            icon: LucideIcons.history,
            label: context.l10n.last_check,
            value: lastCheckLabel(context, habit, withTime: false),
          )
        else ...[
        MinimalTile(
          icon: LucideIcons.flame,
          label: context.l10n.current_streak,
          value: _format(context, habit.currentStreak),
        ),
        MinimalTile(
          icon: LucideIcons.trophy,
          label: context.l10n.best_streak,
          value: _format(context, habit.longestStreak),
        ),
        ],
        MinimalTile(
          icon: negative ? LucideIcons.triangleAlert : LucideIcons.check,
          label: period,
          value: '$count',
        ),
        if (!habit.tracking)
          MinimalTile(
            icon: LucideIcons.target,
            label: context.l10n.completion_rate_short,
            value: '${habit.consistency}%',
          ),
      ],
    );
  }
}

class MinimalMoneyTiles extends StatelessWidget {
  const MinimalMoneyTiles({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return MinimalGrid(
      children: [
        MinimalTile(
          icon: LucideIcons.piggyBank,
          label: context.l10n.money_saved,
          value: habitMoneySaved(context, habit),
        ),
        MinimalTile(
          icon: LucideIcons.shieldCheck,
          label: context.l10n.clean_days,
          value: '${habit.cleanDays}',
        ),
      ],
    );
  }
}

class MinimalFocusRow extends StatelessWidget {
  const MinimalFocusRow({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    context.select<FocusController, int>((f) => f.revision);
    final focus = context.read<FocusController>();
    final seconds = focus.secondsForHabit(habit.id);
    final today = focus.secondsForHabitOnDay(habit.id, AppClock.now());

    return MinimalList(
      children: [
        MinimalRow(
          label: context.l10n.focus_total,
          caption: today == 0
              ? null
              : '${context.l10n.today}  ${formatHoursShort(today)}',
          value: seconds == 0 ? null : formatHoursShort(seconds),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: FocusQuickTimers(habit: habit),
              ),
              const SizedBox(width: 8),
              _PlayButton(habit: habit, active: focus.isActive),
            ],
          ),
          onTap: () =>
              AppNavigator.push(FocusStatsPage(habitId: habit.id)),
          last: true,
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.habit, required this.active});

  final Habit habit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.focus_start,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          unawaited(
            AppNavigator.push(
              active
                  ? const FocusPage()
                  : FocusPage(
                      startHabitId: habit.id,
                      startMinutes: habit.focusMinutes,
                      breakMinutes: habit.focusBreakMinutes,
                    ),
              fade: true,
              name: FocusPage.routeName,
            ),
          );
        },
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: minimalRaised(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(LucideIcons.play, size: 15, color: habit.color.shownIn(context)),
        ),
      ),
    );
  }
}

class MinimalVacationRow extends StatelessWidget {
  const MinimalVacationRow({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return MinimalList(
      children: [
        MinimalRow(
          label: context.l10n.vacation_mode,
          value: vacationSummary(context, habit),
          tint: habit.isOnVacation
              ? context.tokens.info
              : context.tokens.muted,
          onTap: () => showVacationSheet(context, habit: habit),
          last: true,
        ),
      ],
    );
  }
}
