import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_switch.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/minimal_form_fields.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

String vacationSummary(BuildContext context, Habit habit) {
  if (habit.isOnVacation) return context.l10n.paused;
  final days = [...habit.restDays]..sort();
  if (days.isEmpty) return context.l10n.off;
  final labels = WeekdayLabels.shortMonFirst(
    Localizations.localeOf(context).languageCode,
  );
  return days.map((day) => labels[day - 1]).join(', ');
}

Future<void> showVacationSheet(BuildContext context, {required Habit habit}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _VacationSheet(habitId: habit.id),
  );
}

class _VacationSheet extends StatelessWidget {
  const _VacationSheet({required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitsController>().byId(habitId);
    if (habit == null) return const SizedBox.shrink();

    final express = context.watch<SettingsController>().isExpressStyle;
    final accent = context.tokens.info;
    final on = habit.isOnVacation;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (express)
                  ExpressBlob(
                    size: 44,
                    color: accent.withValues(alpha: 0.18),
                    shape: ExpressShape.flower,
                    child: Icon(LucideIcons.palmtree, size: 20, color: accent),
                  )
                else
                  Icon(LucideIcons.palmtree, size: 22, color: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.l10n.vacation_mode,
                    style: sheetTitleStyle(context, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                if (express)
                  ExpressSwitch(
                    value: on,
                    tint: accent,
                    onChanged: (value) => _setVacation(context, habit, value),
                  )
                else
                  Switch(
                    value: on,
                    onChanged: (value) => _setVacation(context, habit, value),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              on ? context.l10n.vacation_on_desc : context.l10n.vacation_off_desc,
              style: sheetBodyStyle(context, size: 13),
            ),
            const SizedBox(height: 22),
            Text(
              context.l10n.rest_days,
              style: sheetHeadingStyle(
                context,
                color: express ? context.colors.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.rest_days_desc,
              style: sheetBodyStyle(context, size: 12.5),
            ),
            const SizedBox(height: 14),
            CompactWeekdays(
              selected: habit.restDays,
              accent: accent,
              onChanged: (days) {
                HapticFeedback.selectionClick();
                context.read<HabitsController>().setRestDays(habit.id, days);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setVacation(BuildContext context, Habit habit, bool value) {
    HapticFeedback.mediumImpact();
    context.read<HabitsController>().setVacation(habit.id, value);
  }
}
