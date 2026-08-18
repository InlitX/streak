import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

Set<String> checkedStepsOf(Habit habit) =>
    habit.completions[AppClock.now().dayKey]?.steps ?? const <String>{};

Future<void> setHabitStep(
  BuildContext context,
  Habit habit,
  String stepId,
  bool value,
) async {
  final controller = context.read<HabitsController>();
  final today = AppClock.now();
  if (value) {
    final allowed = await confirmUnscheduledDay(
      context,
      habit: habit,
      date: today,
    );
    if (!allowed) return;
  }
  HapticFeedback.selectionClick();
  await controller.setStep(habit.id, today, stepId, value);
}

List<Substep> orderedSteps(BuildContext context, Habit habit) {
  final checked = checkedStepsOf(habit);
  if (!context.watch<SettingsController>().sortCompletedLast) {
    return habit.substeps;
  }
  return [
    ...habit.substeps.where((s) => !checked.contains(s.id)),
    ...habit.substeps.where((s) => checked.contains(s.id)),
  ];
}

class HabitChecklist extends StatelessWidget {
  const HabitChecklist({
    super.key,
    required this.habit,
    this.dense = false,
    this.header = false,
  });

  final Habit habit;
  final bool dense;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final checked = checkedStepsOf(habit);
    final done = habit.substeps.where((s) => checked.contains(s.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Text(
              context.l10n.steps_done('$done', '${habit.substeps.length}'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.tokens.muted,
              ),
            ),
          ),
        for (final step in orderedSteps(context, habit))
          ChecklistRow(
            title: step.title,
            checked: checked.contains(step.id),
            color: habit.color,
            dense: dense,
            onTap: () => unawaited(
              setHabitStep(context, habit, step.id, !checked.contains(step.id)),
            ),
          ),
      ],
    );
  }
}

class ChecklistRow extends StatelessWidget {
  const ChecklistRow({
    super.key,
    required this.title,
    required this.checked,
    required this.color,
    required this.onTap,
    this.dense = false,
  });

  final String title;
  final bool checked;
  final Color color;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final box = dense ? 22.0 : 26.0;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: dense ? 7 : 10,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: box,
                height: box,
                decoration: BoxDecoration(
                  color: checked ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(dense ? 7 : 8),
                  border: checked
                      ? null
                      : Border.all(
                          color: color.withValues(alpha: 0.5), width: 1.6),
                ),
                child: checked
                    ? Icon(
                        LucideIcons.check,
                        size: dense ? 14 : 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: dense ? 10 : 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: dense ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dense ? 13.5 : 15,
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

class HabitStepsPanel extends StatefulWidget {
  const HabitStepsPanel({super.key, required this.habit});

  final Habit habit;

  @override
  State<HabitStepsPanel> createState() => _HabitStepsPanelState();
}

class _HabitStepsPanelState extends State<HabitStepsPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final checked = checkedStepsOf(habit);
    final done = habit.substeps.where((s) => checked.contains(s.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(9),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.listChecks, size: 13, color: habit.color),
                  const SizedBox(width: 5),
                  Text(
                    context.l10n.steps_done('$done', '${habit.substeps.length}'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: habit.color,
                    ),
                  ),
                  Icon(
                    _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 15,
                    color: habit.color,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? HabitChecklist(habit: habit, dense: true)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
