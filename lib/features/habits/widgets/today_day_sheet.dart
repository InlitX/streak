import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';

Future<void> showTodayDaySheet(
  BuildContext context, {
  required DateTime day,
  required Future<void> Function(Habit habit, DateTime day) onToggle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxWidth: phoneWidth,
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
    ),
    builder: (_) => _DaySheet(day: day, onToggle: onToggle),
  );
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.day, required this.onToggle});

  final DateTime day;
  final Future<void> Function(Habit habit, DateTime day) onToggle;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return SafeArea(
      top: false,
      child: Consumer<HabitsController>(
        builder: (context, controller, _) {
          final due = [
            for (final habit in controller.habits)
              if (!habit.tracking && DayPlan.isDueOn(habit, day)) habit,
          ];
          final done = due.where((h) => h.isCompletedOn(day)).length;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat.MMMMEEEEd(locale).format(day),
                        style: sheetTitleStyle(context),
                      ),
                    ),
                    Text(
                      '$done / ${due.length}',
                      style: sheetLabelStyle(context, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final habit in due)
                        _Row(
                          habit: habit,
                          done: habit.isCompletedOn(day),
                          onTap: () => onToggle(habit, day),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.habit, required this.done, required this.onTap});

  final Habit habit;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final color = habit.color.shownIn(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: HabitGlyph(glyph: habit.icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sheetOptionStyle(context),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? color : Colors.transparent,
                border: Border.all(
                  color: done ? color : scheme.onSurface.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: done
                  ? Icon(
                      LucideIcons.check,
                      size: 16,
                      color: color.computeLuminance() > 0.6
                          ? Colors.black
                          : Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
