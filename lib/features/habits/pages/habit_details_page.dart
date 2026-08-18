import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_stats_page.dart';
import 'package:streak/features/focus/widgets/focus_daily_bars.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/focus/widgets/focus_defaults_sheet.dart';
import 'package:streak/features/focus/widgets/focus_habit_sheet.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/features/habits/pages/journey_page.dart';
import 'package:streak/features/habits/pages/quant_stats_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/habits/widgets/activity_calendar.dart';
import 'package:streak/features/habits/widgets/day_actions_sheet.dart';
import 'package:streak/features/habits/widgets/note_widgets.dart';
import 'package:streak/features/habits/widgets/frequency_chip.dart';
import 'package:streak/features/habits/widgets/habit_checklist.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/minimal_form_fields.dart';
import 'package:streak/features/habits/widgets/quant_daily_bars.dart';
import 'package:streak/features/habits/widgets/quantitative_progress.dart';
import 'package:streak/features/habits/widgets/saved_money.dart';
import 'package:streak/features/habits/widgets/share_card.dart';
import 'package:streak/features/habits/widgets/streak_summary.dart';
import 'package:streak/features/habits/widgets/focus_only_dialog.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class HabitDetailsPage extends StatefulWidget {
  const HabitDetailsPage({super.key, required this.habitId});

  final String habitId;

  @override
  State<HabitDetailsPage> createState() => _HabitDetailsPageState();
}

class _HabitDetailsPageState extends State<HabitDetailsPage> {
  late HeatmapMode _mode;

  @override
  void initState() {
    super.initState();
    final saved = context.read<SettingsController>().heatmapMode;
    _mode = HeatmapMode.values[saved.clamp(0, 2)];
  }

