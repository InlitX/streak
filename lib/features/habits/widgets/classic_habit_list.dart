import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/widgets/stacked_corners.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/habit_card.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/habit_entrance.dart';
import 'package:streak/features/habits/widgets/slot_transition.dart';

class ClassicHabitList extends StatelessWidget {
  const ClassicHabitList({
    super.key,
    required this.habits,
    required this.mode,
    required this.reordering,
    required this.header,
    required this.onReorder,
    required this.onOpen,
    required this.onToggleToday,
    required this.onToggleDay,
    required this.onLongPress,
    this.leaving = const {},
  });

  final List<Habit> habits;
  final HeatmapMode mode;
  final bool reordering;
  final Set<String> leaving;
  final Widget header;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<Habit> onOpen;
  final ValueChanged<Habit> onToggleToday;
  final void Function(Habit habit, DateTime date) onToggleDay;
  final ValueChanged<Habit> onLongPress;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: context.pagePadding(16, 8, 16, 104),
      itemCount: habits.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        onReorder(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        child: child,
      ),
      header: header,
      itemBuilder: (context, index) {
        final habit = habits[index];
        if (reordering) {
          return ReorderableDelayedDragStartListener(
            key: ValueKey(habit.id),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: HabitCard(
                      habit: habit,
                      mode: mode,
                      onOpen: () {},
                      onToggleToday: () {},
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      LucideIcons.gripVertical,
                      color: context.tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final compact = context.watch<SettingsController>().compactCards;
        return HabitEntrance(
          key: ValueKey(habit.id),
          index: index,
          child: SlotTransition(
            leaving: leaving.contains(habit.id),
            child: Padding(
              padding: EdgeInsets.only(bottom: compact ? 3 : 12),
              child: HabitCard(
                habit: habit,
                mode: mode,
                corners: compact
                    ? stackedCorners(index, habits.length)
                    : null,
                onOpen: () => onOpen(habit),
                onToggleToday: () => onToggleToday(habit),
                onToggleDay: (date) => onToggleDay(habit, date),
                onLongPress: () => onLongPress(habit),
              ),
            ),
          ),
        );
      },
    );
  }
}
