import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';

void announcePastCheck(
  BuildContext context,
  HabitsController controller,
  Habit habit,
  DateTime date,
  bool wasDone,
) {
  if (!date.atMidnight.isBefore(AppClock.today())) return;
  final day = DateFormat.MMMd(Localizations.localeOf(context).toString())
      .format(date);
  final l10n = context.l10n;
  AppSnackbar.action(
    context,
    wasDone ? l10n.day_unmarked(day) : l10n.day_marked(day),
    label: l10n.undo,
    duration: const Duration(seconds: 6),
    onPressed: () => controller.toggle(habit.id, date),
  );
}
