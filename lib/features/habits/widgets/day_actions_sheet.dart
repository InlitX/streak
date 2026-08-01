import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/note_editor_page.dart';
import 'package:streak/features/habits/pages/notes_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/state/notes_controller.dart';

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

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
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
                DateFormat.yMMMMEEEEd(locale).format(date),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            if (!date.atMidnight.isAfter(AppClock.now().atMidnight)) ...[
              _Action(
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
              _Action(
                icon: LucideIcons.notebookPen,
                label: context.l10n.view_notes,
                badge: count > 0 ? '$count' : null,
                accent: habit.color,
                highlighted: true,
                trailing: LucideIcons.chevronRight,
                onTap: () {
                  Navigator.of(sheet).pop();
                  AppNavigator.push(
                    NotesPage(
                      habitId: habit.id,
                      date: date,
                      accent: habit.color,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              _Action(
                icon: LucideIcons.circlePlus,
                label: context.l10n.add_note,
                onTap: () {
                  Navigator.of(sheet).pop();
                  AppNavigator.push(
                    NoteEditorPage(
                      habitId: habit.id,
                      dayKey: date.dayKey,
                      accent: habit.color,
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
                  context.l10n.cancel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.accent,
    this.trailing,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final Color? accent;
  final IconData? trailing;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? context.colors.primary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: highlighted
                ? Border.all(color: color.withValues(alpha: 0.7), width: 1.4)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: highlighted ? color : context.colors.onSurface,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, size: 18, color: context.tokens.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
