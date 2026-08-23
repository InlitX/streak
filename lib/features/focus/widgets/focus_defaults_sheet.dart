import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/focus/widgets/focus_duration_fields.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';

Future<void> showFocusDefaultsSheet(
  BuildContext context, {
  required Habit habit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _FocusDefaults(habit: habit),
  );
}

class _FocusDefaults extends StatefulWidget {
  const _FocusDefaults({required this.habit});

  final Habit habit;

  @override
  State<_FocusDefaults> createState() => _FocusDefaultsState();
}

class _FocusDefaultsState extends State<_FocusDefaults> {
  late int _minutes = widget.habit.focusMinutes;
  late bool _pomodoro = widget.habit.focusBreakMinutes > 0;
  late int _breakMinutes =
      _pomodoro ? widget.habit.focusBreakMinutes : focusBreakPresets.first;

  Future<void> _save() async {
    final habits = context.read<HabitsController>();
    final updated = widget.habit.copyWith(
      focusMinutes: _minutes,
      focusBreakMinutes: _pomodoro ? _breakMinutes : 0,
    );
    Navigator.of(context).pop();
    await habits.update(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 16),
              child: Text(
                context.l10n.focus_defaults,
                style: sheetTitleStyle(context, size: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                context.l10n.focus_duration,
                style: sheetLabelStyle(context),
              ),
            ),
            FocusDurationChips(
              minutes: _minutes,
              onChanged: (value) => setState(() => _minutes = value),
            ),
            const SizedBox(height: 18),
            FocusPomodoroCard(
              enabled: _pomodoro,
              breakMinutes: _breakMinutes,
              onToggle: (value) => setState(() => _pomodoro = value),
              onBreakChanged: (value) =>
                  setState(() => _breakMinutes = value),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.l10n.save,
                  style: sheetActionStyle(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
