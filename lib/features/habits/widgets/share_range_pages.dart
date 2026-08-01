import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

enum ShareRange { week, month, year }

class SharePanelHeader extends StatelessWidget {
  const SharePanelHeader({
    super.key,
    required this.habit,
    required this.title,
    required this.subtitle,
    required this.width,
  });

  final Habit habit;
  final String title;
  final String subtitle;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            habit.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontStyle: FontStyle.italic,
              fontSize: width * 0.06,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: width * 0.03),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: width * 0.034,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: width * 0.034,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Color shareDayFill(Habit habit, DateTime date, Color accent) {
  if (date.isAfter(AppClock.now())) return Colors.transparent;
  if (habit.isNeutralOn(date)) return const Color(0xFF3F6CA8);
  if (habit.kind == HabitKind.negative) {
    return habit.completions.containsKey(date.dayKey)
        ? const Color(0xFF9E3B3B)
        : accent;
  }
  return habit.isCompletedOn(date) ? accent : Colors.transparent;
}

class ShareMonthPage extends StatelessWidget {
  const ShareMonthPage({
    super.key,
    required this.habit,
    required this.accent,
    required this.width,
    required this.offset,
  });

  final Habit habit;
  final Color accent;
  final double width;
  final int offset;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final weekStart = context.watch<SettingsController>().weekStart;
    final today = AppClock.now();
    final month = DateTime(today.year, today.month + offset, 1);
    final first = month.startOfWeek(weekStart);
    final length = DateTime(month.year, month.month + 1, 0).day;
    final lead = month.difference(first).inDays;
    final weeks = ((lead + length) / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharePanelHeader(
          habit: habit,
          title: DateFormat.MMMM(locale).format(month),
          subtitle: '${month.year}',
          width: width,
        ),
        SizedBox(height: width * 0.04),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final column = box.maxWidth / 7;
              final row = (box.maxHeight / weeks).clamp(0.0, column);
              final side = row * 0.84;

              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var w = 0; w < weeks; w++)
                    SizedBox(
                      height: row,
                      child: Row(
                        children: [
                          for (var d = 0; d < 7; d++)
                            Builder(builder: (_) {
                              final date = first.add(Duration(days: w * 7 + d));
                              final inMonth = date.month == month.month &&
                                  date.year == month.year;
                              final fill = inMonth
                                  ? shareDayFill(habit, date, accent)
                                  : Colors.transparent;
                              final filled = fill != Colors.transparent;
                              return SizedBox(
                                width: column,
                                child: Center(
                                  child: Container(
                                    width: side,
                                    height: side,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: fill,
                                      borderRadius:
                                          BorderRadius.circular(side * 0.3),
                                    ),
                                    child: Text(
                                      inMonth ? '${date.day}' : '',
                                      style: TextStyle(
                                        fontSize: (side * 0.44).clamp(8.0, 16.0),
                                        fontWeight: filled
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: filled
                                            ? (fill.computeLuminance() > 0.6
                                                ? Colors.black
                                                : Colors.white)
                                            : Colors.white
                                                .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class ShareWeekPage extends StatelessWidget {
  const ShareWeekPage({
    super.key,
    required this.habit,
    required this.accent,
    required this.width,
    required this.offset,
  });

  final Habit habit;
  final Color accent;
  final double width;
  final int offset;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final weekStart = context.watch<SettingsController>().weekStart;
    final letters = WeekdayLabels.narrowFrom(
      Localizations.localeOf(context).languageCode,
      weekStart,
    );
    final start = AppClock.now()
        .add(Duration(days: 7 * offset))
        .startOfWeek(weekStart);
    final end = start.add(const Duration(days: 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharePanelHeader(
          habit: habit,
          title: '${start.day} – ${end.day} '
              '${DateFormat.MMM(locale).format(end)}',
          subtitle: '${end.year}',
          width: width,
        ),
        SizedBox(height: width * 0.04),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final column = box.maxWidth / 7;
              final side =
                  (column * 0.8).clamp(0.0, box.maxHeight * 0.62).toDouble();

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < 7; i++)
                    SizedBox(
                      width: column,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            letters[i],
                            style: TextStyle(
                              fontSize: side * 0.3,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.38),
                            ),
                          ),
                          SizedBox(height: side * 0.24),
                          Builder(builder: (_) {
                            final date = start.add(Duration(days: i));
                            final fill = shareDayFill(habit, date, accent);
                            final filled = fill != Colors.transparent;
                            return Container(
                              width: side,
                              height: side,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: filled
                                    ? fill
                                    : Colors.white.withValues(alpha: 0.07),
                                borderRadius:
                                    BorderRadius.circular(side * 0.3),
                              ),
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: side * 0.36,
                                  fontWeight: FontWeight.w700,
                                  color: filled
                                      ? (fill.computeLuminance() > 0.6
                                          ? Colors.black
                                          : Colors.white)
                                      : Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class ShareYearPage extends StatelessWidget {
  const ShareYearPage({
    super.key,
    required this.habit,
    required this.accent,
    required this.width,
    required this.offset,
  });

  final Habit habit;
  final Color accent;
  final double width;
  final int offset;

  @override
  Widget build(BuildContext context) {
    final weekStart = context.watch<SettingsController>().weekStart;
    final anchor = AppClock.now()
        .startOfWeek(weekStart)
        .add(Duration(days: 7 * 8 * offset));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: width * 0.13,
              height: width * 0.13,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(width * 0.036),
              ),
              child: HabitGlyph(
                glyph: habit.icon,
                color: Colors.white,
                size: width * 0.062,
              ),
            ),
            SizedBox(width: width * 0.035),
            Expanded(
              child: Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: width * 0.062,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: width * 0.045),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final gap = (width * 0.011).clamp(1.4, 3.5);
              var cell = (box.maxHeight - gap * 6) / 7;
              var columns = ((box.maxWidth + gap) / (cell + gap)).floor();
              if (columns > 53) {
                columns = 53;
                cell = (box.maxWidth - gap * (columns - 1)) / columns;
              }
              if (columns < 1) columns = 1;

              return Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: cell * 7 + gap * 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < columns; c++)
                        Padding(
                          padding: EdgeInsets.only(
                            right: c == columns - 1 ? 0 : gap,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var r = 0; r < 7; r++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: r == 6 ? 0 : gap,
                                  ),
                                  child: Builder(builder: (_) {
                                    final date = anchor.subtract(
                                      Duration(days: 7 * (columns - 1 - c) - r),
                                    );
                                    final fill = shareDayFill(habit, date, accent);
                                    return Container(
                                      width: cell,
                                      height: cell,
                                      decoration: BoxDecoration(
                                        color: fill == Colors.transparent
                                            ? Colors.white
                                                .withValues(alpha: 0.06)
                                            : fill,
                                        borderRadius:
                                            BorderRadius.circular(cell * 0.32),
                                      ),
                                    );
                                  }),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
