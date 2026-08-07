import 'package:flutter/material.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/grid_habit_cards.dart';
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

  static const _padding = EdgeInsets.fromLTRB(16, 8, 16, 104);

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
    if (mode == HeatmapMode.month) return _monthGrid();
    return ListView(
      padding: _padding,
      children: [
        header,
        for (var i = 0; i < habits.length; i++)
          Entrance(
            key: ValueKey('$mode-${habits[i].id}'),
            index: i,
            child: SlotTransition(
              leaving: leaving.contains(habits[i].id),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: mode == HeatmapMode.week
                    ? GridWeekCard(
                        habit: habits[i],
                        onOpen: () => onOpen(habits[i]),
                        onToggleDay: (d) => onToggleDay(habits[i], d),
                        onLongPress: () => onLongPress(habits[i]),
                      )
                    : GridYearCard(
                        habit: habits[i],
                        onOpen: () => onOpen(habits[i]),
                        onToggleToday: () => onToggleToday(habits[i]),
                        onToggleDay: (d) => onToggleDay(habits[i], d),
                        onLongPress: () => onLongPress(habits[i]),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _monthGrid() {
    return ListView(
      padding: _padding,
      children: [
        header,
        for (var i = 0; i < habits.length; i += 2)
          Entrance(
            key: ValueKey('month-$i-${habits[i].id}'),
            index: i ~/ 2,
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
          ),
      ],
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
