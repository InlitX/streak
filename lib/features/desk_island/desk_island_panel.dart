import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/desk_island/desk_island_card.dart';
import 'package:streak/features/desk_island/desk_island_host.dart';
import 'package:streak/features/desk_island/desk_island_kit.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/focus/widgets/timer_clocks.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_groups.dart';
import 'package:streak/features/todos/pages/todos_page.dart';
import 'package:streak/features/todos/state/todos_controller.dart';

class IslandPanel extends StatelessWidget {
  const IslandPanel({
    super.key,
    required this.tab,
    required this.accent,
    required this.locked,
    required this.onTab,
    required this.onTyping,
    required this.onLeave,
  });

  final IslandTab tab;
  final Color accent;
  final bool locked;
  final ValueChanged<IslandTab> onTab;
  final ValueChanged<bool> onTyping;
  final VoidCallback onLeave;

  void _openApp(BuildContext context, IslandTab shown) {
    final focusing =
        shown == IslandTab.focus && context.read<FocusController>().isActive;
    if (focusing && !AppNavigator.isShowing(FocusPage.routeName)) {
      openInApp(const FocusPage());
    } else {
      DeskIslandHost.showApp();
    }
    onLeave();
  }

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return _Locked(onOpen: () => _openApp(context, IslandTab.today));
    }
    final settings = context.watch<SettingsController>();
    final l10n = context.l10n;
    final tabs = [
      (IslandTab.today, LucideIcons.listChecks, l10n.today),
      if (settings.focusEnabled) (IslandTab.focus, LucideIcons.timer, l10n.focus),
      if (settings.todosEnabled) (IslandTab.tasks, LucideIcons.squareCheckBig, l10n.todos),
    ];
    final shown = tabs.any((t) => t.$1 == tab) ? tab : IslandTab.today;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String date;
    try {
      date = DateFormat('EEE d MMM', locale).format(DateTime.now());
    } catch (_) {
      date = DateFormat('EEE d MMM').format(DateTime.now());
    }

    final Widget body = switch (shown) {
      IslandTab.today => _TodayTab(accent: accent, onLeave: onLeave),
      IslandTab.focus => _FocusTab(accent: accent, onLeave: onLeave),
      IslandTab.tasks => _TasksTab(accent: accent, onTyping: onTyping, onLeave: onLeave),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                for (final (id, icon, label) in tabs) ...[
                  _TabChip(
                    icon: icon,
                    label: label,
                    selected: id == shown,
                    onTap: () => onTab(id),
                  ),
                  const SizedBox(width: 4),
                ],
                const Spacer(),
                Text(
                  toBeginningOfSentenceCase(date),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: IslandKit.muted,
                  ),
                ),
                const SizedBox(width: 6),
                IslandIconButton(
                  icon: LucideIcons.appWindow,
                  tooltip: l10n.desk_island_open,
                  onTap: () => _openApp(context, shown),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(shown), child: body),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? '' : label,
      waitDuration: const Duration(milliseconds: 500),
      child: IslandHover(
        onTap: onTap,
        builder: (context, hover) => AnimatedContainer(
          duration: Express.normal,
          curve: Express.bouncy,
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(
              alpha: selected ? 0.12 : hover ? 0.07 : 0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: Express.normal,
                curve: Express.bouncy,
                child: Icon(icon, size: 17, color: selected ? Colors.white : IslandKit.muted),
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: Express.normal,
                  curve: Express.emphasized,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 7),
                          child: Text(
                            label,
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.lock, size: 30, color: IslandKit.muted),
          const SizedBox(height: 14),
          Text(
            context.l10n.app_lock_title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          IslandButton(
            label: context.l10n.app_lock_unlock,
            primary: true,
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

void _startFocus(BuildContext context, Habit? habit) {
  final focus = context.read<FocusController>();
  if (focus.isActive) return;
  if (habit == null) {
    final settings = context.read<SettingsController>();
    focus.start(
      habitId: '',
      targetMinutes: settings.focusMinutes,
      breakMinutes: settings.focusBreakMinutes,
    );
    return;
  }
  focus.start(
    habitId: habit.id,
    targetMinutes: habit.focusMinutes,
    breakMinutes: habit.focusBreakMinutes,
  );
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.accent, required this.onLeave});

  final Color accent;
  final VoidCallback onLeave;

  Future<void> _act(BuildContext context, Habit habit) async {
    final now = AppClock.now();
    if (habit.kind == HabitKind.negative || habit.isScale) return _open(habit);
    if (habit.blocksManualCheck(now)) {
      final focus = context.read<FocusController>();
      if (!context.read<SettingsController>().focusEnabled || focus.isActive) {
        return _open(habit);
      }
      _startFocus(context, habit);
      return;
    }
    await context.read<HabitsController>().toggle(habit.id, now);
  }

  void _open(Habit habit) {
    openInApp(HabitDetailsPage(habitId: habit.id));
    onLeave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = IslandToday.of(context.watch<HabitsController>());
    final percent = (today.ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: IslandKit.tile,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              IslandRing(
                value: today.ratio,
                color: today.perfect ? IslandKit.rest : accent,
                size: 46,
                stroke: 4.5,
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFeatures: IslandKit.figures,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      today.perfect
                          ? l10n.all_done_today
                          : l10n.x_of_y_completed('${today.done}', '${today.total}'),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(LucideIcons.flame, size: 13, color: IslandKit.fire),
                        const SizedBox(width: 5),
                        Text(
                          '${l10n.best_streak}: ${today.best}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: IslandKit.muted,
                            fontFeatures: IslandKit.figures,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _WeekStrip(accent: accent),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: today.due.isEmpty
              ? Center(
                  child: Text(
                    l10n.no_habits_yet,
                    style: const TextStyle(fontSize: 13.5, color: IslandKit.muted),
                  ),
                )
              : IslandFade(
                  child: GridView.builder(
                    primary: true,
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 58,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: today.due.length,
                    itemBuilder: (context, i) {
                      final habit = today.due[i];
                      return IslandEnter(
                        index: i,
                        child: _HabitTile(
                          habit: habit,
                          onTap: () => _act(context, habit),
                          onOpen: () => _open(habit),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitsController>().habits.where((h) => !h.tracking);
    final today = AppClock.today();
    final locale = Localizations.localeOf(context).toLanguageTag();
    String letter(DateTime day) {
      try {
        return DateFormat.E(locale).format(day).characters.first.toUpperCase();
      } catch (_) {
        return DateFormat.E().format(day).characters.first.toUpperCase();
      }
    }

    double ratio(DateTime day) {
      final due = habits
          .where((h) =>
              !h.isPausedOn(day) &&
              h.isScheduledOn(day) &&
              !day.isBefore(h.createdAt.atMidnight))
          .toList();
      if (due.isEmpty) return 0;
      final done = due.where((h) => h.isCompletedOn(day) || h.isCoveredOn(day)).length;
      return done / due.length;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var back = 6; back >= 0; back--) ...[
          Builder(
            builder: (context) {
              final day = today.addDays(-back);
              final value = ratio(day);
              final isToday = back == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 9,
                      height: 30,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            heightFactor: value == 0 ? 0 : 0.2 + 0.8 * value,
                            widthFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: value >= 1
                                    ? IslandKit.rest
                                    : accent.withValues(alpha: 0.55 + 0.45 * value),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      letter(day),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isToday ? Colors.white : IslandKit.faint,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.habit, required this.onTap, required this.onOpen});

  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final now = AppClock.now();
    final color = habit.color.shownIn(context);
    final done = habit.isCompletedOn(now) || habit.isCoveredOn(now);
    final blocked = !done && habit.blocksManualCheck(now);
    final negative = habit.kind == HabitKind.negative;
    final String? amount = habit.kind == HabitKind.quantitative && habit.hasGoal
        ? context.l10n.day_amount(
            habit.amountText(habit.completions[now.dayKey]?.count ?? 0),
            habit.amountText(habit.effectiveTarget),
          )
        : null;

    final Widget mark;
    if (negative) {
      mark = const Icon(LucideIcons.arrowUpRight, size: 15, color: IslandKit.muted);
    } else if (blocked) {
      mark = Icon(LucideIcons.play, size: 13, color: color);
    } else if (done) {
      mark = const Icon(LucideIcons.check, size: 15, color: Colors.black);
    } else {
      mark = const SizedBox.shrink();
    }

    return GestureDetector(
      onSecondaryTap: onOpen,
      child: IslandHover(
        onTap: onTap,
        builder: (context, hover) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: islandTile(hover),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.17),
                ),
                child: Center(
                  child: HabitGlyph(glyph: habit.icon, size: 18, color: color),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: done ? IslandKit.muted : Colors.white,
                      ),
                    ),
                    if (amount != null || habit.currentStreak > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (amount != null)
                            Flexible(
                              child: Text(
                                amount,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: IslandKit.muted,
                                  fontFeatures: IslandKit.figures,
                                ),
                              ),
                            )
                          else ...[
                            const Icon(LucideIcons.flame, size: 11, color: IslandKit.fire),
                            const SizedBox(width: 3),
                            Text(
                              '${habit.currentStreak}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: IslandKit.muted,
                                fontFeatures: IslandKit.figures,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done && !negative ? color : Colors.transparent,
                  border: done && !negative
                      ? null
                      : Border.all(
                          color: hover ? Colors.white38 : Colors.white24,
                          width: 1.6,
                        ),
                ),
                child: Center(child: mark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusTab extends StatefulWidget {
  const _FocusTab({required this.accent, required this.onLeave});

  final Color accent;
  final VoidCallback onLeave;

  @override
  State<_FocusTab> createState() => _FocusTabState();
}

class _FocusTabState extends State<_FocusTab> {
  bool _ending = false;

  int _todaySeconds(FocusController focus) {
    final key = AppClock.today().dayKey;
    var total = 0;
    for (final session in focus.sessions) {
      if (session.countedOn.dayKey == key) total += session.seconds;
    }
    if (focus.isActive && !focus.isBreak) total += focus.elapsedSeconds;
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    final l10n = context.l10n;
    final today = _todaySeconds(focus);
    if (!focus.isActive) return _idle(context, today);

    final settings = context.watch<SettingsController>();
    final style = ClockStyle.values[
        settings.focusClockStyle.clamp(0, ClockStyle.values.length - 1)];
    final habit = focus.habitId.isEmpty
        ? null
        : context.watch<HabitsController>().byId(focus.habitId);
    final color = focus.isBreak ? IslandKit.rest : widget.accent;
    final waits = focusWaits(focus);
    final title = focus.isBreak
        ? l10n.focus_break
        : habit?.name ?? (focus.label.isNotEmpty ? focus.label : l10n.focus_free_session);
    final state = waits
        ? (focus.isBreak ? l10n.focus_break_over : l10n.focus_done_title)
        : !focus.isRunning
        ? l10n.focus_paused
        : focus.isPomodoro
        ? l10n.focus_round(focus.round)
        : l10n.focus;
    final until = focus.isRunning && !focus.isFlow && !waits
        ? MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(
              DateTime.now().add(Duration(seconds: focus.remainingSeconds)),
            ),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          )
        : null;
    final details = [
      if (!focus.isFlow) '${focus.targetMinutes} ${l10n.unit_min_short}',
      if (until != null) '→ $until',
      if (today >= 60) '${l10n.today} ${formatHoursShort(today)}',
    ].join('  ·  ');

    final IconData mainIcon;
    final String mainTip;
    final VoidCallback mainTap;
    if (focus.isAwaiting || focus.switchIn > 0) {
      mainIcon = LucideIcons.play;
      mainTip = l10n.focus_continue;
      mainTap = focus.continueNow;
    } else if (focus.isFinished) {
      mainIcon = LucideIcons.check;
      mainTip = l10n.focus_end;
      mainTap = () => endFocusFromIsland(focus);
    } else {
      mainIcon = focus.isRunning ? LucideIcons.pause : LucideIcons.play;
      mainTip = focus.isRunning ? l10n.focus_pause : l10n.focus_resume;
      mainTap = focus.isRunning ? focus.pause : focus.resume;
    }

    final Widget side = focus.isBreak && !waits
        ? IslandButton(
            label: l10n.focus_skip_break,
            icon: LucideIcons.skipForward,
            expand: true,
            onTap: focus.skipBreak,
          )
        : IslandButton(
            label: '+1 ${l10n.unit_min_short}',
            expand: true,
            onTap: focus.isFlow || focus.isBreak ? null : focus.addMinute,
          );

    final controls = Column(
      key: const ValueKey('controls'),
      children: [
        IslandButton(
          label: mainTip,
          icon: mainIcon,
          primary: true,
          expand: true,
          tall: true,
          onTap: mainTap,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: side),
            if (!focus.isFinished) ...[
              const SizedBox(width: 8),
              Expanded(
                child: IslandButton(
                  label: l10n.focus_end,
                  color: IslandKit.stop,
                  expand: true,
                  onTap: () {
                    if (focus.isPomodoro && focus.isBreak) {
                      endFocusFromIsland(focus);
                      return;
                    }
                    setState(() => _ending = true);
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );

    final confirm = Column(
      key: const ValueKey('confirm'),
      children: [
        IslandButton(
          label: l10n.focus_end,
          icon: LucideIcons.square,
          color: IslandKit.stop,
          primary: true,
          expand: true,
          tall: true,
          onTap: () {
            setState(() => _ending = false);
            endFocusFromIsland(focus);
          },
        ),
        const SizedBox(height: 8),
        IslandButton(
          label: l10n.focus_end_keep,
          expand: true,
          onTap: () => setState(() => _ending = false),
        ),
      ],
    );

    return Row(
      children: [
        Tooltip(
          message: l10n.focus_style,
          waitDuration: const Duration(milliseconds: 600),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => settings.setFocusClockStyle(
                (style.index + 1) % ClockStyle.values.length,
              ),
              child: SizedBox(
                width: 156,
                height: 146,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(style),
                      child: switch (style) {
                        ClockStyle.ring => _Clock(
                            ring: style == ClockStyle.ring,
                            seconds: focus.switchIn > 0
                                ? focus.switchIn
                                : focus.displaySeconds,
                            progress: focus.progress,
                            color: color,
                            label: state,
                            dim: !focus.isRunning && !waits,
                          ),
                        _ => FocusClock(
                            style: style,
                            seconds: focus.switchIn > 0
                                ? focus.switchIn
                                : focus.displaySeconds,
                            progress: focus.progress,
                            color: color,
                            label: state,
                            size: 152,
                            row: true,
                            paused: !focus.isRunning && !waits,
                            resting: focus.isBreak,
                          ),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (habit != null && !focus.isBreak) ...[
                    HabitGlyph(
                      glyph: habit.icon,
                      size: 16,
                      color: habit.color.shownIn(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                details,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: IslandKit.muted,
                  fontFeatures: IslandKit.figures,
                ),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.96, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: _ending ? confirm : controls,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _idle(BuildContext context, int today) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsController>();
    final habits = islandFocusHabits(context.watch<HabitsController>());
    final accent = widget.accent;
    final onAccent = ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final pause = settings.focusBreakMinutes > 0 ? ' + ${settings.focusBreakMinutes}' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IslandHover(
          onTap: () => _startFocus(context, null),
          builder: (context, hover) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: hover ? 0.45 : 0.25)),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: hover ? 0.30 : 0.22),
                  accent.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                  child: Icon(LucideIcons.play, size: 18, color: onAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.focus_start,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        today >= 60
                            ? '${settings.focusMinutes}$pause ${l10n.unit_min_short}'
                                  '  ·  ${l10n.today} ${formatHoursShort(today)}'
                            : '${settings.focusMinutes}$pause ${l10n.unit_min_short}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: IslandKit.muted,
                          fontFeatures: IslandKit.figures,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 160),
                  offset: Offset(hover ? 0.15 : 0, 0),
                  child: const Icon(LucideIcons.chevronRight, size: 18, color: IslandKit.muted),
                ),
              ],
            ),
          ),
        ),
        if (habits.isNotEmpty) ...[
          const SizedBox(height: 12),
          Expanded(
            child: IslandFade(
              child: GridView.builder(
                primary: true,
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 58,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: habits.length,
                itemBuilder: (context, i) {
                  final habit = habits[i];
                  final color = habit.color.shownIn(context);
                  final minutes = habit.focusMinutes;
                  return IslandEnter(
                    index: i + 1,
                    child: IslandHover(
                      onTap: () => _startFocus(context, habit),
                      builder: (context, hover) => AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: islandTile(hover),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.17),
                              ),
                              child: Center(
                                child: HabitGlyph(glyph: habit.icon, size: 18, color: color),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    habit.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    minutes > 0 ? '$minutes ${l10n.unit_min_short}' : l10n.focus,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: IslandKit.muted,
                                      fontFeatures: IslandKit.figures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: hover ? 0.9 : 0.14),
                              ),
                              child: Icon(
                                LucideIcons.play,
                                size: 13,
                                color: hover ? Colors.black : color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock({
    required this.ring,
    required this.seconds,
    required this.progress,
    required this.color,
    required this.label,
    required this.dim,
  });

  final bool ring;
  final int seconds;
  final double progress;
  final Color color;
  final String label;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          FocusClock.clockText(seconds),
          style: TextStyle(
            fontSize: ring ? 30 : 44,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -0.8,
            color: dim ? IslandKit.muted : Colors.white,
            fontFeatures: IslandKit.figures,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
    if (!ring) return text;
    return SizedBox.square(
      dimension: 140,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => CustomPaint(
          painter: _ClockRing(value: value, color: color),
          child: child,
        ),
        child: Center(child: text),
      ),
    );
  }
}

class _ClockRing extends CustomPainter {
  const _ClockRing({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    if (value <= 0.002) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ClockRing old) => old.value != value || old.color != color;
}

class _TasksTab extends StatefulWidget {
  const _TasksTab({
    required this.accent,
    required this.onTyping,
    required this.onLeave,
  });

  final Color accent;
  final ValueChanged<bool> onTyping;
  final VoidCallback onLeave;

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  final _text = TextEditingController();
  final _node = FocusNode();
  final _clock = TextEditingController();
  final _clockNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _node.addListener(_focusChanged);
    _clockNode.addListener(_clockFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_focusChanged);
    _clockNode.removeListener(_clockFocus);
    if (_node.hasFocus || _clockNode.hasFocus) widget.onTyping(false);
    _node.dispose();
    _clockNode.dispose();
    _text.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _focusChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onTyping(_node.hasFocus || _clockNode.hasFocus);
    });
  }

  void _clockFocus() {
    _focusChanged();
    if (_clockNode.hasFocus) {
      final minutes = _minutes;
      _clock.text = minutes == null
          ? ''
          : '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
              '${(minutes % 60).toString().padLeft(2, '0')}';
      _clock.selection = TextSelection(baseOffset: 0, extentOffset: _clock.text.length);
      return;
    }
    _readClock();
  }

  void _readClock() {
    final typed = parseClock(_clock.text);
    setState(() {
      if (typed != null) {
        _minutes = typed;
        if (_day < 0) _day = 0;
      } else if (_clock.text.trim().isEmpty) {
        _minutes = null;
      }
    });
    _showClock();
  }

  void _showClock() {
    if (_clockNode.hasFocus) return;
    final minutes = _minutes;
    _clock.text = minutes == null
        ? ''
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          );
  }

  int _day = 0;
  int? _minutes;

  Future<void> _add() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    _text.clear();
    final dated = _day >= 0 || _minutes != null;
    final minutes = _minutes;
    setState(() => _minutes = null);
    _showClock();
    await context.read<TodosController>().create(
      text: text,
      date: dated ? AppClock.today().addDays(_day < 0 ? 0 : _day).dayKey : '',
      minutes: minutes,
    );
  }

  void _shiftDay(int step) {
    setState(() {
      _day = (_day + step).clamp(-1, 60);
      if (_day < 0) _minutes = null;
    });
    _showClock();
  }

  void _shiftTime(int step) {
    setState(() {
      final current = _minutes;
      if (current == null) {
        final now = TimeOfDay.now();
        final next = ((now.hour * 60 + now.minute) ~/ 30 + 1) * 30;
        _minutes = next % (24 * 60);
        if (_day < 0) _day = next >= 24 * 60 ? 1 : 0;
        return;
      }
      _minutes = (current ~/ 15 * 15 + step) % (24 * 60);
      if (_day < 0) _day = 0;
    });
    _showClock();
  }

  String _dayLabel(AppLocalizations l10n) {
    if (_day < 0) return l10n.todo_no_date;
    if (_day == 0) return l10n.today;
    if (_day == 1) return l10n.tomorrow;
    final day = AppClock.today().addDays(_day);
    final locale = Localizations.localeOf(context).toLanguageTag();
    try {
      return toBeginningOfSentenceCase(DateFormat('EEE d', locale).format(day));
    } catch (_) {
      return toBeginningOfSentenceCase(DateFormat('EEE d').format(day));
    }
  }

  String _group(AppLocalizations l10n, TodoGroup group) => switch (group) {
        TodoGroup.pinned => l10n.todo_pinned,
        TodoGroup.overdue => l10n.todo_overdue,
        TodoGroup.today => l10n.today,
        TodoGroup.tomorrow => l10n.tomorrow,
        TodoGroup.upcoming => l10n.todo_upcoming,
        TodoGroup.someday => l10n.todo_someday,
      };

  void _open(Todo todo) {
    openInApp(TodosPage(openId: todo.id));
    widget.onLeave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final todos = context.watch<TodosController>();
    final sections = todos.sections;
    final rows = <Widget>[];
    for (final section in sections) {
      rows.add(
        Padding(
          padding: EdgeInsets.fromLTRB(4, rows.isEmpty ? 0 : 12, 4, 6),
          child: Text(
            _group(l10n, section.group),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: section.group == TodoGroup.overdue ? IslandKit.stop : IslandKit.faint,
            ),
          ),
        ),
      );
      for (final todo in section.todos) {
        rows.add(
          _TodoRow(
            todo: todo,
            accent: widget.accent,
            onCheck: () => todo.blocksManualCheck
                ? _open(todo)
                : context.read<TodosController>().toggle(todo.id),
            onOpen: () => _open(todo),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _text,
          focusNode: _node,
          onSubmitted: (_) => _add(),
          onEditingComplete: () {},
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          cursorColor: widget.accent,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: IslandKit.tile,
            hintText: l10n.todo_hint,
            hintStyle: const TextStyle(fontSize: 14, color: IslandKit.faint),
            prefixIcon: const Icon(LucideIcons.plus, size: 17, color: IslandKit.muted),
            contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: widget.accent.withValues(alpha: 0.6)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: Row(
            children: [
              Expanded(
                child: _Stepper(
                  icon: LucideIcons.calendarDays,
                  label: _dayLabel(l10n),
                  active: _day >= 0,
                  onPrev: _day < 0 ? null : () => _shiftDay(-1),
                  onNext: () => _shiftDay(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stepper(
                  icon: LucideIcons.clock,
                  label: l10n.todo_time,
                  active: _minutes != null,
                  onPrev: () => _shiftTime(-15),
                  onNext: () => _shiftTime(15),
                  onClear: _minutes == null
                      ? null
                      : () {
                          setState(() => _minutes = null);
                          _showClock();
                        },
                  field: TextField(
                    controller: _clock,
                    focusNode: _clockNode,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _clockNode.unfocus(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9:.hH ]')),
                      LengthLimitingTextInputFormatter(5),
                    ],
                    cursorColor: widget.accent,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _minutes == null ? IslandKit.muted : Colors.white,
                      fontFeatures: IslandKit.figures,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: l10n.todo_time,
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: IslandKit.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.todo_empty_title,
                    style: const TextStyle(fontSize: 13.5, color: IslandKit.muted),
                  ),
                )
              : IslandFade(
                  child: ListView(
                    primary: true,
                    padding: EdgeInsets.zero,
                    children: [
                      for (var i = 0; i < rows.length; i++)
                        IslandEnter(index: i, child: rows[i]),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPrev,
    required this.onNext,
    this.onClear,
    this.field,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onPrev;
  final VoidCallback onNext;
  final VoidCallback? onClear;
  final Widget? field;

  void _wheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (event.scrollDelta.dy < 0) {
      onNext();
    } else {
      onPrev?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = active ? Colors.white : IslandKit.muted;
    Widget arrow(IconData glyph, VoidCallback? tap) => IslandHover(
          onTap: tap,
          builder: (context, hover) => AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: hover && tap != null ? 0.10 : 0),
            ),
            child: Icon(
              glyph,
              size: 15,
              color: tap == null ? IslandKit.faint : Colors.white70,
            ),
          ),
        );

    return Listener(
      onPointerSignal: _wheel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: IslandKit.tile,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: Colors.white.withValues(alpha: active ? 0.10 : 0.04),
          ),
        ),
        child: Row(
          children: [
            arrow(LucideIcons.chevronLeft, onPrev),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 13, color: ink),
                  const SizedBox(width: 6),
                  if (field != null)
                    SizedBox(width: 72, child: field)
                  else
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          label,
                          key: ValueKey(label),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: ink,
                            fontFeatures: IslandKit.figures,
                          ),
                        ),
                      ),
                    ),
                  if (onClear != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onClear,
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Icon(LucideIcons.x, size: 12, color: IslandKit.muted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            arrow(LucideIcons.chevronRight, onNext),
          ],
        ),
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.todo,
    required this.accent,
    required this.onCheck,
    required this.onOpen,
  });

  final Todo todo;
  final Color accent;
  final VoidCallback onCheck;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final time = todo.time;
    return IslandHover(
      onTap: onOpen,
      builder: (context, hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: hover ? IslandKit.tile : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onCheck,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: todo.priority == TodoPriority.none
                          ? Colors.white38
                          : accent,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                todo.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, color: Colors.white),
              ),
            ),
            if (time != null) ...[
              const SizedBox(width: 8),
              Text(
                MaterialLocalizations.of(context).formatTimeOfDay(
                  time,
                  alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: IslandKit.muted,
                  fontFeatures: IslandKit.figures,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
