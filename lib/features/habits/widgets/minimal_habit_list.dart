import 'package:flutter/material.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/grid_habit_cards.dart';
import 'package:streak/features/habits/widgets/habit_entrance.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/slot_transition.dart';

class MinimalHabitList extends StatelessWidget {
  const MinimalHabitList({
    super.key,
    required this.habits,
    required this.mode,
    required this.header,
    required this.onOpen,
    required this.onToggleToday,
    required this.onToggleDay,
    required this.onLongPress,
    this.leaving = const {},
  });

  static EdgeInsets _padding(BuildContext context) =>
      context.pagePadding(16, 8, 16, 104);

  final List<Habit> habits;
  final HeatmapMode mode;
  final Widget header;
  final ValueChanged<Habit> onOpen;
  final ValueChanged<Habit> onToggleToday;
  final void Function(Habit habit, DateTime date) onToggleDay;
  final ValueChanged<Habit> onLongPress;
  final Set<String> leaving;

  @override
  Widget build(BuildContext context) {
    if (mode == HeatmapMode.month) return _monthGrid(context);
    return ListView.builder(
      padding: _padding(context),
      itemCount: habits.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return header;
        final i = index - 1;
        final habit = habits[i];
        return HabitEntrance(
          key: ValueKey('$mode-${habit.id}'),
          index: i,
          child: SlotTransition(
            leaving: leaving.contains(habit.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: mode == HeatmapMode.week
                  ? GridWeekCard(
                      habit: habit,
                      onOpen: () => onOpen(habit),
                      onToggleDay: (d) => onToggleDay(habit, d),
                      onLongPress: () => onLongPress(habit),
                    )
                  : GridYearCard(
                      habit: habit,
                      onOpen: () => onOpen(habit),
                      onToggleToday: () => onToggleToday(habit),
                      onToggleDay: (d) => onToggleDay(habit, d),
                      onLongPress: () => onLongPress(habit),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _monthGrid(BuildContext context) {
    return ListView.builder(
      padding: _padding(context),
      itemCount: (habits.length + 1) ~/ 2 + 1,
      itemBuilder: (context, index) {
        if (index == 0) return header;
        final i = (index - 1) * 2;
        return HabitEntrance(
          key: ValueKey('month-${habits[i].id}'),
          index: index - 1,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _monthCard(habits[i])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < habits.length
                        ? _monthCard(habits[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _monthCard(Habit habit) {
    return GridMonthCard(
      habit: habit,
      onOpen: () => onOpen(habit),
      onToggleToday: () => onToggleToday(habit),
      onToggleDay: (d) => onToggleDay(habit, d),
      onLongPress: () => onLongPress(habit),
    );
  }
}
