import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/express_habit_card.dart';
import 'package:streak/features/habits/widgets/habit_entrance.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/slot_transition.dart';

class ExpressHabitList extends StatelessWidget {
  const ExpressHabitList({
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
  final Widget header;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<Habit> onOpen;
  final ValueChanged<Habit> onToggleToday;
  final void Function(Habit habit, DateTime date) onToggleDay;
  final ValueChanged<Habit> onLongPress;
  final Set<String> leaving;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: context.pagePadding(16, 4, 16, 128),
      itemCount: habits.length,
      buildDefaultDragHandles: false,
      header: header,
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        onReorder(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Transform.scale(
          scale: 1 + Curves.easeOut.transform(animation.value) * 0.04,
          child: Material(color: Colors.transparent, child: child),
        ),
      ),
      itemBuilder: (context, index) {
        final habit = habits[index];
        final radius = expressSlotRadius(index, habits.length);

        if (reordering) {
          return ReorderableDelayedDragStartListener(
            key: ValueKey(habit.id),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Express.groupGap),
              child: Row(
                children: [
                  Expanded(
                    child: ExpressHabitCard(
                      habit: habit,
                      mode: mode,
                      radius: radius,
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

        return HabitEntrance(
          key: ValueKey('$mode-${habit.id}'),
          index: index,
          child: SlotTransition(
            leaving: leaving.contains(habit.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: Express.groupGap),
              child: ExpressHabitCard(
                habit: habit,
                mode: mode,
                radius: radius,
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
