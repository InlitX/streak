import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/celebration_overlay.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/day_timeline_parts.dart';
import 'package:streak/features/habits/widgets/focus_only_dialog.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

const _entrance = Duration(milliseconds: 320);

class DayTimelinePage extends StatefulWidget {
  const DayTimelinePage({super.key});

  @override
  State<DayTimelinePage> createState() => _DayTimelinePageState();
}

class _DayTimelinePageState extends State<DayTimelinePage> {
  late DateTime _day = AppClock.now().atMidnight;
  final _celebration = ValueNotifier(0);

  @override
  void dispose() {
    _celebration.dispose();
    super.dispose();
  }

  bool get _isToday => _day.isSameDay(AppClock.now());

  void _select(DateTime day) => setState(() => _day = day.atMidnight);

  void _shiftWeek(int weeks) => setState(
        () => _day = DateTime(_day.year, _day.month, _day.day + weeks * 7),
      );

  Future<void> _check(Habit habit) async {
    final controller = context.read<HabitsController>();
    if (!await allowManualCheck(context, habit: habit, date: _day)) return;
    if (!mounted) return;
    if (!await confirmUnscheduledDay(context, habit: habit, date: _day)) return;

    final wasDone = habit.isCompletedOn(_day);
    HapticFeedback.mediumImpact();
    if (habit.kind == HabitKind.quantitative) {
      await controller.addProgress(habit.id, _day, habit.incrementAmount);
    } else {
      await controller.toggle(habit.id, _day);
    }
    if (!mounted) return;

    final updated = controller.byId(habit.id);
    if (_isToday && !wasDone && (updated?.isCompletedOn(_day) ?? false)) {
      _celebration.value++;
    }
  }

  Color _neighbourColor(DayPlan plan, int from, int step) {
    for (var i = from; i >= 0 && i < plan.slots.length; i += step) {
      final habit = plan.slots[i].habit;
      if (habit != null) return habit.color;
    }
    return context.colors.primary;
  }

  List<Widget> _rows(BuildContext context, DayPlan plan) {
    final rows = <Widget>[];
    var index = 0;
    for (var i = 0; i < plan.slots.length; i++) {
      final slot = plan.slots[i];
      final habit = slot.habit;
      rows.add(
        Entrance(
          index: index,
          delay: _entrance,
          child: habit == null
              ? TimelineGap(
                  minutes: slot.minutes,
                  from: _neighbourColor(plan, i - 1, -1),
                  to: _neighbourColor(plan, i + 1, 1),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: TimelineBlock(
                    habit: habit,
                    date: _day,
                    done: habit.isCompletedOn(_day),
                    onOpen: () => AppNavigator.push(
                      HabitDetailsPage(habitId: habit.id),
                      fade: true,
                    ),
                    onCheck: () => _check(habit),
                  ),
                ),
        ),
      );
      index++;
    }

    if (plan.anytime.isNotEmpty) {
      rows.add(const SizedBox(height: 22));
      rows.add(SectionLabel(context.l10n.day_timeline_anytime));
      for (final habit in plan.anytime) {
        rows.add(
          Entrance(
            index: index,
            delay: _entrance,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AnytimeRow(
                habit: habit,
                date: _day,
                done: habit.isCompletedOn(_day),
                onOpen: () => AppNavigator.push(
                  HabitDetailsPage(habitId: habit.id),
                  fade: true,
                ),
                onCheck: () => _check(habit),
              ),
            ),
          ),
        );
        index++;
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitsController>().habits;
    final weekStart = context.watch<SettingsController>().weekStart;
    final plan = DayPlan.of(habits, _day);
    final locale = Localizations.localeOf(context).toString();
    final first = _day.startOfWeek(weekStart);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: Text(DateFormat.yMMMM(locale).format(_day)),
        actions: [
          if (!_isToday)
            IconButton(
              tooltip: context.l10n.today,
              icon: const Icon(LucideIcons.calendarCheck),
              onPressed: () => _select(AppClock.now()),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _WeekStrip(
                first: first,
                selected: _day,
                habits: habits,
                onSelected: _select,
                onShift: _shiftWeek,
              ),
              Expanded(
                child: plan.isEmpty
                    ? AppEmptyState(
                        icon: LucideIcons.calendarClock,
                        title: context.l10n.day_timeline_empty,
                        message: context.l10n.day_timeline_empty_sub,
                      )
                    : ListView(
                        padding: context.pagePadding(16, 8, 16, 28),
                        children: _rows(context, plan),
                      ),
              ),
            ],
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: ValueListenableBuilder<int>(
                valueListenable: _celebration,
                builder: (context, trigger, _) =>
                    CelebrationOverlay(trigger: trigger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.first,
    required this.selected,
    required this.habits,
    required this.onSelected,
    required this.onShift,
  });

  final DateTime first;
  final DateTime selected;
  final List<Habit> habits;
  final ValueChanged<DateTime> onSelected;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final labels = WeekdayLabels.shortFrom(
      Localizations.localeOf(context).languageCode,
      first.weekday,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft, size: 18),
                tooltip: context.l10n.a11y_previous_week,
                visualDensity: VisualDensity.compact,
                onPressed: () => onShift(-1),
              ),
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _DayChip(
                    day: DateTime(first.year, first.month, first.day + i),
                    label: labels[i],
                    selected: DateTime(
                      first.year,
                      first.month,
                      first.day + i,
                    ).isSameDay(selected),
                    habits: habits,
                    onTap: onSelected,
                  ),
                ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight, size: 18),
                tooltip: context.l10n.a11y_next_week,
                visualDensity: VisualDensity.compact,
                onPressed: () => onShift(1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.label,
    required this.selected,
    required this.habits,
    required this.onTap,
  });

  final DateTime day;
  final String label;
  final bool selected;
  final List<Habit> habits;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final today = day.isSameDay(AppClock.now());
    final dots = [
      for (final habit in habits)
        if (DayPlan.isDueOn(habit, day) && habit.isPlanned) habit.color,
    ].take(4).toList();

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => onTap(day),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? accent
                  : context.colors.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.replaceAll('.', ''),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: selected ? accent : context.tokens.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.day}',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: selected
                        ? accent
                        : today
                            ? context.colors.onSurface
                            : context.tokens.muted,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final color in dots)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
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

class _AnytimeRow extends StatelessWidget {
  const _AnytimeRow({
    required this.habit,
    required this.date,
    required this.done,
    required this.onOpen,
    required this.onCheck,
  });

  final Habit habit;
  final DateTime date;
  final bool done;
  final VoidCallback onOpen;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(
              alpha: done ? 0.35 : 0.6,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: habit.color.withValues(alpha: done ? 0.5 : 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HabitGlyph(
                  glyph: habit.icon,
                  color: done ? scheme.surface : habit.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: done ? context.tokens.muted : scheme.onSurface,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: context.tokens.muted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TimelineCheck(
                habit: habit,
                date: date,
                done: done,
                onTap: onCheck,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
