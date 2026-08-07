import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/features/habits/data/habit.dart';

Future<bool> confirmUnscheduledDay(
  BuildContext context, {
  required Habit habit,
  required DateTime date,
}) async {
  if (habit.kind == HabitKind.negative ||
      habit.completions.containsKey(date.dayKey) ||
      !habit.isOffDay(date)) {
    return true;
  }

  final locale = Localizations.localeOf(context).toString();
  final confirmed = await showAppConfirmDialog(
    context,
    title: context.l10n.unscheduled_title,
    message: context.l10n.unscheduled_body(
      DateFormat.EEEE(locale).format(date),
    ),
    confirmLabel: context.l10n.unscheduled_confirm,
    icon: LucideIcons.calendarOff,
    danger: false,
  );
  return confirmed == true;
}
