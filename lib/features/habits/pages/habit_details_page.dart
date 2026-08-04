import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_setup_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/features/habits/pages/journey_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/habits/widgets/activity_calendar.dart';
import 'package:streak/features/habits/widgets/day_actions_sheet.dart';
import 'package:streak/features/habits/widgets/note_widgets.dart';
import 'package:streak/features/habits/widgets/frequency_chip.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/minimal_form_fields.dart';
import 'package:streak/features/habits/widgets/quantitative_progress.dart';
import 'package:streak/features/habits/widgets/share_card.dart';
import 'package:streak/features/habits/widgets/streak_summary.dart';
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
          final current = habit.completions[date.dayKey]?.count ?? 0;
          final value = await showNumberKeypadDialog(
            context,
            title: DateFormat.yMMMMd(
              Localizations.localeOf(context).toString(),
            ).format(date),
            value: current,
            unit: habit.unitLabel,
            target: habit.perDayTarget,
            accent: habit.color,
          );
          if (value != null && value != current) {
            await controller.setProgress(habit.id, date, value);
          }
        }

        void toggle(DateTime date) {
          HapticFeedback.selectionClick();
          switch (habit.kind) {
            case HabitKind.positive:
              controller.toggle(habit.id, date);
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
            child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
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
                ],
                if (habit.hasSubsteps) ...[
                  SectionLabel(context.l10n.todays_checklist),
                  _TodayChecklist(habit: habit),
                  const SizedBox(height: 20),
                ],
                if (settings.focusEnabled) ...[
                  _FocusTile(habit: habit),
                  const SizedBox(height: 20),
                ],
                SectionLabel(context.l10n.streaks),
                StreakSummary(habit: habit),
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

class _TodayChecklist extends StatelessWidget {
  const _TodayChecklist({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<HabitsController>();
    final sortCompletedLast = context.watch<SettingsController>().sortCompletedLast;
    final today = AppClock.now();
    final checked = habit.completions[today.dayKey]?.steps ?? const <String>{};
    final done = habit.substeps.where((s) => checked.contains(s.id)).length;
    final steps = sortCompletedLast
        ? [
            ...habit.substeps.where((s) => !checked.contains(s.id)),
            ...habit.substeps.where((s) => checked.contains(s.id)),
          ]
        : habit.substeps;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.steps_done('$done', '${habit.substeps.length}'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.tokens.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final step in steps)
              _ChecklistRow(
                title: step.title,
                checked: checked.contains(step.id),
                color: habit.color,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.setStep(
                    habit.id,
                    today,
                    step.id,
                    !checked.contains(step.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.title,
    required this.checked,
    required this.color,
    required this.onTap,
  });

  final String title;
  final bool checked;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: checked ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: checked
                      ? null
                      : Border.all(
                          color: color.withValues(alpha: 0.5), width: 1.6),
                ),
                child: checked
                    ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: checked
                        ? context.tokens.muted
                        : context.colors.onSurface,
                    decoration:
                        checked ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: context.tokens.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.rest_days,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
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
                    selected: habit.restDays,
                    accent: color,
                    onChanged: (days) {
                      HapticFeedback.selectionClick();
                      context
                          .read<HabitsController>()
                          .setRestDays(habit.id, days);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

class _FocusTile extends StatelessWidget {
  const _FocusTile({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    final seconds = focus.secondsForHabit(habit.id);
    final today = focus.secondsForHabitOnDay(habit.id, AppClock.now());

    return Card(
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
                    today > 0
                        ? '${formatHoursShort(seconds)}  ·  ${context.l10n.today} ${formatHoursShort(today)}'
                        : formatHoursShort(seconds),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.circlePlay, color: habit.color),
              onPressed: () => AppNavigator.push(
                FocusSetupPage(habitId: habit.id),
                fullscreenDialog: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