  void _changeMode(HeatmapMode mode) {
    setState(() => _mode = mode);
    context.read<SettingsController>().setHeatmapMode(mode.index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitsController>(
      builder: (context, controller, _) {
        final habit = controller.byId(widget.habitId);
        if (habit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.pop();
          });
          return const SizedBox.shrink();
        }

        Future<void> editAmount(DateTime date) async {
          final allowed =
              await confirmUnscheduledDay(context, habit: habit, date: date);
          if (!allowed || !context.mounted) return;

          final current = habit.completions[date.dayKey]?.count ?? 0;
          final value = await showNumberKeypadDialog(
            context,
            title: DateFormat.yMMMMd(
              Localizations.localeOf(context).toString(),
            ).format(date),
            value: current,
            unit: habit.unitLabel,
            target: habit.perDayTarget,
            decimals: true,
            accent: habit.color,
          );
          if (value != null && value != current) {
            await controller.setProgress(habit.id, date, value);
          }
        }

        Future<void> toggleDay(DateTime date) async {
          if (!await allowManualCheck(context, habit: habit, date: date)) return;
          if (!context.mounted) return;
          final allowed =
              await confirmUnscheduledDay(context, habit: habit, date: date);
          if (!allowed) return;
          await controller.toggle(habit.id, date);
        }

        void toggle(DateTime date) {
          HapticFeedback.selectionClick();
          switch (habit.kind) {
            case HabitKind.positive:
              unawaited(toggleDay(date));
              break;
            case HabitKind.negative:
              final relapsed = habit.completions.containsKey(date.dayKey);
              relapsed
                  ? controller.clearRelapse(habit.id, date)
                  : controller.logRelapse(habit.id, date);
              break;
            case HabitKind.quantitative:
              unawaited(editAmount(date));
              break;
          }
        }

        final settings = context.watch<SettingsController>();
        final minimal = settings.isMinimalStyle;
        final notesOn = settings.notesEnabled;

        void openDay(DateTime date) => showDayActionsSheet(
              context,
              habit: habit,
              date: date,
              notesEnabled: notesOn,
            );

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: minimal ? 52 : null,
            title: minimal
                ? null
                : Row(
              children: [
                HabitGlyph(glyph: habit.icon, color: habit.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(habit.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: () => AppNavigator.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share2),
                tooltip: context.l10n.share_progress,
                onPressed: () => showShareCard(context, habit),
              ),
              IconButton(
                icon: const Icon(LucideIcons.pencil),
                onPressed: () => AppNavigator.push(
                  HabitFormPage(habit: habit),
                  fullscreenDialog: true,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _DetailBackground(
            coverPath: habit.coverPath,
            child: ListView(
              padding: context.pagePadding(16, 16, 16, 16),
              children: [
                if (minimal) _MinimalHeader(habit: habit),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FrequencyChip(habit: habit),
                ),
                const SizedBox(height: 14),
                if (habit.description.isNotEmpty) ...[
                  Text(
                    habit.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.tokens.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (habit.kind == HabitKind.quantitative) ...[
                  QuantitativeProgress(habit: habit),
                  const SizedBox(height: 20),
                  SectionLabel(
                    context.l10n.quant_per_day,
                    trailing: QuantStatsLink(habit: habit),
                  ),
                  QuantDailyBars(habit: habit),
                  const SizedBox(height: 20),
                ],
                if (habit.hasSubsteps) ...[
                  SectionLabel(context.l10n.todays_checklist),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: HabitChecklist(habit: habit, header: true),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (settings.focusEnabled) ...[
                  _FocusTile(habit: habit),
                  const SizedBox(height: 20),
                ],
                SectionLabel(context.l10n.streaks),
                StreakSummary(habit: habit),
                if (habit.hasCost) ...[
                  const SizedBox(height: 12),
                  SavedMoneyCard(habit: habit),
                ],
                const SizedBox(height: 20),
                SectionLabel(
                  context.l10n.activity,
                  trailing: _ModeToggle(
                    mode: _mode,
                    onChanged: _changeMode,
                  ),
                ),
                _ActivityView(
                  habit: habit,
                  mode: _mode,
                  onToggle: toggle,
                  onLongPress: openDay,
                  showNotes: notesOn,
                ),
                if (notesOn && _mode != HeatmapMode.year) const NoteLegend(),
                if (notesOn) _JourneyStrip(habit: habit),
                const SizedBox(height: 20),
                _VacationTile(habit: habit),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JourneyStrip extends StatelessWidget {
  const _JourneyStrip({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final shots = journeyShots(context.watch<NotesController>(), habit.id);
    if (shots.isEmpty) return const SizedBox.shrink();

    final preview = shots.take(8).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            context.l10n.journey,
            trailing: Semantics(
              button: true,
              child: GestureDetector(
                onTap: () => AppNavigator.push(
                  JourneyPage(habitId: habit.id, accent: habit.color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.journey_sub(shots.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.tokens.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: context.tokens.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) => Semantics(
                button: true,
                label: context.l10n.journey,
                child: GestureDetector(
                  onTap: () => showJourneyViewer(context, shots, index),
                  child: Container(
                    width: 92,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CoverImage.exists(preview[index].path)
                        ? CoverImage(path: preview[index].path)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBackground extends StatelessWidget {
  const _DetailBackground({required this.coverPath, required this.child});

  final String coverPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasCover = CoverImage.exists(coverPath);
    if (!hasCover) return child;
    return Stack(
      children: [
        Positioned.fill(
          child: CoverImage(path: coverPath),
        ),
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.78)),
        ),
        child,
      ],
    );
  }
}

class _ActivityView extends StatelessWidget {
  const _ActivityView({
    required this.habit,
    required this.mode,
    required this.onToggle,
    required this.onLongPress,
    required this.showNotes,
  });

  final Habit habit;
  final HeatmapMode mode;
  final void Function(DateTime date) onToggle;
  final void Function(DateTime date)? onLongPress;
  final bool showNotes;

  @override
  Widget build(BuildContext context) {
    if (mode == HeatmapMode.month) {
      return ActivityCalendar(
        habit: habit,
        onToggle: onToggle,
        onLongPress: onLongPress,
        showNotes: showNotes,
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: HabitHeatmap(
          habit: habit,
          mode: mode,
          onToggle: mode == HeatmapMode.week ? onToggle : null,
          onLongPress: onLongPress,
          showNotes: showNotes && mode == HeatmapMode.week,
        ),
      ),
    );
  }
}

class _MinimalHeader extends StatelessWidget {
  const _MinimalHeader({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HabitGlyph(glyph: habit.icon, color: habit.color, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              habit.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: -0.6,
                color: context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VacationTile extends StatelessWidget {
  const _VacationTile({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final on = habit.isOnVacation;
    final color = context.tokens.info;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.palmtree, size: 22, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.vacation_mode,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        on
                            ? context.l10n.vacation_on_desc
                            : context.l10n.vacation_off_desc,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: context.tokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: on,
                  onChanged: (v) {
                    HapticFeedback.mediumImpact();
                    context.read<HabitsController>().setVacation(habit.id, v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 4),
              child: _RestDays(habit: habit, accent: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestDays extends StatefulWidget {
  const _RestDays({required this.habit, required this.accent});

  final Habit habit;
  final Color accent;

  @override
  State<_RestDays> createState() => _RestDaysState();
}

class _RestDaysState extends State<_RestDays> {
  bool _open = false;

  String _summary(BuildContext context) {
    final days = [...widget.habit.restDays]..sort();
    if (days.isEmpty) return context.l10n.rest_days_none;
    final labels = WeekdayLabels.shortMonFirst(
      Localizations.localeOf(context).languageCode,
    );
    return days.map((day) => labels[day - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.rest_days,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    _summary(context),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.habit.restDays.isEmpty
                          ? context.tokens.muted
                          : widget.accent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: context.tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.rest_days_desc,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: context.tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CompactWeekdays(
                      selected: widget.habit.restDays,
                      accent: widget.accent,
                      onChanged: (days) {
                        HapticFeedback.selectionClick();
                        context
                            .read<HabitsController>()
                            .setRestDays(widget.habit.id, days);
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final HeatmapMode mode;
  final ValueChanged<HeatmapMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final options = [
      (HeatmapMode.week, context.l10n.week),
      (HeatmapMode.month, context.l10n.month),
      (HeatmapMode.year, context.l10n.year),
    ];
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in options)
              Flexible(
                child: Semantics(
                  button: true,
                  selected: value == mode,
                  child: GestureDetector(
                    onTap: () => onChanged(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: value == mode
                            ? scheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: value == mode
                              ? scheme.onPrimary
                              : context.tokens.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _focusLine(BuildContext context, int total, int week, int today) {
  final parts = [
    formatHoursShort(total),
    if (week > 0) '${context.l10n.week} ${formatHoursShort(week)}',
    if (today > 0) '${context.l10n.today} ${formatHoursShort(today)}',
  ];
  return parts.join('  ·  ');
}

class _FocusTile extends StatelessWidget {
  const _FocusTile({required this.habit});

  final Habit habit;

  Future<void> _openActions(BuildContext context) async {
    final action = await showFocusHabitSheet(context, habit: habit);
    if (action == null || !context.mounted) return;
    switch (action) {
      case FocusHabitAction.defaults:
        await showFocusDefaultsSheet(context, habit: habit);
      case FocusHabitAction.clearToday:
        await _clearToday(context);
    }
  }

  Future<void> _clearToday(BuildContext context) async {
    final focus = context.read<FocusController>();
    final ids = focus
        .sessionsForHabitOnDay(habit.id, AppClock.now())
        .map((s) => s.id)
        .toSet();
    if (ids.isEmpty) return;

    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.focus_delete_sessions,
      message: context.l10n.focus_delete_sessions_body(ids.length),
      confirmLabel: context.l10n.delete,
    );
    if (confirmed != true || !context.mounted) return;

    await focus.removeSessions(ids);
    if (!context.mounted) return;
    AppSnackbar.success(context, context.l10n.focus_sessions_deleted(ids.length));
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    final seconds = focus.secondsForHabit(habit.id);
    final today = focus.secondsForHabitOnDay(habit.id, AppClock.now());
    final week = focus.secondsForHabitSince(
      habit.id,
      AppClock.now().startOfWeek(context.watch<SettingsController>().weekStart),
    );

    return Card(
      child: Column(
        children: [
          InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => AppNavigator.push(FocusStatsPage(habitId: habit.id)),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          unawaited(_openActions(context));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              Icon(LucideIcons.timer, size: 21, color: habit.color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.focus_total,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _focusLine(context, seconds, week, today),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.focus_start,
                icon: Icon(LucideIcons.circlePlay, color: habit.color),
                onPressed: () => AppNavigator.push(
                  focus.isActive
                      ? const FocusPage()
                      : FocusPage(
                          startHabitId: habit.id,
                          startMinutes: habit.focusMinutes,
                          breakMinutes: habit.focusBreakMinutes,
                        ),
                  fade: true,
                  name: FocusPage.routeName,
                ),
              ),
            ],
          ),
        ),
          ),
          if (seconds > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: FocusDailyBars(habit: habit),
            ),
        ],
      ),
    );
  }
}
