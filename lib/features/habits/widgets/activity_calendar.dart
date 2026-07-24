import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class ActivityCalendar extends StatefulWidget {
  const ActivityCalendar({
    super.key,
    required this.habit,
    required this.onToggle,
  });

  final Habit habit;
  final void Function(DateTime date) onToggle;

  @override
  State<ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends State<ActivityCalendar> {
  final _today = DateTime.now();
  late DateTime _month = DateTime(_today.year, _today.month, 1);

  List<DateTime> _daysFor(int weekStart) {
    final first = DateTime(_month.year, _month.month, 1);
    final start = first.startOfWeek(weekStart);
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  bool _isCurrentMonth(DateTime d) =>
      d.month == _month.month && d.year == _month.year;

  bool _isToday(DateTime d) =>
      d.year == _today.year && d.month == _today.month && d.day == _today.day;

  void _shift(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by, 1));

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final habit = widget.habit;
    final atCurrent = _isCurrentMonth(DateTime.now());
    final weekStart = context.watch<SettingsController>().weekStart;
    final days = _daysFor(weekStart);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _month.year == _today.year
                      ? DateFormat('MMMM').format(_month)
                      : DateFormat('MMMM yyyy').format(_month),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _shift(-1),
                      icon: const Icon(LucideIcons.chevronLeft),
                    ),
                    IconButton(
                      onPressed: atCurrent ? null : () => _shift(1),
                      icon: Icon(
                        LucideIcons.chevronRight,
                        color: atCurrent ? context.tokens.muted : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: WeekdayLabels.shortFrom(
                      Localizations.localeOf(context).languageCode, weekStart)
                  .map((d) => Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.tokens.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            for (var week = 0; week < 6; week++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    for (var day = 0; day < 7; day++)
                      Expanded(
                        child: _CalendarCell(
                          date: days[week * 7 + day],
                          habit: habit,
                          isCurrentMonth:
                              _isCurrentMonth(days[week * 7 + day]),
                          isToday: _isToday(days[week * 7 + day]),
                          onToggle: widget.onToggle,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.date,
    required this.habit,
    required this.isCurrentMonth,
    required this.isToday,
    required this.onToggle,
  });

  final DateTime date;
  final Habit habit;
  final bool isCurrentMonth;
  final bool isToday;
  final void Function(DateTime date) onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final negative = habit.kind == HabitKind.negative;
    final ratioFill = habit.kind == HabitKind.quantitative || habit.hasSubsteps;
    final future = date.isAfter(DateTime.now());
    final beforeCreation = date.atMidnight.isBefore(habit.createdAt.atMidnight);
    final outOfScope = future || beforeCreation;
    final completed = habit.isCompletedOn(date);
    final relapsed = negative && !completed && !outOfScope;
    final paused = isCurrentMonth && !outOfScope && habit.isNeutralOn(date);
    final tappable = isCurrentMonth && !future;
    final danger = context.tokens.danger;
    final count = habit.completions[date.dayKey]?.count ?? 0;

    final Color? fillColor;
    if (paused) {
      fillColor = context.tokens.info.withValues(alpha: 0.5);
    } else if (isCurrentMonth && relapsed) {
      fillColor = danger;
    } else if (isCurrentMonth && negative && !outOfScope) {
      fillColor = habit.color.withValues(alpha: 0.24);
    } else if (isCurrentMonth && ratioFill && count > 0) {
      final target = habit.effectiveTarget <= 0 ? 1 : habit.effectiveTarget;
      final ratio = (count / target).clamp(0.25, 1.0);
      fillColor = Color.lerp(
        habit.color.withValues(alpha: 0.4),
        habit.color,
        ratio,
      );
    } else if (isCurrentMonth && !negative && !ratioFill && completed) {
      fillColor = habit.color;
    } else {
      fillColor = null;
    }
    final filledStrong = isCurrentMonth &&
        !paused &&
        (relapsed ||
            (!negative && !ratioFill && completed) ||
            (ratioFill && count > 0));

    final Color textColor;
    if (filledStrong) {
      textColor = (relapsed ? danger : habit.color).computeLuminance() > 0.5
          ? Colors.black
          : Colors.white;
    } else if (!isCurrentMonth) {
      textColor = context.tokens.muted.withValues(alpha: 0.3);
    } else if (future) {
      textColor = context.tokens.muted.withValues(alpha: 0.5);
    } else {
      textColor = scheme.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tappable ? () => onToggle(date) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          height: 38,
          decoration: BoxDecoration(
            color: fillColor ??
                (isToday ? scheme.surfaceContainerHighest : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: isToday && !filledStrong
                ? Border.all(color: habit.color.withValues(alpha: 0.5))
                : null,
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
