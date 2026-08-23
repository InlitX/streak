import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/pages/focus_stats_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/frequency_chip.dart';
import 'package:streak/features/habits/widgets/saved_money.dart';
import 'package:streak/features/habits/widgets/vacation_sheet.dart';

class MinimalDetailHeader extends StatelessWidget {
  const MinimalDetailHeader({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final meta = [
      habitFrequencyLabel(context, habit),
      if (habit.isPlanned) minuteLabel(habit.startMinute),
      if (habit.category.isNotEmpty) context.categoryLabel(habit.category),
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: HabitGlyph(glyph: habit.icon, color: habit.color, size: 24),
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
  const MinimalStreakTiles({super.key, required this.habit});

  final Habit habit;

  String _format(BuildContext context, int value) => switch (habit.interval) {
    HabitInterval.weekly => context.l10n.count_weeks(value),
    HabitInterval.monthly => context.l10n.count_months(value),
    _ => context.l10n.count_days(value),
  };

  @override
  Widget build(BuildContext context) {
    final negative = habit.kind == HabitKind.negative;
    return MinimalGrid(
      children: [
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
        MinimalTile(
          icon: negative ? LucideIcons.triangleAlert : LucideIcons.check,
          label: negative ? context.l10n.relapses : context.l10n.total,
          value: '${habit.totalCompletions}',
        ),
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
    final focus = context.watch<FocusController>();
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
          trailing: _PlayButton(habit: habit, active: focus.isActive),
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
          HapticFeedback.selectionClick();
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
          child: Icon(LucideIcons.play, size: 15, color: habit.color),
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
