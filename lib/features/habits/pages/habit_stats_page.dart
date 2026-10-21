import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/express/express_page.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/avoid_stats.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

bool hasHabitStats(Habit habit) =>
    habit.hasTotalGoal || habit.kind == HabitKind.negative;

class HabitStatsPage extends StatelessWidget {
  const HabitStatsPage({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitsController>().byId(habitId);
    if (habit == null) return const SizedBox.shrink();
    final settings = context.watch<SettingsController>();

    final children = <Widget>[
      if (habit.hasCleanGoal) CleanGoalCard(habit: habit),
      if (habit.hasTotalGoal) TotalGoalCard(habit: habit),
      if (habit.kind == HabitKind.negative) AvoidMonthSection(habit: habit),
    ];
    final spaced = [
      for (final (i, child) in children.indexed) ...[
        if (i > 0) const SizedBox(height: 20),
        child,
      ],
    ];

    if (settings.isExpressStyle) {
      return ExpressScaffold(title: habit.name, children: spaced);
    }
    final minimal = settings.isMinimalStyle;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: minimal ? 52 : null,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: minimal ? null : Text(habit.name),
      ),
      body: ListView(
        padding: context.pagePadding(minimal ? 20 : 16, 8, minimal ? 20 : 16, 32),
        children: [
          if (minimal) MinimalTitle(title: habit.name),
          ...spaced,
        ],
      ),
    );
  }
}
