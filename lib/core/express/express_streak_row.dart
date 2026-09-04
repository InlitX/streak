import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_streak_paint.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class ExpressStreakRow extends StatefulWidget {
  const ExpressStreakRow({
    super.key,
    required this.habit,
    this.onToggle,
    this.onLongPress,
    this.days = 7,
    this.height = 50,
    this.showLabels = true,
  });

  final Habit habit;
  final void Function(DateTime date)? onToggle;
  final void Function(DateTime date)? onLongPress;
  final int days;
  final double height;
  final bool showLabels;

  @override
  State<ExpressStreakRow> createState() => _ExpressStreakRowState();
}

class _ExpressStreakRowState extends State<ExpressStreakRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: Express.morph,
    value: 1,
  );
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

  ExpressDayState _stateOf(DateTime date, DateTime today) {
    if (date.isAfter(today)) return ExpressDayState.future;
    if (widget.habit.isCompletedOn(date)) return ExpressDayState.done;
    if (widget.habit.isCoveredOn(date)) return ExpressDayState.covered;
    if (widget.habit.isNeutralOn(date)) return ExpressDayState.neutral;
    if (widget.habit.isOffDay(date)) return ExpressDayState.off;
    return ExpressDayState.empty;
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = context.watch<SettingsController>().weekStart;
    final today = AppClock.now().atMidnight;
    final start = widget.days == 7
        ? today.startOfWeek(weekStart)
        : today.addDays(-(widget.days - 1));
    final labels = WeekdayLabels.shortFrom(
      Localizations.localeOf(context).languageCode,
      weekStart,
    );

    final dates = [
      for (var i = 0; i < widget.days; i++) start.addDays(i),
    ];
    final states = [for (final date in dates) _stateOf(date, today)];
    _replay(states.map((s) => s.index).join());

    final tint = widget.habit.color;
    final ink = tint.computeLuminance() > 0.55 ? Colors.black : Colors.white;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _morph,
        builder: (context, child) => CustomPaint(
          painter: _StreakPainter(
            states: states,
            ink: expressInk(context, tint),
            progress: Express.bouncy.transform(_morph.value),
          ),
          child: child,
        ),
        child: Row(
          children: [
            for (var i = 0; i < widget.days; i++)
              Expanded(
                child: _DayCell(
                  habit: widget.habit,
                  date: dates[i],
                  state: states[i],
                  label: widget.showLabels
                      ? labels[(dates[i].weekday - weekStart + 7) % 7]
                            .replaceAll('.', '')
                            .toUpperCase()
                      : null,
                  isToday: dates[i] == today,
                  ink: ink,
                  onToggle: widget.onToggle,
                  onLongPress: widget.onLongPress,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.habit,
    required this.date,
    required this.state,
    required this.label,
    required this.isToday,
    required this.ink,
    required this.onToggle,
    required this.onLongPress,
  });

  final Habit habit;
  final DateTime date;
  final ExpressDayState state;
  final String? label;
  final bool isToday;
  final Color ink;
  final void Function(DateTime date)? onToggle;
  final void Function(DateTime date)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final done = state == ExpressDayState.done;
    final future = state == ExpressDayState.future;
    final text = done
        ? ink
        : future
        ? context.tokens.muted.withValues(alpha: 0.45)
        : context.tokens.muted;

    return Semantics(
      button: !future,
      label: heatmapDayLabel(context, habit, date),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: future || onToggle == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onToggle!(date);
              },
        onLongPress: onLongPress == null ? null : () => onLongPress!(date),
        child: ExcludeSemantics(
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: ExpressType.rounded.at(
                    14,
                    weight: done ? 850 : 700,
                    color: text,
                    tabular: true,
                  ),
                ),
                if (label != null)
                  Text(
                    label!,
                    maxLines: 1,
                    style: ExpressType.body.at(
                      9.5,
                      weight: isToday ? 850 : 600,
                      spacing: 0.4,
                      color: isToday && !done
                          ? context.colors.primary
                          : text.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakPainter extends CustomPainter {
  const _StreakPainter({
    required this.states,
    required this.ink,
    required this.progress,
  });

  final List<ExpressDayState> states;
  final ExpressStreakInk ink;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    paintStreakRow(canvas, Offset.zero & size, states, ink, progress);
  }

  @override
  bool shouldRepaint(_StreakPainter old) =>
      old.progress != progress ||
      old.ink.color != ink.color ||
      old.ink.track != ink.track ||
      !sameStates(old.states, states);
}
