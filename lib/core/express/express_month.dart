import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_streak_paint.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/note_widgets.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class ExpressMonthCalendar extends StatefulWidget {
  const ExpressMonthCalendar({
    super.key,
    required this.habit,
    required this.onToggle,
    this.onLongPress,
    this.showNotes = false,
  });

  final Habit habit;
  final void Function(DateTime date) onToggle;
  final void Function(DateTime date)? onLongPress;
  final bool showNotes;

  @override
  State<ExpressMonthCalendar> createState() => _ExpressMonthCalendarState();
}

class _ExpressMonthCalendarState extends State<ExpressMonthCalendar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: Express.morph,
    value: 1,
  );
  final _today = AppClock.now().atMidnight;
  late DateTime _month = DateTime(_today.year, _today.month);
  String _signature = '';

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  void _replay(String signature) {
    if (_signature.isEmpty || _signature == signature) {
      _signature = signature;
      return;
    }
    _signature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _morph.forward(from: 0);
    });
  }

  void _shift(int by) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + by));
  }

  ExpressDayState _stateOf(DateTime date) {
    if (date.month != _month.month) return ExpressDayState.blank;
    if (date.isAfter(_today)) return ExpressDayState.future;
    if (widget.habit.isCompletedOn(date)) return ExpressDayState.done;
    if (widget.habit.isCoveredOn(date)) return ExpressDayState.covered;
    if (widget.habit.isNeutralOn(date)) return ExpressDayState.neutral;
    if (widget.habit.isOffDay(date)) return ExpressDayState.off;
    return ExpressDayState.empty;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final locale = Localizations.localeOf(context);
    final weekStart = context.watch<SettingsController>().weekStart;
    final first = DateTime(_month.year, _month.month);
    final offset = first.epochDay - first.startOfWeek(weekStart).epochDay;
    final length = DateTime(_month.year, _month.month + 1, 0).day;
    final weeks = ((offset + length) / 7).ceil();
    final start = first.startOfWeek(weekStart);
    final days = List.generate(weeks * 7, (i) => start.addDays(i));
    final states = [for (final date in days) _stateOf(date)];
    _replay(states.map((s) => s.index).join());

    final atCurrent =
        _month.year == _today.year && _month.month == _today.month;
    final ink = expressInk(context, widget.habit.color);

    return ExpressCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              ExpressIconButton(
                icon: LucideIcons.chevronLeft,
                size: 38,
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: Text(
                  DateFormat(
                    _month.year == _today.year ? 'MMMM' : 'MMMM yyyy',
                    locale.toString(),
                  ).format(_month),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ExpressType.display.at(
                    19,
                    spacing: -0.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              ExpressIconButton(
                icon: LucideIcons.chevronRight,
                size: 38,
                onPressed: atCurrent ? null : () => _shift(1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final label in WeekdayLabels.shortFrom(
                locale.languageCode,
                weekStart,
              ))
                Expanded(
                  child: Text(
                    label.replaceAll('.', '').toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: ExpressType.body.at(
                      9.5,
                      weight: 800,
                      spacing: 0.6,
                      color: context.tokens.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _morph,
            builder: (context, _) => Column(
              children: [
                for (var week = 0; week < weeks; week++)
                  SizedBox(
                    height: 42,
                    child: CustomPaint(
                      painter: _MonthRowPainter(
                        states: states.sublist(week * 7, week * 7 + 7),
                        ink: ink,
                        progress: Express.bouncy.transform(_morph.value),
                      ),
                      child: Row(
                        children: [
                          for (var day = 0; day < 7; day++)
                            Expanded(
                              child: _MonthCell(
                                habit: widget.habit,
                                date: days[week * 7 + day],
                                state: states[week * 7 + day],
                                isToday: days[week * 7 + day] == _today,
                                showNotes: widget.showNotes,
                                onToggle: widget.onToggle,
                                onLongPress: widget.onLongPress,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExpressMonthStrip extends StatelessWidget {
  const ExpressMonthStrip({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final weekStart = context.watch<SettingsController>().weekStart;
    final today = AppClock.now().atMidnight;
    final first = DateTime(today.year, today.month);
    final offset = first.epochDay - first.startOfWeek(weekStart).epochDay;
    final length = DateTime(today.year, today.month + 1, 0).day;
    final weeks = ((offset + length) / 7).ceil();
    final start = first.startOfWeek(weekStart);

    ExpressDayState stateOf(DateTime date) {
      if (date.month != today.month) return ExpressDayState.blank;
      if (date.isAfter(today)) return ExpressDayState.future;
      if (habit.isCompletedOn(date)) return ExpressDayState.done;
      if (habit.isCoveredOn(date)) return ExpressDayState.covered;
      if (habit.isNeutralOn(date)) return ExpressDayState.neutral;
      if (habit.isOffDay(date)) return ExpressDayState.off;
      return ExpressDayState.empty;
    }

    final ink = expressInk(context, habit.color);

    return Column(
      children: [
        for (var week = 0; week < weeks; week++)
          SizedBox(
            height: 16,
            child: CustomPaint(
              size: Size.infinite,
              painter: _MonthRowPainter(
                states: [
                  for (var day = 0; day < 7; day++)
                    stateOf(start.addDays(week * 7 + day)),
                ],
                ink: ink,
                progress: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.habit,
    required this.date,
    required this.state,
    required this.isToday,
    required this.showNotes,
    required this.onToggle,
    required this.onLongPress,
  });

  final Habit habit;
  final DateTime date;
  final ExpressDayState state;
  final bool isToday;
  final bool showNotes;
  final void Function(DateTime date) onToggle;
  final void Function(DateTime date)? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (state == ExpressDayState.blank) return const SizedBox.shrink();

    final done = state == ExpressDayState.done;
    final future = state == ExpressDayState.future;
    final ink = done
        ? (habit.color.computeLuminance() > 0.55 ? Colors.black : Colors.white)
        : future
        ? context.tokens.muted.withValues(alpha: 0.45)
        : context.colors.onSurface;

    return Semantics(
      button: !future,
      label: heatmapDayLabel(context, habit, date),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: future
            ? null
            : () {
                HapticFeedback.selectionClick();
                onToggle(date);
              },
        onLongPress: onLongPress == null ? null : () => onLongPress!(date),
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: ExpressType.rounded.at(
                  14,
                  weight: done || isToday ? 850 : 650,
                  color: isToday && !done ? context.colors.primary : ink,
                  tabular: true,
                ),
              ),
              if (showNotes)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: NoteDots(
                    types: context.watch<NotesController>().typesFor(
                      habit.id,
                      date.dayKey,
                    ),
                    size: 4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthRowPainter extends CustomPainter {
  const _MonthRowPainter({
    required this.states,
    required this.ink,
    required this.progress,
  });

  final List<ExpressDayState> states;
  final ExpressStreakInk ink;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    paintStreakRow(
      canvas,
      Offset.zero & size,
      states,
      ink,
      progress,
      thicknessRatio: 1,
      gap: 4,
      edge: 3,
    );
  }

  @override
  bool shouldRepaint(_MonthRowPainter old) =>
      old.progress != progress ||
      old.ink.color != ink.color ||
      old.ink.track != ink.track ||
      !sameStates(old.states, states);
}
