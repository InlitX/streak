import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/habits/data/habit.dart';

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

  List<DateTime> get _days {
    final first = DateTime(_month.year, _month.month, 1);
    final start = first.subtract(Duration(days: first.weekday % 7));
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
              children: WeekdayLabels.shortSunFirst(
                      Localizations.localeOf(context).languageCode)
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
                          date: _days[week * 7 + day],
                          habit: habit,
                          isCurrentMonth:
                              _isCurrentMonth(_days[week * 7 + day]),
                          isToday: _isToday(_days[week * 7 + day]),
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
    final completed = habit.isCompletedOn(date);
    final future = date.isAfter(DateTime.now());
    final tappable = isCurrentMonth && !future;

    final Color textColor;
    if (completed && isCurrentMonth) {
      textColor =
          habit.color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
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
            color: completed && isCurrentMonth
                ? habit.color
                : isToday
                    ? scheme.surfaceContainerHighest
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isToday && !completed
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
