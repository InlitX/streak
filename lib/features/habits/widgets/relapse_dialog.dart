import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';

bool isRelapse(Habit habit, DateTime date) =>
    habit.completions.containsKey(date.dayKey);

Future<bool> confirmRelapse(BuildContext context, Habit habit) async {
  final confirmed = await showAppConfirmDialog(
    context,
    title: context.l10n.log_relapse_title,
    message: context.l10n.log_relapse_body(habit.name),
    confirmLabel: context.l10n.log_relapse_confirm,
    icon: LucideIcons.ban,
  );
  if (confirmed != true) return false;
  HapticFeedback.heavyImpact();
  return true;
}
