import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/habit_card.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';

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
    required this.onLongPress,
  });

  final List<Habit> habits;
  final HeatmapMode mode;
  final bool reordering;
  final Widget header;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<Habit> onOpen;
  final ValueChanged<Habit> onToggleToday;
  final ValueChanged<Habit> onLongPress;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
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
        return _EntranceCard(
          key: ValueKey(habit.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitCard(
              habit: habit,
              mode: mode,
              onOpen: () => onOpen(habit),
              onToggleToday: () => onToggleToday(habit),
              onLongPress: () => onLongPress(habit),
            ),
          ),
        );
      },
    );
  }
}

class _EntranceCard extends StatefulWidget {
  const _EntranceCard({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_EntranceCard> createState() => _EntranceCardState();
}

class _EntranceCardState extends State<_EntranceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 35 * widget.index.clamp(0, 6)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
