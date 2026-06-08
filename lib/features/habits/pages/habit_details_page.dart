import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/app_strings.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/activity_calendar.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/share_card.dart';
import 'package:streak/features/habits/widgets/streak_summary.dart';

class HabitDetailsPage extends StatefulWidget {
  const HabitDetailsPage({super.key, required this.habitId});

  final String habitId;

  @override
  State<HabitDetailsPage> createState() => _HabitDetailsPageState();
}

class _HabitDetailsPageState extends State<HabitDetailsPage> {
  HeatmapMode _mode = HeatmapMode.week;

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitsController>(
      builder: (context, controller, _) {
        final habit = controller.byId(widget.habitId);
        if (habit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.pop();
          });
          return const SizedBox.shrink();
        }

        void toggle(DateTime date) {
          HapticFeedback.selectionClick();
          controller.toggle(habit.id, date);
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                HabitGlyph(glyph: habit.icon, color: habit.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(habit.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: () => AppNavigator.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share2),
                tooltip: context.tr('share_progress'),
                onPressed: () => showShareCard(context, habit),
              ),
              IconButton(
                icon: const Icon(LucideIcons.pencil),
                onPressed: () => AppNavigator.push(
                  HabitFormPage(habit: habit),
                  fullscreenDialog: true,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _DetailBackground(
            coverPath: habit.coverPath,
            child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (habit.description.isNotEmpty) ...[
                  Text(
                    habit.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.tokens.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                SectionLabel(context.tr('streaks')),
                StreakSummary(habit: habit),
                const SizedBox(height: 20),
                SectionLabel(
                  context.tr('activity'),
                  trailing: _ModeToggle(
                    mode: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                ),
                _ActivityView(habit: habit, mode: _mode, onToggle: toggle),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}

/// Muestra la foto del hábito como fondo con overlay oscuro si existe.
class _DetailBackground extends StatelessWidget {
  const _DetailBackground({required this.coverPath, required this.child});

  final String coverPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasCover = coverPath.isNotEmpty && File(coverPath).existsSync();
    if (!hasCover) return child;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.file(File(coverPath), fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.78)),
        ),
        child,
      ],
    );
  }
}

class _ActivityView extends StatelessWidget {
  const _ActivityView({
    required this.habit,
    required this.mode,
    required this.onToggle,
  });

  final Habit habit;
  final HeatmapMode mode;
  final void Function(DateTime date) onToggle;

  @override
  Widget build(BuildContext context) {
    if (mode == HeatmapMode.month) {
      return ActivityCalendar(habit: habit, onToggle: onToggle);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: HabitHeatmap(
          habit: habit,
          mode: mode,
          onToggle: mode == HeatmapMode.week ? onToggle : null,
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final HeatmapMode mode;
  final ValueChanged<HeatmapMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final options = [
      (HeatmapMode.week, context.tr('week')),
      (HeatmapMode.month, context.tr('month')),
      (HeatmapMode.year, context.tr('year')),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label) in options)
            GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: value == mode ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        value == mode ? scheme.onPrimary : context.tokens.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
