import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/widgets/sheet_action.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';

enum FocusHabitAction { defaults, clearToday }

String focusDefaultsLabel(BuildContext context, Habit habit) =>
    habit.focusBreakMinutes > 0
        ? '${habit.focusMinutes} / ${habit.focusBreakMinutes} '
            '${context.l10n.unit_min_short}'
        : context.l10n.minutes_short('${habit.focusMinutes}');

Future<FocusHabitAction?> showFocusHabitSheet(
  BuildContext context, {
  required Habit habit,
}) {
  final today = context
      .read<FocusController>()
      .sessionsForHabitOnDay(habit.id, AppClock.now())
      .length;

  return showModalBottomSheet<FocusHabitAction>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sheetTitleStyle(context, size: 18),
              ),
            ),
            SheetAction(
              icon: LucideIcons.timer,
              label: context.l10n.focus_defaults,
              badge: focusDefaultsLabel(context, habit),
              accent: habit.color,
              highlighted: true,
              onTap: () => Navigator.of(sheet).pop(FocusHabitAction.defaults),
            ),
            if (today > 0) ...[
              const SizedBox(height: 6),
              SheetAction(
                icon: LucideIcons.eraser,
                label: context.l10n.focus_clear_today,
                badge: '$today',
                accent: context.tokens.danger,
                onTap: () =>
                    Navigator.of(sheet).pop(FocusHabitAction.clearToday),
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
                  context.l10n.cancel,
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
