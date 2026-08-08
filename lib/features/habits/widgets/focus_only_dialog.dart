import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';

Future<bool> allowManualCheck(
  BuildContext context, {
  required Habit habit,
  required DateTime date,
}) async {
  if (!habit.blocksManualCheck(date)) return true;

  if (date.dayKey != AppClock.now().dayKey) {
    AppSnackbar.error(context, context.l10n.focus_only_past(habit.name));
    return false;
  }

  final confirmed = await showAppConfirmDialog(
    context,
    title: context.l10n.focus_only_title,
    message: context.l10n.focus_only_body(habit.name),
    confirmLabel: context.l10n.focus_only_start,
    icon: LucideIcons.timer,
    danger: false,
  );
  if (confirmed != true || !context.mounted) return false;

  AppNavigator.push(
    context.read<FocusController>().isActive
        ? const FocusPage()
        : FocusPage(
            startHabitId: habit.id,
            startMinutes: habit.focusMinutes,
            breakMinutes: habit.focusBreakMinutes,
          ),
  );
  return false;
}
