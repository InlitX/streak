import 'package:flutter/material.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/widgets/keep_built.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/widgets/pane_mark.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/grid_habit_cards.dart';
import 'package:streak/features/habits/widgets/habit_entrance.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/slot_transition.dart';
import 'package:streak/features/habits/widgets/swipe_check.dart';
import 'package:streak/core/extensions/color_extensions.dart';

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
    this.onSwipe,
    this.leaving = const {},
    this.fold,
    this.more = const [],
  });

  static EdgeInsets _padding(BuildContext context) =>
      context.pagePadding(16, 8, 16, 104);

  final List<Habit> habits;
  final HeatmapMode mode;
  final Widget header;
  final Widget? fold;
  final List<Habit> more;
  final ValueChanged<Habit> onOpen;
  final ValueChanged<Habit> onToggleToday;
  final void Function(Habit habit, DateTime date) onToggleDay;
  final ValueChanged<Habit> onLongPress;
  final ValueChanged<Habit>? onSwipe;
  final Set<String> leaving;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 440),
      reverseDuration: const Duration(milliseconds: 220),
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.easeOut,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => child.key == ValueKey(mode)
          ? _SwitchIn(animation: animation, child: child)
          : FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey(mode),
        child: mode == HeatmapMode.month ? _monthGrid(context) : _list(context),
      ),
    );
  }

  Widget _list(BuildContext context) {
    return ListView.builder(
      padding: _padding(context),
      itemCount: habits.length + 1 + (fold == null ? 0 : 1 + more.length),
      itemBuilder: (context, index) {
        if (index == 0) return _Cascade(index: 0, child: header);
        final i = index - 1;
        if (i == habits.length) return _Cascade(index: index, child: fold!);
        final habit = i > habits.length ? more[i - habits.length - 1] : habits[i];
        return _Cascade(
          index: index,
          child: HabitEntrance(
          key: ValueKey(habit.id),
          index: i,
          child: Opacity(
            opacity: i > habits.length ? 0.6 : 1,
            child: SlotTransition(
            leaving: leaving.contains(habit.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PaneMark(
                id: habit.id,
                tint: habit.color.shownIn(context),
                corners: BorderRadius.circular(20),
                child: SwipeCheck(
                  done: habit.isCompletedOn(AppClock.today()),
                  tint: habit.color.shownIn(context),
                  corners: BorderRadius.circular(20),
                  onSwipe: onSwipe == null ? null : () => onSwipe!(habit),
                  child: KeepBuilt(
                  keys: [habit, mode, AppClock.today()],
                  build: () => mode == HeatmapMode.week
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
              ),
            ),
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
      itemCount: _rows(habits) + 1 + (fold == null ? 0 : 1 + _rows(more)),
      itemBuilder: (context, index) {
        if (index == 0) return _Cascade(index: 0, child: header);
        final split = _rows(habits) + 1;
        if (index == split) return _Cascade(index: index, child: fold!);
        final extra = index > split;
        final group = extra ? more : habits;
        final i = (index - (extra ? split + 1 : 1)) * 2;
        return _Cascade(
          index: index,
          child: HabitEntrance(
          key: ValueKey(group[i].id),
          index: index - 1,
          child: Opacity(
            opacity: extra ? 0.6 : 1,
            child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _monthCard(context, group[i])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < group.length
                        ? _monthCard(context, group[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          ),
          ),
        );
      },
    );
  }

  static int _rows(List<Habit> habits) => (habits.length + 1) ~/ 2;

  Widget _monthCard(BuildContext context, Habit habit) {
    return PaneMark(
      id: habit.id,
      tint: habit.color.shownIn(context),
      corners: BorderRadius.circular(30),
      child: SwipeCheck(
        done: habit.isCompletedOn(AppClock.today()),
        tint: habit.color.shownIn(context),
        corners: BorderRadius.circular(30),
        onSwipe: onSwipe == null ? null : () => onSwipe!(habit),
        child: KeepBuilt(
        keys: [habit, AppClock.today()],
        build: () => GridMonthCard(
          habit: habit,
          onOpen: () => onOpen(habit),
          onToggleToday: () => onToggleToday(habit),
          onToggleDay: (d) => onToggleDay(habit, d),
          onLongPress: () => onLongPress(habit),
        ),
        ),
      ),
    );
  }
}

class _SwitchIn extends InheritedWidget {
  const _SwitchIn({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_SwitchIn old) => old.animation != animation;
}

class _Cascade extends StatelessWidget {
  const _Cascade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent =
        context.dependOnInheritedWidgetOfExactType<_SwitchIn>()?.animation;
    if (parent == null) return child;
    final start = 0.05 * index.clamp(0, 6);
    final curve = CurvedAnimation(
      parent: parent,
      curve: Interval(start, start + 0.6, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(curve),
        child: RepaintBoundary(child: child),
      ),
    );
  }
}
