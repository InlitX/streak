import 'package:provider/provider.dart';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/core/widgets/glass.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

typedef DayTally = ({int done, int due});

class TimelineWeekStrip extends StatefulWidget {
  const TimelineWeekStrip({
    super.key,
    required this.first,
    required this.selected,
    required this.habits,
    required this.style,
    required this.direction,
    required this.page,
    required this.month,
    required this.onSelected,
    required this.onShift,
    required this.onFold,
  });

  final DateTime first;
  final DateTime selected;
  final List<Habit> habits;
  final int style;
  final int direction;
  final int page;
  final bool month;
  final ValueChanged<DateTime> onSelected;
  final ValueChanged<int> onShift;
  final VoidCallback onFold;

  static final _weeks = Expando<Map<int, List<int>>>();

  static List<int> _marks(Habit habit, DateTime first, List<DateTime> days) {
    final cache = _weeks[habit] ??= {};
    return cache[first.epochDay] ??= [
      for (final day in days)
        habit.tracking || !DayPlan.isDueOn(habit, day)
            ? 0
            : habit.isCompletedOn(day)
                ? 2
                : 1,
    ];
  }

  static List<DayTally> tallies(List<Habit> habits, DateTime first) {
    final days = [for (var i = 0; i < 7; i++) first.addDays(i)];
    final done = List.filled(7, 0);
    final due = List.filled(7, 0);
    for (final habit in habits) {
      final marks = _marks(habit, first, days);
      for (var i = 0; i < 7; i++) {
        if (marks[i] > 0) due[i]++;
        if (marks[i] == 2) done[i]++;
      }
    }
    return [for (var i = 0; i < 7; i++) (done: done[i], due: due[i])];
  }

  @override
  State<TimelineWeekStrip> createState() => _TimelineWeekStripState();
}

