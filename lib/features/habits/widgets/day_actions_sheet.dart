import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/core/widgets/sheet_action.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/note_editor_page.dart';
import 'package:streak/features/habits/pages/notes_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/habits/widgets/focus_only_dialog.dart';
import 'package:streak/features/habits/widgets/habit_checklist.dart';
import 'package:streak/features/habits/widgets/miss_reasons.dart';
import 'package:streak/features/habits/widgets/relapse_dialog.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/core/extensions/color_extensions.dart';

Future<void> showDayActionsSheet(
  BuildContext context, {
  required Habit habit,
  required DateTime date,
  required bool notesEnabled,
}) {
  final count = context.read<NotesController>().countFor(habit.id, date.dayKey);
  final locale = Localizations.localeOf(context).toString();
  final habits = context.read<HabitsController>();
  final paused = habit.isPausedOn(date);
  final reachable = !date.atMidnight.isAfter(AppClock.today());

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxWidth: phoneWidth,
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (sheet) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 14 + MediaQuery.viewInsetsOf(sheet).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                DateFormat.yMMMMEEEEd(locale).format(date),
                style: sheetTitleStyle(context, size: 17),
              ),
            ),
            if (reachable) ...[
              _DayStatus(habitId: habit.id, date: date),
              const SizedBox(height: 12),
              MissReasonPicker(habitId: habit.id, date: date),
            ],
            if (habit.hasSubsteps && reachable) ...[
              Consumer<HabitsController>(
                builder: (inner, controller, _) => HabitChecklist(
                  habit: controller.byId(habit.id) ?? habit,
                  date: date,
                  dense: true,
                  header: true,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (!habit.isRestDay(date) && reachable) ...[
              SheetAction(
                icon: LucideIcons.palmtree,
                label: paused
                    ? context.l10n.vacation_day_off
                    : context.l10n.vacation_day_on,
                accent: context.tokens.info,
                highlighted: paused,
                onTap: () {
                  Navigator.of(sheet).pop();
                  habits.toggleVacationDay(habit.id, date);
                },
              ),
              const SizedBox(height: 6),
            ],
            if (notesEnabled) ...[
              SheetAction(
                icon: LucideIcons.notebookPen,
                label: context.l10n.view_notes,
                badge: count > 0 ? '$count' : null,
                accent: habit.color.shownIn(context),
                highlighted: true,
                trailing: LucideIcons.chevronRight,
                onTap: () {
                  Navigator.of(sheet).pop();
                  AppNavigator.push(
                    NotesPage(
                      habitId: habit.id,
                      date: date,
                      accent: habit.color.shownIn(context),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              SheetAction(
                icon: LucideIcons.circlePlus,
                label: context.l10n.add_note,
                onTap: () {
                  Navigator.of(sheet).pop();
                  AppNavigator.push(
                    NoteEditorPage(
                      habitId: habit.id,
                      dayKey: date.dayKey,
                      accent: habit.color.shownIn(context),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(sheet).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.surfaceContainerHighest,
                  foregroundColor: context.colors.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.l10n.done,
                  style: sheetActionStyle(context),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DayStatus extends StatelessWidget {
  const _DayStatus({required this.habitId, required this.date});

  final String habitId;
  final DateTime date;

  Future<void> _toggle(BuildContext context, Habit habit) async {
    final controller = context.read<HabitsController>();
    if (!await allowManualCheck(context, habit: habit, date: date)) return;
    if (!context.mounted) return;
    if (!await confirmUnscheduledDay(context, habit: habit, date: date)) return;
    await controller.toggle(habit.id, date);
  }

  Future<void> _relapse(BuildContext context, Habit habit) async {
    final controller = context.read<HabitsController>();
    final spent = await askRelapse(context, habit);
    if (spent == null) return;
    await controller.logRelapse(habit.id, date, spent: spent);
  }

  Future<void> _set(BuildContext context, Habit habit, double value) async {
    final controller = context.read<HabitsController>();
    if (!await allowManualCheck(context, habit: habit, date: date)) return;
    if (!context.mounted) return;
    if (!await confirmUnscheduledDay(context, habit: habit, date: date)) return;
    await controller.setProgress(habit.id, date, value < 0 ? 0 : value);
  }

  Future<void> _type(BuildContext context, Habit habit, double current) async {
    final value = await showNumberKeypadDialog(
      context,
      title: DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(date),
      value: current,
      unit: habit.unitLabel,
      target: habit.goalOn(date) > 0 ? habit.goalOn(date) : null,
      decimals: true,
      clock: habit.isTimeAmount,
      accent: habit.color.shownIn(context),
    );
    if (value == null || value == current || !context.mounted) return;
    await _set(context, habit, value);
  }

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitsController>().byId(habitId);
    if (habit == null) return const SizedBox.shrink();
    final color = habit.color.shownIn(context);
    final count = habit.completions[date.dayKey]?.count ?? 0;
    final negative = habit.kind == HabitKind.negative;
    final quantity = habit.kind == HabitKind.quantitative;
    final counted = !negative && !habit.hasSubsteps && (quantity || habit.perDayTarget > 1);
    final goal = habit.goalOn(date);
    final done = habit.isCompletedOn(date);
    final relapsed = habit.isRelapseOn(date);
    final relapses = relapsed ? count.round().clamp(1, 999) : 0;
    final unit = habit.isTimeAmount || habit.unitLabel.isEmpty ? '' : ' ${habit.unitLabel}';
    String amount(double value) => '${habit.amountText(value)}$unit';

    final status = negative
        ? (relapsed ? context.l10n.day_relapses(relapses) : context.l10n.day_clean)
        : counted
            ? (goal > 0
                ? context.l10n.day_amount(amount(count), amount(goal))
                : amount(count))
            : (done ? context.l10n.done : context.l10n.day_not_done);
    final good = negative ? !relapsed : done;
    final step = quantity ? habit.incrementAmount : 1.0;
    final tint = relapsed ? context.colors.error : color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: good || relapsed ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: HabitGlyph(glyph: habit.icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sheetHeadingStyle(context, size: 16),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        status,
                        key: ValueKey(status),
                        style: sheetLabelStyle(
                          context,
                          color: relapsed
                              ? context.colors.error
                              : good
                                  ? color
                                  : context.tokens.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (negative && !relapsed)
                _Pill(
                  label: context.l10n.day_log_relapse,
                  color: context.colors.error,
                  filled: true,
                  onTap: () => _relapse(context, habit),
                )
              else if (!counted && !habit.hasSubsteps)
                _CheckButton(done: done, color: color, onTap: () => _toggle(context, habit)),
            ],
          ),
          if (relapsed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _RoundIcon(
                  icon: LucideIcons.minus,
                  color: context.colors.error,
                  onTap: () => context.read<HabitsController>().dropRelapse(habit.id, date),
                ),
                Expanded(
                  child: Text(
                    '$relapses',
                    textAlign: TextAlign.center,
                    style: sheetTitleStyle(context, size: 24, color: context.colors.error),
                  ),
                ),
                _RoundIcon(
                  icon: LucideIcons.plus,
                  color: context.colors.error,
                  onTap: () => context.read<HabitsController>().addRelapse(habit.id, date),
                ),
              ],
            ),
            if (habit.logsSpent) ...[
              const SizedBox(height: 12),
              SpentField(
                value: habit.completions[date.dayKey]?.spent ?? 0,
                onChanged: (value) =>
                    context.read<HabitsController>().setSpent(habit.id, date, value),
              ),
            ],
          ],
          if (counted) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  end: goal <= 0
                      ? (count > 0 ? 1 : 0)
                      : (count / goal).clamp(0, 1).toDouble(),
                ),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _RoundIcon(
                  icon: LucideIcons.minus,
                  color: color,
                  onTap: count <= 0 ? null : () => _set(context, habit, count - step),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: quantity ? () => _type(context, habit, count) : null,
                    child: Column(
                      children: [
                        Text(
                          amount(count),
                          maxLines: 1,
                          style: sheetTitleStyle(context, size: 24),
                        ),
                        if (quantity)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.pencil, size: 12, color: context.tokens.muted),
                              const SizedBox(width: 4),
                              Text(context.l10n.edit, style: sheetLabelStyle(context, size: 12)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                _RoundIcon(
                  icon: LucideIcons.plus,
                  color: color,
                  onTap: () => _set(context, habit, count + step),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.color, required this.onTap});

  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = color.computeLuminance() > 0.6 ? Colors.black : Colors.white;
    return Semantics(
      button: true,
      checked: done,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: done ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: done ? color : color.withValues(alpha: 0.45), width: 2),
          ),
          child: AnimatedScale(
            scale: done ? 1 : 0.6,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Icon(
              LucideIcons.check,
              size: 22,
              color: done ? on : color.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: color.withValues(alpha: enabled ? 0.16 : 0.06),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: enabled ? color : color.withValues(alpha: 0.35)),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.filled, required this.onTap});

  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color.withValues(alpha: 0.14) : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: filled ? 0 : 0.5), width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(label, style: sheetHeadingStyle(context, size: 13.5, color: color)),
        ),
      ),
    );
  }
}
