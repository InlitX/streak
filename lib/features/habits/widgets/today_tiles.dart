import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/statistics/data/habit_stats.dart';

const todayWideWidth = 660.0;

class TodayHeaderSwitch extends StatelessWidget {
  const TodayHeaderSwitch({super.key, required this.wide, required this.narrow});

  final Widget? wide;
  final Widget narrow;

  @override
  Widget build(BuildContext context) => wide == null || !hasRoom(context)
      ? narrow
      : LayoutBuilder(
          builder: (context, box) =>
              box.maxWidth >= todayWideWidth ? wide! : narrow,
        );
}

class TodayTile extends StatelessWidget {
  const TodayTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final muted = context.tokens.muted;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 2),
              Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FocusTodayTile extends StatelessWidget {
  const FocusTodayTile({super.key});

  @override
  Widget build(BuildContext context) {
    final seconds = context.select<FocusController, int>(
      (focus) => focus.secondsForDay(AppClock.today()),
    );
    return TodayTile(
      icon: LucideIcons.timer,
      label: context.l10n.widget_focus_today,
      value: formatMinutes(seconds / 60),
    );
  }
}

class PerfectStreakTile extends StatelessWidget {
  const PerfectStreakTile({super.key, required this.habits});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final streak = HabitStats.perfectStreakOf(
      habits.where((h) => !h.isArchived && !h.tracking).toList(),
      AppClock.today(),
    );
    return TodayTile(
      icon: LucideIcons.flame,
      label: context.l10n.perfect_streak,
      value: context.l10n.count_days(streak.current),
      note: '${context.l10n.best_streak}: ${context.l10n.count_days(streak.best)}',
    );
  }
}