class _TimelineWeekStripState extends State<TimelineWeekStrip>
    with SingleTickerProviderStateMixin {
  late final _fold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: widget.month ? 1 : 0,
  );
  late final _curve = CurvedAnimation(
    parent: _fold,
    curve: Express.emphasized,
    reverseCurve: Express.emphasized.flipped,
  );

  @override
  void didUpdateWidget(TimelineWeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.month != oldWidget.month) {
      widget.month ? _fold.forward() : _fold.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _fold.dispose();
    super.dispose();
  }

  List<DateTime> _weeksOfMonth() {
    final selected = widget.selected;
    final start = DateTime(selected.year, selected.month)
        .startOfWeek(widget.first.weekday);
    return [for (var w = 0; w < 6; w++) start.addDays(w * 7)];
  }

  String _range(String locale) {
    if (widget.month) return DateFormat.MMMMEEEEd(locale).format(widget.selected);
    final format = DateFormat.MMMd(locale);
    final first = widget.first;
    return '${format.format(first)} - ${format.format(first.addDays(6))}';
  }

  @override
  Widget build(BuildContext context) {
    final express = widget.style == 2;
    final month = widget.month;
    final locale = Localizations.localeOf(context).toString();
    final labels = [
      for (final label in WeekdayLabels.shortFrom(
        Localizations.localeOf(context).languageCode,
        widget.first.weekday,
      ))
        label.replaceAll('.', ''),
    ];
    final weeks = month || _fold.value > 0
        ? _weeksOfMonth()
        : [widget.first];
    final current = weeks.indexWhere(
      (week) => week.isSameDay(widget.first),
    );
    final tallies = [
      for (final week in weeks) TimelineWeekStrip.tallies(widget.habits, week),
    ];
    var done = 0;
    var due = 0;
    for (final (w, week) in weeks.indexed) {
      if (!month && w != current) continue;
      for (final (i, tally) in tallies[w].indexed) {
        if (month && week.addDays(i).month != widget.selected.month) continue;
        done += tally.done;
        due += tally.due;
      }
    }
    final muted = context.tokens.muted;
    final spoken = DateFormat.MMMMEEEEd(locale);

    Widget row(int w, double fold) => Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _DayCard(
                    day: weeks[w].addDays(i),
                    label: labels[i],
                    spoken: spoken,
                    selected: weeks[w].addDays(i).isSameDay(widget.selected),
                    outside: weeks[w].addDays(i).month != widget.selected.month,
                    tally: tallies[w][i],
                    style: widget.style,
                    fold: fold,
                    onTap: widget.onSelected,
                  ),
                ),
              ),
          ],
        );

    Widget reveal(double fold, Widget child) {
      if (fold >= 1) return child;
      return ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: fold,
          child: Opacity(opacity: fold, child: child),
        ),
      );
    }

    Widget grid(double fold) => Column(
          key: ValueKey(widget.page),
          children: [
            for (var w = 0; w < weeks.length; w++)
              if (w == current || fold > 0)
                Padding(
                  padding: EdgeInsets.only(top: w == 0 ? 0 : 6 * fold),
                  child: w == current ? row(w, fold) : reveal(fold, row(w, fold)),
                ),
          ],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 0, 13, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 0, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _range(locale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: muted,
                    ),
                  ),
                ),
                if (due > 0) ...[
                  Icon(LucideIcons.circleCheck, size: 14, color: muted),
                  const SizedBox(width: 5),
                  Text(
                    '$done/$due',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: muted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                AnimatedRotation(
                  turns: month ? 0.5 : 0,
                  duration: _fold.duration!,
                  curve: Express.emphasized,
                  child: _Arrow(
                    icon: LucideIcons.chevronDown,
                    tooltip: month
                        ? context.l10n.plan_show_week
                        : context.l10n.plan_show_month,
                    express: express,
                    onPressed: widget.onFold,
                  ),
                ),
                const SizedBox(width: 6),
                _Arrow(
                  icon: LucideIcons.chevronLeft,
                  tooltip: month
                      ? context.l10n.a11y_previous_month
                      : context.l10n.a11y_previous_week,
                  express: express,
                  onPressed: () => widget.onShift(-1),
                ),
                const SizedBox(width: 6),
                _Arrow(
                  icon: LucideIcons.chevronRight,
                  tooltip: month
                      ? context.l10n.a11y_next_month
                      : context.l10n.a11y_next_week,
                  express: express,
                  onPressed: () => widget.onShift(1),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _curve,
            builder: (context, _) {
              final fold = _curve.value.clamp(0.0, 1.0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (fold > 0)
                    reveal(
                      fold,
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            for (final label in labels)
                              Expanded(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: express
                        ? (details) => widget.onShift(
                              (details.primaryVelocity ?? 0) < 0 ? 1 : -1,
                            )
                        : null,
                    child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [...previous, if (current != null) current],
                          ),
                          transitionBuilder: (child, animation) {
                            final shift = child.key == ValueKey(widget.page)
                                ? widget.direction
                                : -widget.direction;
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween(
                                  begin: Offset(0.25 * shift, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: grid(fold),
                        ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.tooltip,
    required this.express,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool express;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    final fill = context.colors.surfaceContainerHighest.withValues(alpha: 0.55);
    if (!express && !context.watch<SettingsController>().isMinimalStyle) {
      return GlassIconButton(
        icon: icon,
        size: 34,
        tooltip: tooltip,
        onTap: onPressed,
      );
    }
    if (express) {
      return ExpressIconButton(
        icon: icon,
        size: 34,
        tint: muted,
        background: fill,
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }
    return SizedBox.square(
      dimension: 34,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(backgroundColor: fill),
        icon: Icon(icon, size: 18, color: muted),
        onPressed: onPressed,
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.label,
    required this.spoken,
    required this.selected,
    required this.outside,
    required this.tally,
    required this.style,
    required this.fold,
    required this.onTap,
  });

  final DateTime day;
  final String label;
  final DateFormat spoken;
  final bool selected;
  final bool outside;
  final DayTally tally;
  final int style;
  final double fold;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final express = style == 2;
    final minimal = style == 1;
    final scheme = context.colors;
    final muted = context.tokens.muted;
    final today = day.isSameDay(AppClock.today());
    final strong = minimal ? scheme.onSurface : scheme.primary;
    final dim = outside && !selected ? 1 - 0.6 * fold : 1.0;
    Color fade(Color color) => color.withValues(alpha: color.a * dim);
    final ink = selected
        ? (minimal ? scheme.surface : scheme.onPrimary)
        : fade(today ? strong : scheme.onSurface);
    final soft = selected ? ink.withValues(alpha: 0.75) : fade(muted);
    final faint = soft.withValues(alpha: soft.a * (1 - fold));
    final radius = express ? (selected ? 24.0 : 16.0) : 16.0;

    return Semantics(
      button: true,
      selected: selected,
      label: spoken.format(day),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => onTap(day),
        child: SizedBox(
            height: lerpDouble(66, 46, fold),
            child: AnimatedContainer(
              duration:
                  express ? Express.morph : const Duration(milliseconds: 220),
              curve: express ? Express.bouncy : Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected
                    ? strong
                    : fade(scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: today && !selected
                      ? strong.withValues(alpha: 0.7)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.15,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (fold < 1)
                      ClipRect(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          heightFactor: 1 - fold,
                          child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                softWrap: false,
                                style: express
                                    ? ExpressType.body.at(
                                        11,
                                        weight: 800,
                                        height: 1.1,
                                        color: faint,
                                      )
                                    : minimal
                                        ? MinimalType.label(size: 11, color: faint)
                                        : TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            height: 1.1,
                                            color: faint,
                                          ),
                              ),
                          ),
                        ),
                      ),
                    Transform.scale(
                      scale: lerpDouble(1, 16 / 19, fold)!,
                      child: Text(
                      '${day.day}',
                      maxLines: 1,
                      style: express
                          ? ExpressType.display.at(
                              19,
                              height: 1.05,
                              color: ink,
                              tabular: true,
                            )
                          : minimal
                              ? MinimalType.figure(19, height: 1.05, color: ink)
                              : TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                  color: ink,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                    ),
                    ),
                    SizedBox(height: lerpDouble(3, 2, fold)),
                    _DayMeter(
                      tally: tally,
                      color: selected ? ink : fade(strong),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }
}

class _DayMeter extends StatelessWidget {
  const _DayMeter({required this.tally, required this.color});

  final DayTally tally;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (tally.due == 0) return const SizedBox(height: 14);
    if (tally.done == tally.due) {
      return Icon(LucideIcons.circleCheck, size: 14, color: color);
    }
    final radius = BorderRadius.circular(2);
    return Container(
      width: 24,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color.a * 0.2),
        borderRadius: radius,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: tally.done / tally.due),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, fraction, _) => FractionallySizedBox(
          widthFactor: fraction,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}
