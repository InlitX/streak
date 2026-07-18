import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/app_strings.dart';
import 'package:streak/features/habits/data/habit.dart';

class StreakSummary extends StatelessWidget {
  const StreakSummary({super.key, required this.habit});

  final Habit habit;

  String _format(int value) {
    final unit = habit.interval.unit + (value == 1 ? '' : 's');
    return '$value $unit';
  }

  @override
  Widget build(BuildContext context) {
    final negative = habit.kind == HabitKind.negative;
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: LucideIcons.flame,
            iconColor: habit.color,
            label: context.tr('current'),
            value: _format(habit.currentStreak),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            icon: LucideIcons.trophy,
            iconColor: context.tokens.warning,
            label: context.tr('best'),
            value: _format(habit.longestStreak),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            icon: negative ? LucideIcons.triangleAlert : LucideIcons.circleCheck,
            iconColor: negative ? context.tokens.danger : context.tokens.success,
            label: context.tr(negative ? 'relapses' : 'total'),
            value: '${habit.totalCompletions}',
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.tokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}
