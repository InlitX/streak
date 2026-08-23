import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';

Future<void> addCustomAmount(BuildContext context, Habit habit) async {
  if (habit.kind != HabitKind.quantitative) return;

  final today = AppClock.now();
  if (!await confirmUnscheduledDay(context, habit: habit, date: today)) return;
  if (!context.mounted) return;

  final amount = await showNumberKeypadDialog(
    context,
    title: context.l10n.quant_add_title,
    value: 0,
    unit: habit.unitLabel,
    decimals: true,
    accent: habit.color,
  );
  if (amount == null || amount <= 0 || !context.mounted) return;

  HapticFeedback.mediumImpact();
  await context.read<HabitsController>().addProgress(habit.id, today, amount);
}
